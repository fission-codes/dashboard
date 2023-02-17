import type { } from "./index.d"
import type { IPFS } from "webnative/components/depot/implementation/ipfs/node"

import * as DID from "webnative/did/index"
import * as Namefilter from "webnative/fs/protocol/private/namefilter"
import * as Path from "webnative/path/index"
import * as Uint8arrays from "uint8arrays"
import * as UCAN from "webnative/ucan/index"
import * as Webnative from "webnative"

import FileSystem from "webnative/fs/filesystem"
import PrivateTree from "webnative/fs/v1/PrivateTree"
import MMPT from "webnative/fs/protocol/private/mmpt"
import throttle from "lodash/throttle"

import * as Awake from "./awake"
import { SymmAlg } from "webnative/components/crypto/implementation"
import { WebSocketChannel, TextEncodedChannel } from "./channel"
import { createProgramWithIPFS, ENDPOINTS } from "./webnative"
import { EventEmitter } from "webnative/events"


//----------------------------------------
// GLOBALS / CONFIG
//----------------------------------------

const environment = CONFIG_ENVIRONMENT
console.log(`Running in ${environment} environment`)

const RECOVERY_KIT_USERNAME_KEY = "account-recovery-username"
const RECOVERY_KIT_KEY = "account-recovery-key"

function clearRecoveryKit() {
  localStorage.removeItem(RECOVERY_KIT_USERNAME_KEY)
  localStorage.removeItem(RECOVERY_KIT_KEY)
}


//----------------------------------------
// WEBNATIVE
//----------------------------------------

let maybeIPFS: IPFS | null
let maybeProgram: Webnative.Program | null


function ipfs(): IPFS {
  if (!maybeIPFS) throw new Error("Expected a IPFS instance")
  return maybeIPFS
}

function program(): Webnative.Program {
  if (!maybeProgram) throw new Error("Expected a Program")
  return maybeProgram
}

createProgramWithIPFS().then(({ ipfs, program }) => {
  maybeIPFS = ipfs
  maybeProgram = program
})


//----------------------------------------
// SETUP ELM APP
//----------------------------------------

const elmApp = Elm.Recovery.Main.init({
  flags: {
    endpoints: {
      api: `${ENDPOINTS.server}${ENDPOINTS.apiPath}`,
      lobby: ENDPOINTS.lobby,
      user: ENDPOINTS.userDomain,
    },
    savedRecovery: {
      username: localStorage.getItem(RECOVERY_KIT_USERNAME_KEY),
      key: localStorage.getItem(RECOVERY_KIT_KEY)
    }
  }
})

elmApp.ports.verifyRecoveryKit.subscribe(async (recoveryKit: { username: string, key: string }) => {
  const { components } = program()

  try {
    const rootCID = await tryRethrowing(
      components.reference.dataRoot.lookup(recoveryKit.username),
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

    const { cid: mmptCID } = await tryRethrowing(
      ipfs().dag.resolve(`/ipfs/${rootCID}/private`),
      e => ({
        isUserError: true,
        message: "Something went wrong: We couldn't find a private filesystem in your personal datastore.",
        contactSupport: true,
        original: e,
      })
    )

    const privateName = await getRootBlockPrivateName(
      Uint8arrays.fromString(recoveryKit.key, "base64pad")
    )

    const mmpt = await tryRethrowing(
      MMPT.fromCID(components.depot, mmptCID),
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

async function getRootBlockPrivateName(key: Uint8Array): Promise<Namefilter.PrivateName> {
  const { crypto } = program().components
  const bareName = await Namefilter.createBare(crypto, key)
  const revisionName = await Namefilter.addRevision(crypto, bareName, key, 1)
  return await Namefilter.toPrivateName(crypto, revisionName)
}


elmApp.ports.usernameExists.subscribe(
  throttle(async (username: string) => {
    const { auth } = program()
    if (await auth.isUsernameValid(username)) {
      const exists = !await auth.isUsernameAvailable(username)
      elmApp.ports.usernameExistsResponse.send({ username, valid: true, exists })
    } else {
      elmApp.ports.usernameExistsResponse.send({ username, valid: false, exists: true })
    }
  }, 500, { leading: false, trailing: true })
)


elmApp.ports.saveUsername.subscribe(async (username: string) => {
  localStorage.setItem(RECOVERY_KIT_USERNAME_KEY, username)
})
elmApp.ports.saveRecoveryKit.subscribe(async (recoveryKit: string) => {
  localStorage.setItem(RECOVERY_KIT_KEY, recoveryKit)
})


elmApp.ports.fetchWritePublicKey.subscribe(async () => {
  try {
    const { components } = program()
    // Make sure to generate a new publicWriteKey
    await components.crypto.keystore.clearStore()
    const publicKeyBase64 = await components.crypto.keystore.publicWriteKey()
    elmApp.ports.writePublicKeyFetched.send(publicKeyBase64)
  } catch (e) {
    elmApp.ports.writePublicKeyFailure.send(e.message)
  }
})


elmApp.ports.linkingInitiate.subscribe(async ({ username, rootPublicKey, readKey }: { username: string, rootPublicKey: string, readKey: string | null }) => {
  const { crypto } = program().components
  const keystorePublicWriteKey = Uint8arrays.toString(
    await crypto.keystore.publicWriteKey(),
    "base64pad"
  )

  if (keystorePublicWriteKey !== rootPublicKey) {
    console.error("The public key in the keystore is not the same as the public key used for account recovery", keystorePublicWriteKey, rootPublicKey)
  }

  // If we can't recover the user's files, we generate a new read key for them
  const actualReadKey = readKey != null
    ? Uint8arrays.fromString(readKey, "base64pad")
    : await crypto.aes.exportKey(
      await crypto.aes.genKey(SymmAlg.AES_GCM)
    )

  // as well as create a new private root in their filesystem
  if (readKey == null) {
    await addNewPrivateRootToFileSystem(username, actualReadKey)
  }

  // After that, we can start authorizing auth lobbies
  const wssApi = ENDPOINTS.server.replace(/^https?:\/\//, "wss://")
  const rootDID = DID.publicKeyToDid(crypto, Uint8arrays.fromString(rootPublicKey, "base64pad"), "rsa")
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

      const authorized = await Awake.authorize({ crypto }, {
        inquirerThrowawayDID: throwawayDID,
        channel: socketChannel,
        readKey: Uint8arrays.toString(actualReadKey, "base64pad"),
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
        await crypto.keystore.clearStore()
        elmApp.ports.linkingDone.send({})
        return
      }
    } catch (e) {
      console.error("Failed an awake protocol try")
      console.error(e)
    }
  }
})


async function addNewPrivateRootToFileSystem(username: string, readKey: Uint8Array): Promise<void> {
  console.log("Loading filesystem")

  const { crypto, depot, manners, reference } = program().components
  const cid = await reference.dataRoot.lookup(username)
  const rootDID = await reference.didRoot.lookup(username)

  if (cid == null) {
    console.log("No filesystem exists yet - initialising")

    const permissions = {
      fs: {
        private: [ Path.root() ],
        public: [ Path.root() ]
      }
    }
    const fs = await FileSystem.empty({
      account: { rootDID },
      dependencies: program().components,
      eventEmitter: new EventEmitter(),
      rootKey: readKey,
      permissions,
      localOnly: true,
    })

    // initialise filesystem like in auth-lobby
    await fs.mkdir(Path.directory("private", "Apps"))
    await fs.mkdir(Path.directory("private", "Audio"))
    await fs.mkdir(Path.directory("private", "Documents"))
    await fs.mkdir(Path.directory("private", "Photos"))
    await fs.mkdir(Path.directory("private", "Video"))

    console.log("updating data root")

    await uploadFileSystem(fs)

    console.log("initialised filesystem")

    return
  }

  const fs = await FileSystem.fromCID(cid, {
    account: { rootDID },
    dependencies: program().components,
    eventEmitter: new EventEmitter(),
    permissions: {
      fs: {
        public: [ Path.root() ],
        private: [],
      }
    }
  })

  console.log("Adding new private root")

  const newPrivateRoot = await PrivateTree.create(crypto, depot, manners, reference, fs.root.mmpt, readKey, null)
  fs.root.privateNodes[ Path.toPosix(Path.directory("private")) ] = newPrivateRoot
  await newPrivateRoot.put()
  fs.root.updatePuttable("private", fs.root.mmpt)
  const newCID = await fs.root.mmpt.put()
  await fs.root.addPrivateLogEntry(depot, newCID)

  console.log("updating data root")

  await uploadFileSystem(fs)

  console.log("reinitialised private filesystem")
}

async function uploadFileSystem(fs: FileSystem): Promise<void> {
  const { crypto, reference } = program().components

  const issuer = await DID.write(crypto)
  const fsUcan = await UCAN.build({
    dependencies: { crypto },

    potency: "APPEND",
    resource: "*",

    audience: issuer,
    issuer
  })
  await reference.dataRoot.update(
    await fs.root.put(),
    fsUcan
  )
}
