import * as webnative from "webnative"
import * as webnativeElm from "webnative-elm"

const elmApp = Elm.Main.init()

const permissions = {
  app: {
    creator: "Fission",
    name: "Dashboard",
  },
  public: [
    "Apps/Published/"
  ],
}

webnative.setup.debug({ enabled: true })

if (window.location.hostname === "localhost") {
  setupInStaging()
}

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
