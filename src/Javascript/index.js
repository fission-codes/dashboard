import * as webnative from "webnative"
import * as webnativeElm from "webnative-elm"

const elmApp = Elm.Main.init()

const permissions = {
  app: {
    creator: "Fission",
    name: "Dashboard",
  },
}

webnative.setup.debug({ enabled: true })

if (window.location.hostname === "localhost") {
  setupInStaging()
}

webnative
  .initialise({
    permissions
  })
  .then(state => {
    // No need for filesystem operations at the moment
    webnativeElm.setup(elmApp, () => state.fs)

    elmApp.ports.webnativeInitialized.send(state)
    elmApp.ports.webnativeResendVerificationEmail.subscribe(async () => {
      await webnative.resendVerificationEmail()
      elmApp.ports.webnativeVerificationEmailSent.send({})
    })
  })

window.webnative = webnative


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
