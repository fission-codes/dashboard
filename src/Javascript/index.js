import * as webnative from "webnative"
import * as webnativeElm from "webnative-elm"

const elmApp = Elm.Main.init()

const permissions = {
  app: {
    creator: "Fission",
    name: "Dashboard",
  },
}


webnative
  .initialise({
    permissions
  })
  .then(state => {
    // No need for filesystem operations at the moment
    webnativeElm.setup(elmApp, state.fs)

    elmApp.ports.webnativeInitialized.send(state)
  })

window.webnative = webnative
