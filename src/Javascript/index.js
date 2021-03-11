import * as webnative from "webnative"
import * as webnativeElm from "webnative-elm"

const elmApp = Elm.Main.init()

const permissions = {
  app: {
    creator: "Fission",
    name: "Dashboard",
  },
  fs: {
    publicPaths: ["/Apps"]
  },
}

webnative.setup.debug({ enabled: true })

// if (window.location.hostname === "localhost") {
//   setupInStaging()
// }

window.webnative = webnative

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

    elmApp.ports.webnativeInitialized.send(state)
  })
  .catch(error => {
    console.error("Error in webnative initialization", error)
    elmApp.ports.webnativeError.send(error)
  });


if ("serviceWorker" in navigator && window.location.hostname !== "localhost") {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("service-worker.js")
  })
}


customElements.define("dashboard-upload-dropzone", class extends HTMLElement {
  constructor() {
    super()
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
    }

    this.addEventListener("dragleave", unhighlight);
    ["dragenter", "dragover"].map(ev => this.addEventListener(ev, highlight))


    // File upload events

    this.addEventListener("change", async event => {
      event.preventDefault()
      event.stopPropagation()

      const files = Array.from(event.target.files)

      const appName = this.getAttribute("app-name")
      console.log(appName)
      if (appName == null) return
      const appUrl = `${appName}.fission.app`
      const appPath = `Apps/${appName}/Published`

      if (await fs.exists(`public/${appPath}`)) {
        console.log("Removing all previous files")
        await fs.rm(`public/${appPath}`)
        console.log("Done")
      }

      const cid = await addAppFiles(appPath, files, async file => {
        const firstSlash = file.webkitRelativePath.indexOf("/")
        const relativePath = file.webkitRelativePath.substring(firstSlash)
        return {
          arrayBuffer: await file.arrayBuffer(),
          relativePath,
        }
      })

      console.log("Uploading files")
      await fs.publish()
      console.log("Done")

      console.log("Uploading app to fission", cid)
      await webnative.apps.update(appUrl, cid)
      console.log("Done. Your app is live! 🚀")
    })

    this.addEventListener("drop", async event => {
      event.preventDefault()
      event.stopPropagation()

      unhighlight(event)

      const appName = this.getAttribute("app-name")
      console.log(appName)
      if (appName == null) return
      const appUrl = `${appName}.fission.app`
      const appPath = `Apps/${appName}/Published`

      const files = []
      for (const item of event.dataTransfer.items) {
        const entry = item.webkitGetAsEntry()
        const entryFiles = await listFiles(entry)
        entryFiles.forEach(entryFile => {
          console.log("Recognized uploaded file", entryFile.fullPath)
          files.push(entryFile)
        })
      }

      if (await fs.exists(`public/${appPath}`)) {
        console.log("Removing all previous files")
        await fs.rm(`public/${appPath}`)
        console.log("Done")
      }

      const cid = await addAppFiles(appPath, files, async entry => {
        const asJsFile = await fileContent(file)
        const content = await asJsFile.arrayBuffer()
        return {
          arrayBuffer: content,
          relativePath: entry.fullPath,
        }
      })

      console.log("Uploading files")
      await fs.publish()
      console.log("Done")

      console.log("Uploading app to fission", cid)
      await webnative.apps.update(appUrl, cid)
      console.log("Done. Your app is live! 🚀")
    })
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

async function addAppFiles(appPath, files, getFileInfo) {
  await Promise.all(files.map(async file => {
    const { arrayBuffer, relativePath } = await getFileInfo(file)
    await fs.write(`public/${appPath}${relativePath}`, arrayBuffer)
    console.log("Added file", relativePath)
  }))

  const ipfs = await webnative.ipfs.get()
  const rootCid = await fs.root.put()
  const { cid } = await ipfs.files.stat(`/ipfs/${rootCid}/p/${appPath}/`)
  return cid.toBaseEncodedString()
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
