import type { } from "./index.d"

import type { DistinctivePath, DirectoryPath } from "webnative/path/index"
import type { IPFS } from "webnative/components/depot/implementation/ipfs/node"

import * as Fission from "webnative/components/auth/implementation/fission/index"
import * as Path from "webnative/path/index"
import * as RootKey from "webnative/common/root-key"
import * as Uint8arrays from "uint8arrays"
import * as Webnative from "webnative"
import lodashMerge from "lodash/merge"

import { PERMISSIONS_BASE, createProgramWithIPFS, ENDPOINTS } from "./webnative"


//----------------------------------------
// GLOBALS / CONFIG
//----------------------------------------

const environment = CONFIG_ENVIRONMENT
console.log(`Running in ${environment} environment`)


//----------------------------------------
// PERMISSIONS
//----------------------------------------

function lookupLocalStorage(key: string) {
  const saved = localStorage.getItem(key)
  try {
    return saved ? JSON.parse(saved) : null
  } catch (_) {
    return null
  }
}

function saveLocalStorage(key: string, json) {
  if (json == null) {
    localStorage.removeItem(key)
  }
  localStorage.setItem(key, JSON.stringify(json, null, 2))
}

const permissionsConfirmedKey = `permissions-confirmed-v1-${CONFIG_API_ENDPOINT}`
const lookupPermissionsConfirmed = () => lookupLocalStorage(permissionsConfirmedKey)
const savePermissionsConfirmed = json => saveLocalStorage(permissionsConfirmedKey, json)

const permissionsWantedKey = `permissions-wanted-v1-${CONFIG_API_ENDPOINT}`
const lookupPermissionsWanted = () => lookupLocalStorage(permissionsWantedKey)
const savePermissionsWanted = json => saveLocalStorage(permissionsWantedKey, json)

const url = new URL(window.location.href)
if (url.searchParams.get("cancelled") != null) {
  savePermissionsWanted(null)
  url.searchParams.delete("cancelled")
  history.replaceState(null, document.title, url.toString())
}

const permissionsConfirmed = lookupPermissionsConfirmed() || {}
const permissionsWanted = lookupPermissionsWanted() || {}

const permissions = lodashMerge(PERMISSIONS_BASE, permissionsConfirmed, permissionsWanted)

console.log("Permissions Confirmed:", permissionsConfirmed)
console.log("Permissions Wanted:", permissionsWanted)
console.log("Permissions now trying:", permissions)


//----------------------------------------
// SETUP ELM APP
//----------------------------------------

const elmApp = Elm.Main.init({
  flags: { permissionsBaseline: PERMISSIONS_BASE }
})

elmApp.ports.webnativeRedirectToLobby.subscribe(async ({ permissions }) => {
  console.log("Requesting permissions", permissions)
  savePermissionsWanted(permissions)
  await program().capabilities.request(permissions)
})

elmApp.ports.log.subscribe(messages => {
  console.log.apply(console, messages)
})

elmApp.ports.webnativeResendVerificationEmail.subscribe(async () => {
  try {
    const { crypto, reference } = program().components
    await Fission.resendVerificationEmail(ENDPOINTS, crypto, reference)
  } finally {
    elmApp.ports.webnativeVerificationEmailSent.send({})
  }
})

elmApp.ports.webnativeAppIndexFetch.subscribe(async () => {
  try {
    const deps = program().components
    const index = await Webnative.apps.index(ENDPOINTS, deps)
    elmApp.ports.webnativeAppIndexFetched.send(index)
  } catch (error) {
    console.error("Error while fetching the app index", error)
  }
})

elmApp.ports.webnativeAppDelete.subscribe(async appUrl => {
  try {
    const deps = program().components
    await Webnative.apps.deleteByDomain(ENDPOINTS, deps, appUrl)
    elmApp.ports.webnativeAppDeleteSucceeded.send({ app: appUrl })
  } catch (error) {
    console.error("Error while deleting an app", error)
    elmApp.ports.webnativeAppDeleteFailed.send({ app: appUrl, error: error.message })
  }
})

elmApp.ports.webnativeAppRename.subscribe(async ({ from, to }: { from: string, to: string }) => {
  try {
    const fromPath = wnfsAppPath(appNameOnly(from))
    const toPath = wnfsAppPath(appNameOnly(to))

    const deps = program().components
    const fs = fileSystem()

    const newApp = await Webnative.apps.create(ENDPOINTS, deps, appNameOnly(to))
    const cid = await getPublicPathCid(
      wnfsAppPublishPathInPublic(appNameOnly(from))
    )

    await Webnative.apps.publish(ENDPOINTS, deps, newApp.domains[ 0 ], cid)
    await fs.mv(fromPath, toPath)
    await Webnative.apps.deleteByDomain(ENDPOINTS, deps, from)

    elmApp.ports.webnativeAppRenameSucceeded.send({ app: from, renamed: newApp.domains[ 0 ] })

  } catch (error) {
    console.error(`Error while renaming an app from ${from} to ${to}`, error)
    elmApp.ports.webnativeAppRenameFailed.send({ app: from, error: error.message })

  }
})

elmApp.ports.fetchReadKey.subscribe(async () => {
  try {
    const { accountDID, components } = program()
    const { username } = session()

    const readKey = await RootKey.retrieve({
      accountDID: await accountDID(username),
      crypto: components.crypto,
    })

    elmApp.ports.fetchedReadKey.send({
      key: Uint8arrays.toString(readKey, "base64pad"),
      createdAt: (new Date()).toDateString(),
    })
  } catch (error) {
    console.error(`Error while trying to fetch the readKey for backup`, error)
    elmApp.ports.fetchReadKeyError.send(error.message)
  }
})

elmApp.ports.logout.subscribe(async () => {
  savePermissionsWanted(null)
  savePermissionsConfirmed(null)
  const session = program().session
  await session?.destroy()
  window.location.reload()
})


//----------------------------------------
// WEBNATIVE
//----------------------------------------

let maybeIPFS: IPFS | null
let maybeProgram: Webnative.Program | null


function fileSystem(): Webnative.FileSystem {
  const fs = program().session?.fs
  if (!fs) throw new Error("Expected a FileSystem instance")
  return fs
}

function ipfs(): IPFS {
  if (!maybeIPFS) throw new Error("Expected a IPFS instance")
  return maybeIPFS
}

function program(): Webnative.Program {
  if (!maybeProgram) throw new Error("Expected a Program")
  return maybeProgram
}

function session(): Webnative.Session {
  const s = program().session
  if (!s) throw new Error("Expected a Session")
  return s
}


createProgramWithIPFS()
  .then(({ ipfs, program }) => {
    maybeIPFS = ipfs
    maybeProgram = program

    if (program.session) {
      savePermissionsConfirmed(permissions)
    } else {
      savePermissionsConfirmed(null)
    }
    // There should be no further permissions we want to request in the future.
    // We either just got them, or we've got them denied. In any case we stop trying.
    savePermissionsWanted(null)

    elmApp.ports.webnativeInitialized.send({
      permissions: permissions,
      session: program.session,
    })

    // Webnative will remove search params after authorisation.
    // To keep the URL in sync, we tell Elm about it
    elmApp.ports.urlChanged.send(window.location.toString())
  })
  .catch(error => {
    console.error("Error in webnative initialisation", error)
    elmApp.ports.webnativeError.send("Initialisation error")
  })


//----------------------------------------
// SERVICE WORKER
//----------------------------------------

if ("serviceWorker" in navigator && window.location.hostname !== "localhost") {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("service-worker.js")
  })
}


//----------------------------------------
// CUSTOM ELEMENTS
//----------------------------------------

customElements.define("dashboard-upload-dropzone", class extends HTMLElement {
  inProgress: boolean

  constructor() {
    super()

    this.inProgress = false
  }

  static get observedAttributes() {
    return [ "app-name" ]
  }

  connectedCallback() {
    // Manage highlighting

    const highlight = async (event: Event) => {
      event.preventDefault()
      this.classList.add("dropping")
    }

    const unhighlight = async (event: Event) => {
      event.preventDefault()
      this.classList.remove("dropping")
    };

    [ "dragleave", "drop" ].map(ev => this.addEventListener(ev, unhighlight));
    [ "dragenter", "dragover" ].map(ev => this.addEventListener(ev, highlight));


    // File upload events

    this.addEventListener("change", async event => {
      if (this.inProgress) return
      this.inProgress = true

      event.preventDefault()
      event.stopPropagation()

      const targetInputElement = event.target as HTMLInputElement

      const getFilePath = (file: File) => {
        // We strip off the first part of an uploaded directory (e.g. build/index.html -> index.html)
        const firstSlash = file.webkitRelativePath.indexOf("/")
        const relativePath = file.webkitRelativePath.substring(firstSlash)
        return Path.fromPosix(relativePath)
      }
      const getFileContents = async (file: File) => await file.arrayBuffer()

      try {

        if (targetInputElement.files == null) {
          throw new Error("Couldn't detect files to be uploaded")
        }

        const files = Array.from(targetInputElement.files)

        this.dispatchPublishStart()

        const appDomain = await this.targetAppDomain()
        await this.publishAppFiles(appDomain, files, getFilePath, getFileContents)

        this.dispatchPublishEnd(appDomain)

      } catch (error) {

        this.dispatchPublishFail()
        throw error

      }

      this.inProgress = false
    })

    this.addEventListener("drop", async event => {
      if (this.inProgress) return
      this.inProgress = true

      event.preventDefault()
      event.stopPropagation()

      try {

        const files: FileSystemFileEntry[] = []
        const dataTransfer = event.dataTransfer

        if (dataTransfer == null) {
          throw new Error("Something went wrong when trying to detect files dropped files")
        }

        this.dispatchPublishStart()

        for (const item of dataTransfer.items) {
          const entry = item.webkitGetAsEntry()
          if (entry == null) {
            console.warn("Couldn't read dropped item", item)
            continue
          }
          const entryFiles = await listFiles(entry)
          entryFiles.forEach(entryFile => {
            files.push(entryFile)
          })
        }

        const getFilePath = (file: FileSystemFileEntry) => Path.fromPosix(file.fullPath)
        const getFileContent = async (file: FileSystemFileEntry) => {
          const asJsFile = await fileContent(file)
          return await asJsFile.arrayBuffer()
        }

        const appDomain = await this.targetAppDomain()
        await this.publishAppFiles(appDomain, files, getFilePath, getFileContent)

        this.dispatchPublishEnd(appDomain)

      } catch (error) {

        this.dispatchPublishFail()
        throw error

      }

      this.inProgress = false
    })
  }

  async targetAppDomain() {
    // Expected to be something like "long-tulip.fission.app"
    const appDomain = this.getAttribute("app-domain")
    if (appDomain == null || appDomain === "") {
      this.dispatchPublishAction("Reserving a new subdomain for your app")
      const deps = program().components
      const app = await Webnative.apps.create(ENDPOINTS, deps, null)
      return app.domains[ 0 ]
    }
    return appDomain
  }

  async publishAppFiles<T>(
    appDomain: string,
    files: T[],
    getFilePath: (file: T) => DistinctivePath<Path.Segments>,
    getFileContent: (file: T) => Promise<ArrayBuffer>
  ) {
    const appName = appNameOnly(appDomain)
    const appPath = wnfsAppPublishPathInPublic(appName)

    const fs = fileSystem()
    const deps = program().components

    this.dispatchPublishAction("Preparing publish directory")
    const path = Path.combine(Path.directory("public"), appPath)

    if (await fs.exists(path)) {
      await fs.rm(path)
    }

    const cid = await this.addAppFiles(appPath, files, getFilePath, getFileContent)

    this.dispatchPublishAction("Uploading files to fission")
    await fs.publish()

    this.dispatchPublishAction("Telling fission to publish the app")
    await Webnative.apps.publish(ENDPOINTS, deps, appDomain, cid)
  }

  async addAppFiles<T>(
    appPath: DirectoryPath<Path.Segments>,
    files: T[],
    getFilePath: (file: T) => DistinctivePath<Path.Segments>,
    getFileContent: (file: T) => Promise<ArrayBuffer>
  ) {
    let progress = 0
    const total = files.length * 2

    for (const file of files) {
      const relativePath = getFilePath(file)
      const pathString = Path.toPosix(relativePath)

      this.dispatchPublishProgress(progress, total, `Uploading file to browser: ${pathString}`)
      const arrayBuffer = await getFileContent(file)
      progress += 1

      this.dispatchPublishProgress(progress, total, `Saving file in WNFS: ${pathString}`)
      const path = Path.combine(Path.directory("public"), Path.combine(appPath, relativePath))
      await fileSystem().write(path, new Uint8Array(arrayBuffer))
      progress += 1
    }

    return await getPublicPathCid(appPath)
  }


  dispatchPublishAction(info: string) {
    console.log(info)
    this.dispatchEvent(new CustomEvent("publishAction", { detail: { info } }))
  }

  dispatchPublishProgress(progress: number, total: number, info: string) {
    console.log(progress, total, info)
    this.dispatchEvent(new CustomEvent("publishProgress", { detail: { progress, total, info } }))
  }

  dispatchPublishStart() {
    console.log("starting")
    this.dispatchEvent(new CustomEvent("publishStart"))
  }

  dispatchPublishEnd(domain: string) {
    console.log("Done. Your app is live! 🚀")
    this.dispatchEvent(new CustomEvent("publishEnd", { detail: { domain } }))
  }

  dispatchPublishFail() {
    this.dispatchEvent(new CustomEvent("publishFail"))
  }

  disconnectedCallback() {
  }
})



//----------------------------------------
// UTILITIES
//----------------------------------------

function fileContent(file: FileSystemFileEntry): Promise<File> {
  return new Promise((resolve, reject) => {
    file.file(resolve, reject)
  })
}

function directoryEntries(directory: FileSystemDirectoryEntry): Promise<FileSystemEntry[]> {
  return new Promise((resolve, reject) => {
    directory.createReader().readEntries(resolve, reject)
  })
}

const isDirectoryEntry = (entry: FileSystemEntry): entry is FileSystemDirectoryEntry => entry.isDirectory
const isFileEntry = (entry: FileSystemEntry): entry is FileSystemFileEntry => entry.isFile

async function listFiles(entry: FileSystemEntry, files: FileSystemFileEntry[] = []) {
  if (isDirectoryEntry(entry)) {
    const entries = await directoryEntries(entry)
    for (const subEntry of entries) {
      await listFiles(subEntry, files)
    }
  }
  if (isFileEntry(entry)) {
    files.push(entry)
  }
  return files
}

async function getPublicPathCid(
  appPath: DirectoryPath<Path.Segments>
) {
  const appPathString = Path.toPosix(appPath)
  const rootCid = await fileSystem().root.put()
  const { cid } = await ipfs().files.stat(`/ipfs/${rootCid}/p/${appPathString}`)
  return cid
}

function wnfsAppPublishPathInPublic(appName: string) {
  return Path.directory("Apps", appName, "Published")
}

function wnfsAppPath(appName: string) {
  return Path.directory("public", "Apps", appName)
}

function appNameOnly(appName: string): string {
  return appName.substring(0, appName.indexOf("."))
}
