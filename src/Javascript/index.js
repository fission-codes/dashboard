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
    webnativeElm.setup(elmApp, state.fs)
  })
