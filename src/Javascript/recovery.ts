import * as webnative from "webnative"
import FileSystem from "webnative/fs/filesystem.js"
import PrivateTree from "webnative/fs/v1/PrivateTree.js"
import * as path from "webnative/path.js"
import * as ucan from "webnative/ucan/index.js"
import * as did from "webnative/did/index.js"
import * as dataRoot from "webnative/data-root.js"
import * as webnativeIpfs from "webnative/ipfs/index.js"
import * as crypto from "webnative/crypto/index.js"
import * as namefilter from "webnative/fs/protocol/private/namefilter.js"
import MMPT from "webnative/fs/protocol/private/mmpt.js"
import throttle from "lodash/throttle"

import * as awake from "./awake"
import { WebSocketChannel, TextEncodedChannel } from "./channel"

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

const RECOVERY_KIT_USERNAME_KEY = "account-recovery-username"
const RECOVERY_KIT_KEY = "account-recovery-key"

function clearRecoveryKit () {
  localStorage.removeItem(RECOVERY_KIT_USERNAME_KEY)
  localStorage.removeItem(RECOVERY_KIT_KEY)
}

window["clearRecoveryKit"] = clearRecoveryKit


//----------------------------------------
// SETUP ELM APP
//----------------------------------------

const elmApp = Elm.Recovery.Main.init({
  flags: {
    endpoints: window.endpoints,
    savedRecovery: {
      username: localStorage.getItem(RECOVERY_KIT_USERNAME_KEY),
      key: localStorage.getItem(RECOVERY_KIT_KEY)
    }
  }
})

window["elmApp"] = elmApp

elmApp.ports.verifyRecoveryKit.subscribe(async (recoveryKit: { username: string, key: string }) => {
  try {
    const ipfsPromise = webnativeIpfs.get()
    const rootCID = await tryRethrowing(
      dataRoot.lookupOnFisson(recoveryKit.username),
      e => ({
        isUserError: true,
        message: `We couldn't find a user with name "${recoveryKit.username}".`,
        contactSupport: false,
        original: e,
      })
    )

    if (rootCID == null) {
      throw {
        isUserError: true,
        message: `We couldn't find a user with name "${recoveryKit.username}".`,
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

    const privateName = await getRootBlockPrivateName(recoveryKit.key)

    const mmpt = await tryRethrowing(
      MMPT.fromCID(mmptCID),
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
        message: "This recovery kit is invalid.",
        contactSupport: true,
        original: null,
      }
    }
    elmApp.ports.verifyRecoveryKitSucceeded.send(recoveryKit)
  } catch (e) {
    if (e.isUserError) {
      elmApp.ports.verifyRecoveryKitFailed.send({ message: e.message, contactSupport: e.contactSupport })
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
  localStorage.setItem(RECOVERY_KIT_USERNAME_KEY, username)
})
elmApp.ports.saveRecoveryKit.subscribe(async (recoveryKit: string) => {
  localStorage.setItem(RECOVERY_KIT_KEY, recoveryKit)
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


elmApp.ports.linkingInitiate.subscribe(async ({ username, rootPublicKey, readKey }: { username: string, rootPublicKey: string, readKey: string | null }) => {
  const keystorePublicWriteKey = await crypto.keystore.publicWriteKey()
  if (keystorePublicWriteKey !== rootPublicKey) {
    console.error("The public key in the keystore is not the same as the public key used for account recovery", keystorePublicWriteKey, rootPublicKey)
  }

  // If we can't recover the user's files, we generate a new read key for them
  const actualReadKey = readKey != null ? readKey : await crypto.aes.genKeyStr()

  // as well as create a new private root in their filesystem
  if (readKey == null) {
    await addNewPrivateRootToFileSystem(username, actualReadKey)
  }

  // After that, we can start authorizing auth lobbies
  const wssApi = window.endpoints.api.replace(/^https?:\/\//, "wss://")
  const rootDID = did.publicKeyToDid(rootPublicKey, did.KeyType.RSA)
  const endpoint = `${wssApi}/user/link/${rootDID}`
  const socket = new WebSocket(endpoint)
  const socketChannel = new WebSocketChannel(socket)
  const textChannel = new TextEncodedChannel(socketChannel)

  console.log("Connected to websocket at", endpoint)

  socket.onmessage = m => console.log("got websocket response", m.data)

  while (socket.readyState === socket.OPEN || socket.readyState === socket.CONNECTING) {
    try {
      console.log("Trying to run awake protocol")

      const throwawayDID = await textChannel.receive()

      const authorized = await awake.authorize({
        inquirerThrowawayDID: throwawayDID,
        channel: socketChannel,
        readKey: actualReadKey,
        validChallenge: challenge => new Promise(resolve => {
          elmApp.ports.linkingPinVerified.subscribe(pinVerified)

          function pinVerified(isVerified: boolean) {
            elmApp.ports.linkingPinVerified.unsubscribe(pinVerified)
            resolve(isVerified)
          }

          elmApp.ports.linkingPinVerification.send(challenge)
        })
      }, {
        log: console.log,
        retriesOnMessages: 10,
        retryIntervalMs: 200,
      })

      if (authorized) {
        clearRecoveryKit()
        await webnative.keystore.clear()
        elmApp.ports.linkingDone.send({})
        return
      }
    } catch (e) {
      console.error("Failed an awake protocol try")
      console.error(e)
    }
  }
})


async function addNewPrivateRootToFileSystem(username: string, readKey: string): Promise<void> {
  console.log("Loading filesystem")

  const cid = await dataRoot.lookup(username)

  if (cid == null) {
    console.log("No filesystem exists yet - initialising")

    const permissions = {
      fs: {
        private: [ path.root() ],
        public: [ path.root() ]
      }
    }
    const fs = await FileSystem.empty({
      rootKey: readKey,
      permissions,
      localOnly: true,
    })

    // initialise filesystem like in auth-lobby
    await fs.mkdir(path.directory("private", "Apps"))
    await fs.mkdir(path.directory("private", "Audio"))
    await fs.mkdir(path.directory("private", "Documents"))
    await fs.mkdir(path.directory("private", "Photos"))
    await fs.mkdir(path.directory("private", "Video"))

    console.log("updating data root")

    await uploadFileSystem(fs)

    console.log("initialised filesystem")

    return
  }

  const fs = await FileSystem.fromCID(cid, {
    permissions: {
      fs: {
        public: [path.root()],
        private: [],
      }
    }
  })

  console.log("Adding new private root")

  const newPrivateRoot = await PrivateTree.create(fs.root.mmpt, readKey, null)
  fs.root.privateNodes[path.toPosix(path.directory("private"))] = newPrivateRoot
  await newPrivateRoot.put()
  fs.root.updatePuttable("private", fs.root.mmpt)
  const newCID = await fs.root.mmpt.put()
  await fs.root.addPrivateLogEntry(newCID)

  console.log("updating data root")

  await uploadFileSystem(fs)

  console.log("reinitialised private filesystem")
}

async function uploadFileSystem(fs: FileSystem): Promise<void> {
  const issuer = await did.write()
  const fsUcan = await ucan.build({
    potency: "APPEND",
    resource: "*",

    audience: issuer,
    issuer
  })
  await dataRoot.update(await fs.root.put(), ucan.encode(fsUcan))
}
