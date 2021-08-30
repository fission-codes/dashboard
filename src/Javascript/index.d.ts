import * as webnative from "webnative"
import type FileSystem from "webnative/fs/filesystem"


//----------------------------------------
// GLOBALS / CONFIG
//----------------------------------------

declare global {
  const CONFIG_ENVIRONMENT: string
  const CONFIG_API_ENDPOINT: string
  const CONFIG_LOBBY: string
  const CONFIG_USER: string

  interface Window {
    environment: string
    endpoints: {
      api: string
      lobby: string
      user: string
    }
    webnative: typeof webnative
    fs: FileSystem
    // For recovery.ts
    clearBackup: () => void
  }

  const Elm: any
}
