import * as webnative from "webnative"
import * as webnativeElm from "webnative-elm"

const elmApp = Elm.Main.init()

webnative
  .initialise({
    permissions: {
      app: { creator: "Fission", name: "Dashboard" }
    }
  })
  .then(state => {
    // webnativeElm.setup(elmApp, state.fs)
    console.log(state)

    elmApp.ports.redirectToLobby.subscribe(() => {
      webnative.redirectToLobby(state.premissions);
    });
    elmApp.ports.webnativeInitialized.send(state)
  })
