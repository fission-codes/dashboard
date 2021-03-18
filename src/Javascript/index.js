import * as webnative from "webnative"
import * as webnativeElm from "webnative-elm"

const elmApp = Elm.Main.init()

const permissions = {
  app: {
    creator: "Fission",
    name: "Dashboard",
  },
  fs: {
    publicPaths: ["Apps"],
  },
  platform: {
    apps: "*",
  },
}

webnative.setup.debug({ enabled: true })
setupInStaging()

// if (window.location.hostname === "localhost") {
//   setupInStaging()
// }

window.webnative = webnative

elmApp.ports.webnativeRedirectToLobby.subscribe(async () => {
  await webnative.redirectToLobby(permissions)
})

webnative
  .initialise({
    permissions
  })
  .then(state => {
    // Subscribe to ports first, so we make sure to never miss any Elm commands.
    elmApp.ports.webnativeResendVerificationEmail.subscribe(async () => {
      try {
        await webnative.lobby.resendVerificationEmail()
      } finally {
        elmApp.ports.webnativeVerificationEmailSent.send({})
      }
    })

    elmApp.ports.webnativeAppIndexFetch.subscribe(async () => {
      try {
        const index = await webnative.apps.index()
        elmApp.ports.webnativeAppIndexFetched.send(index)
      } catch (error) {
        console.error("Error while fetching the app index", error)
      }
    })

    // No need for filesystem operations at the moment
    webnativeElm.setup(elmApp, () => state.fs)

    window.fs = state.fs;

    console.log(state)

    elmApp.ports.webnativeInitialized.send(state)
  })
  .catch(error => {
    console.error("Error in webnative initialisation", error)
    elmApp.ports.webnativeError.send("Initialisation error")
  });


if ("serviceWorker" in navigator && window.location.hostname !== "localhost") {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("service-worker.js")
  })
}


customElements.define("dashboard-upload-dropzone", class extends HTMLElement {
  constructor() {
    super()

    this.inProgress = false
  }

  static get observedAttributes() {
    return ["app-name"]
  }

  connectedCallback() {
    // Manage highlighting

    const highlight = async event => {
      event.preventDefault()
      this.classList.add("dropping")
    }

    const unhighlight = async event => {
      event.preventDefault()
      this.classList.remove("dropping")
    };

    ["dragleave", "drop"].map(ev => this.addEventListener(ev, unhighlight));
    ["dragenter", "dragover"].map(ev => this.addEventListener(ev, highlight));


    // File upload events

    this.addEventListener("change", async event => {
      if (this.inProgress) return
      this.inProgress = true

      event.preventDefault()
      event.stopPropagation()

      const files = Array.from(event.target.files)

      const getFilePath = file => {
        // We strip off the first part of an uploaded directory (e.g. build/index.html -> index.html)
        const firstSlash = file.webkitRelativePath.indexOf("/")
        const relativePath = file.webkitRelativePath.substring(firstSlash)
        return relativePath
      }
      const getFileContents = async file => await file.arrayBuffer()

      try {

        this.dispatchPublishStart()

        const appName = await this.targetAppName()
        await this.publishAppFiles(appName, files, getFilePath, getFileContents)

        this.dispatchPublishEnd(appName)

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

        this.dispatchPublishStart()

        const files = []
        for (const item of event.dataTransfer.items) {
          const entry = item.webkitGetAsEntry()
          const entryFiles = await listFiles(entry)
          entryFiles.forEach(entryFile => {
            files.push(entryFile)
          })
        }

        const getFilePath = file => file.fullPath
        const getFileContent = async file => {
          const asJsFile = await fileContent(file)
          return await asJsFile.arrayBuffer()
        }

        const appName = await this.targetAppName()
        await this.publishAppFiles(appName, files, getFilePath, getFileContent)

        this.dispatchPublishEnd(appName)

      } catch (error) {

        this.dispatchPublishFail()
        throw error

      }

      this.inProgress = false
    })
  }

  async targetAppName() {
    let appName = this.getAttribute("app-name")
    if (appName == null || appName === "") {
      this.dispatchPublishAction("Reserving a new subdomain for your app")
      appName = await webnative.apps.create()
      // We only want the part before the .fission.app
      appName = appName.substring(0, appName.indexOf("."))
    }
    return appName
  }

  async publishAppFiles(appName, files, getFilePath, getFileContent) {
    const appUrl = `${appName}.fission.app`
    const appPath = `Apps/${appName}/Published`

    this.dispatchPublishAction("Preparing publish directory")
    if (await fs.exists(`public/${appPath}`)) {
      await fs.rm(`public/${appPath}`)
    }

    const cid = await this.addAppFiles(appPath, files, getFilePath, getFileContent)

    this.dispatchPublishAction("Uploading files to fission")
    await fs.publish()

    this.dispatchPublishAction("Telling fission to publish the app")
    await webnative.apps.publish(appUrl, cid)
  }

  async addAppFiles(appPath, files, getFilePath, getFileContent) {
    let progress = 0
    const total = files.length * 2

    for (const file of files) {
      const relativePath = getFilePath(file)

      this.dispatchPublishProgress(progress, total, `Uploading file to browser: ${relativePath}`)
      const arrayBuffer = await getFileContent(file)
      progress += 1

      this.dispatchPublishProgress(progress, total, `Saving file in WNFS: ${relativePath}`)
      await fs.write(`public/${appPath}${relativePath}`, arrayBuffer)
      progress += 1
    }

    const ipfs = await webnative.ipfs.get()
    const rootCid = await fs.root.put()
    const { cid } = await ipfs.files.stat(`/ipfs/${rootCid}/p/${appPath}/`)
    return cid.toBaseEncodedString()
  }


  dispatchPublishAction(info) {
    console.log(info)
    this.dispatchEvent(new CustomEvent("publishAction", { detail: { info } }))
  }

  dispatchPublishProgress(progress, total, info) {
    console.log(progress, total, info)
    this.dispatchEvent(new CustomEvent("publishProgress", { detail: { progress, total, info } }))
  }

  dispatchPublishStart() {
    console.log("starting")
    this.dispatchEvent(new CustomEvent("publishStart"))
  }

  dispatchPublishEnd(appName) {
    console.log("Done. Your app is live! 🚀")
    this.dispatchEvent(new CustomEvent("publishEnd", { detail: { appName } }))
  }

  dispatchPublishFail() {
    this.dispatchEvent(new CustomEvent("publishFail"))
  }

  disconnectedCallback() {
  }

  attributeChangedCallback(name, oldValue, newValue) {
  }
})


// Utilities

function setupInStaging() {
  console.log("Running in staging environment")
  webnative.setup.debug({ enabled: true })
  webnative.setup.endpoints({
    api: "https://runfission.net",
    lobby: "https://auth.runfission.net",
    user: "fissionuser.net"
  })
}

function fileContent(file) {
  return new Promise((resolve, reject) => {
    file.file(resolve, reject)
  })
}

function directoryEntries(directory) {
  return new Promise((resolve, reject) => {
    directory.createReader().readEntries(resolve, reject)
  })
}

async function listFiles(entry, files = []) {
  if (entry.isDirectory) {
    const entries = await directoryEntries(entry)
    for (const subEntry of entries) {
      await listFiles(subEntry, files)
    }
  }
  if (entry.isFile) {
    files.push(entry)
  }
  return files
}
