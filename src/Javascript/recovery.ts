
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


//----------------------------------------
// SETUP ELM APP
//----------------------------------------

const elmApp = Elm.Recovery.Main.init({
  flags: { }
})
