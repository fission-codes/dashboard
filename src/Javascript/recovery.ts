import * as webnative from "webnative"
import * as did from "webnative/did/index"
import * as dataRoot from "webnative/data-root"
import * as webnativeIpfs from "webnative/ipfs/index"
import * as crypto from "webnative/crypto/index"
import * as ucan from "webnative/ucan/index"
import { WebSocketChannel, EncryptedChannel, TextEncodedChannel, JSONChannel, Channel } from "webnative/realtime/channel"
import * as namefilter from "webnative/fs/protocol/private/namefilter"
import * as uint8arrays from "uint8arrays"
import MMPT from "webnative/fs/protocol/private/mmpt"
import throttle from "lodash/throttle"

//----------------------------------------
// GLOBALS / CONFIG
//----------------------------------------

window.environment = CONFIG_ENVIRONMENT

console.log(`Running in ${window.environment} environment`)

window.endpoints = {
  api: CONFIG_API_ENDPOINT,
  lobby: CONFIG_LOBBY,
  user: CONFIG_USER,
}

window.webnative = webnative

webnative.setup.debug({ enabled: true })
webnative.setup.endpoints(window.endpoints)

const RECOVERY_USERNAME_KEY = "account-recovery-username"
const RECOVERY_BACKUP_KEY = "account-recovery-backup"

window.clearBackup = () => {
  localStorage.removeItem(RECOVERY_USERNAME_KEY)
  localStorage.removeItem(RECOVERY_BACKUP_KEY)
}


//----------------------------------------
// SETUP ELM APP
//----------------------------------------

const elmApp = Elm.Recovery.Main.init({
  flags: {
    endpoints: window.endpoints,
    savedRecovery: {
      username: localStorage.getItem(RECOVERY_USERNAME_KEY),
      key: localStorage.getItem(RECOVERY_BACKUP_KEY)
    }
  }
})

window["elmApp"] = elmApp

elmApp.ports.verifyBackup.subscribe(async (backup: { username: string, key: string }) => {
  try {
    const ipfsPromise = webnativeIpfs.get()
    const rootCID = await tryRethrowing(
      dataRoot.lookupOnFisson(backup.username),
      e => ({
        isUserError: true,
        message: `We couldn't find a user with name "${backup.username}".`,
        contactSupport: false,
        original: e,
      })
    )

    if (rootCID == null) {
      throw {
        isUserError: true,
        message: `We couldn't find a user with name "${backup.username}".`,
        contactSupport: true,
        original: null,
      }
    }

    const ipfs = await ipfsPromise
    const { cid: mmptCID } = await tryRethrowing(
      ipfs.dag.resolve(`/ipfs/${rootCID}/private`),
      e => ({
        isUserError: true,
        message: "Something went wrong: We couldn't find a private filesystem in your personal datastore.",
        contactSupport: true,
        original: e,
      })
    )

    const privateName = await getRootBlockPrivateName(backup.key)

    const mmpt = await tryRethrowing(
      MMPT.fromCID(mmptCID.toString()),
      e => ({
        isUserError: true,
        message: "Something went wrong: We couldn't load your private filesystem.",
        contactSupport: true,
        original: e,
      })
    )

    const privateRootExists = await mmpt.exists(privateName)

    if (!privateRootExists) {
      throw {
        isUserError: true,
        message: "This backup file is invalid.",
        contactSupport: true,
        original: null,
      }
    }
    elmApp.ports.verifyBackupSucceeded.send(backup)
  } catch (e) {
    if (e.isUserError) {
      elmApp.ports.verifyBackupFailed.send({ message: e.message, contactSupport: e.contactSupport })
    }
    if (e.original != null) {
      console.error(e.original)
    }
  }
})

async function tryRethrowing<T, E>(promise: Promise<T>, rethrow: ((error: unknown) => E) | E): Promise<T> {
  let result: T;
  try {
    result = await promise
  } catch (e) {
    if (rethrow instanceof Function) {
      throw rethrow(e)
    } else {
      throw rethrow
    }
  }
  return result
}

async function getRootBlockPrivateName(key: string): Promise<namefilter.PrivateName> {
  const bareName = await namefilter.createBare(key)
  const revisionName = await namefilter.addRevision(bareName, key, 1)
  return await namefilter.toPrivateName(revisionName)
}


elmApp.ports.usernameExists.subscribe(throttle(async (username: string) => {
  if (webnative.lobby.isUsernameValid(username)) {
    const exists = !await webnative.lobby.isUsernameAvailable(username)
    elmApp.ports.usernameExistsResponse.send({ username, valid: true, exists })
  } else {
    elmApp.ports.usernameExistsResponse.send({ username, valid: false, exists: true })
  }
}, 500, { leading: false, trailing: true }))


elmApp.ports.saveUsername.subscribe(async (username: string) => {
  localStorage.setItem(RECOVERY_USERNAME_KEY, username)
})
elmApp.ports.saveBackup.subscribe(async (backup: string) => {
  localStorage.setItem(RECOVERY_BACKUP_KEY, backup)
})


elmApp.ports.fetchWritePublicKey.subscribe(async () => {
  try {
    // Make sure to generate a new publicWriteKey
    await webnative.keystore.clear()
    const publicKeyBase64 = await crypto.keystore.publicWriteKey()
    elmApp.ports.writePublicKeyFetched.send(publicKeyBase64)
  } catch (e) {
    elmApp.ports.writePublicKeyFailure.send(e.message)
  }
})

const RSA_KEY_ALGO = {
  name: "RSA-OAEP",
  modulusLength: 2048,
  publicExponent: new Uint8Array([0x01, 0x00, 0x01]),
  hash: { name: "SHA-256" }
}

elmApp.ports.justLikeLinkTheAccountsAndStuff.subscribe(async ({ username, rootPublicKey, readKey }: { username: string, rootPublicKey: string, readKey: string | null }) => {
  const keystorePublicWriteKey = await crypto.keystore.publicWriteKey()
  if (keystorePublicWriteKey !== rootPublicKey) {
    console.error("The public key in the keystore is not the same as the public key used for account recovery", keystorePublicWriteKey, rootPublicKey)
  }

  const wssApi = window.endpoints.api.replace(/^https?:\/\//, "wss://")
  const rootDID = did.publicKeyToDid(rootPublicKey, did.KeyType.RSA)
  const endpoint = `${wssApi}/user/link/${rootDID}`
  const socketChannel = new WebSocketChannel(new WebSocket(endpoint))
  const textChannel = new TextEncodedChannel(socketChannel)

  const encryptedChannel = new JSONChannel(new TextEncodedChannel(await retry(async () => {
    const throwawayDID = await textChannel.receive()
    return await establishSecureChannelWith(throwawayDID, socketChannel)
  })))
  
  console.log("Successfully established a secure connection")

  const challengeData: { pin: number, did: string } = await retry(async () => await encryptedChannel.receive(), { interval: 200, maxRetries: 10 })

  console.log("Got challenge: ", challengeData.pin)
  console.log("And the did: ", challengeData.did)
  console.log("Can we reuse readKey?", readKey != null)

  // If we can't recover the user's files, we generate a new read key for them
  const actualReadKey = readKey != null ? readKey : await crypto.aes.genKeyStr()
  const linkingUCAN = ucan.encode(await ucan.build({
    audience: challengeData.did,
    issuer: rootDID,
    lifetimeInSeconds: 60 * 60 * 24 * 30 * 12 * 1000, // 1000 years
    potency: "SUPER_USER",
  }))

  if (!await ucan.isValid(ucan.decode(linkingUCAN))) {
    console.error("Ucan is invalid. Have to stop")
    return
  }

  console.log("Sending Ucan")

  encryptedChannel.send({
    readKey: actualReadKey,
    ucan: linkingUCAN,
  })
})

async function establishSecureChannelWith(recipientDID: string, baseChannel: Channel<ArrayBuffer>, crypto?: SubtleCrypto): Promise<EncryptedChannel> {
  crypto = crypto || (globalThis.crypto as any).webcrypto?.subtle || globalThis.crypto.subtle
  const { publicKey } = did.didToPublicKey(recipientDID) // Also ensures that it's a valid did
  const recipientPubKey = await crypto.importKey(
    "spki",
    base64ToArrayBuffer(publicKey),
    RSA_KEY_ALGO,
    false,
    [ "encrypt" ]
  )

  const sessionKey = await crypto.generateKey(
    {
      name: "AES-GCM",
      length: 256
    },
    true,
    [ "encrypt", "decrypt" ]
  )

  const sessionKeyRaw = await crypto.exportKey("raw", sessionKey)
  const sessionKeyBase64 = arrayBufferToBase64(sessionKeyRaw)

  const encryptedSessionKey = await crypto.encrypt(
    { name: "RSA-OAEP" },
    recipientPubKey,
    sessionKeyRaw
  )

  const sessionKeyExchangeUcan = ucan.encode(await ucan.build({
    issuer: await did.write(),
    audience: recipientDID,
    lifetimeInSeconds: 60 * 5, // 5 minutes
    facts: [{ sessionKey: sessionKeyBase64 }],
    potency: null,
    proof: null, // We just reconstructed the account. did.write is the user's root did, so we don't need to have delegated rights
  }))

  const { iv, msg } = await aesEncryptedString(sessionKey, sessionKeyExchangeUcan)

  const firstMessage = {
    iv: arrayBufferToBase64(iv),
    msg: arrayBufferToBase64(msg),
    sessionKey: arrayBufferToBase64(encryptedSessionKey),
  }
  console.log("sending", firstMessage)
  baseChannel.send(stringToArrayBuffer(JSON.stringify(firstMessage)))

  return new EncryptedChannel(sessionKey, baseChannel, crypto)
}

async function aesEncryptedString(sessionKey: CryptoKey, plaintext: string): Promise<{ iv: Uint8Array, msg: ArrayBuffer }> {
  const iv = window.crypto.getRandomValues(new Uint8Array(16))
  const msg = await window.crypto.subtle.encrypt(
    {
      name: "AES-GCM",
      iv: iv
    },
    sessionKey,
    uint8arrays.fromString(plaintext)
  )
  return { iv, msg }
}


function arrayBufferToBase64(buf: ArrayBuffer): string {
  return uint8arrays.toString(new Uint8Array(buf), "base64pad")
}


function arrayBufferToString(buf: ArrayBuffer): string {
  return new TextDecoder().decode(buf)
}


function base64ToArrayBuffer(b64: string): ArrayBuffer {
  return uint8arrays.fromString(b64, "base64pad").buffer
}


function stringToArrayBuffer(str: string): ArrayBuffer {
  return new TextEncoder().encode(str).buffer
}


async function retry<T>(
    action: () => Promise<T>,
    { maxRetries, signal, interval }: { maxRetries?: number, signal?: AbortSignal | null, interval?: number } = { maxRetries: -1, signal: null, interval: 200 }
  ): Promise<T> {
  const errors = []
  maxRetries = maxRetries || -1
  interval = interval || 200
  while (maxRetries-- !== 0) {
    if (signal != null && signal.aborted) {
      errors.push(new Error("Action aborted."))
      throw errors
    }
    try {
      return await action()
    } catch (e) {
      errors.push(e)
    }
    await new Promise(resolve => setTimeout(resolve, interval))
  }
  throw errors
}
