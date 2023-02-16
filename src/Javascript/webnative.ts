import type { } from "./index.d"
import type { IPFS } from "webnative/components/depot/implementation/ipfs/node"

import * as FissionAuthWithWnfs from "webnative/components/auth/implementation/fission-wnfs"
import * as FissionLobby from "webnative/components/capabilities/implementation/fission-lobby"
import * as FissionReference from "webnative/components/reference/implementation/fission-base"
import * as IpfsBase from "webnative/components/depot/implementation/ipfs"

import * as Ipfs from "webnative/components/depot/implementation/ipfs/index"
import * as Webnative from "webnative"

import { Components } from "webnative/components.js"
import { Configuration, namespace } from "webnative"
import { Endpoints } from "webnative/common/fission"


// 🍱


export const PERMISSIONS_BASE = {
  app: {
    name: "Dashboard",
    creator: "Fission"
  },
  fs: {
    public: [ { directory: [ "Apps" ] } ],
  },
  platform: {
    apps: "*" as "*",
  },
}



// 🏔


export const CONFIG: Configuration = {
  namespace: `dashboard-${CONFIG_USER}`,
  debug: true,

  fileSystem: {
    loadImmediately: false,
  },

  permissions: PERMISSIONS_BASE,

  userMessages: {
    versionMismatch: {
      newer: async version => alert(`Your auth lobby is outdated. It might be cached. Try reloading the page until this message disappears.\n\nIf this doesn't help, please contact support@fission.codes.\n\n(Filesystem version: ${version}. Webnative version: ${Webnative.VERSION})`),
      older: async version => alert(`Your filesystem is outdated.\n\nPlease upgrade your filesystem by running a miration (https://guide.fission.codes/accounts/account-signup/account-migration) or click on "remove this device" and create a new account.\n\n(Filesystem version: ${version}. Webnative version: ${Webnative.VERSION})`),
    }
  }
}


export const ENDPOINTS: Endpoints = {
  apiPath: "/v2/api",
  lobby: CONFIG_LOBBY,
  server: CONFIG_API_ENDPOINT,
  userDomain: CONFIG_USER
}



// 🛠


export async function createProgramWithIPFS(): Promise<{ program: Webnative.Program; ipfs: IPFS }> {
  const crypto = await Webnative.defaultCryptoComponent(CONFIG)
  const storage = Webnative.defaultStorageComponent(CONFIG)

  // Depot
  const { ipfs, repo } = await Ipfs.nodeWithPkg(
    { storage },
    await Ipfs.pkgFromCDN(Ipfs.DEFAULT_CDN_URL),
    `${ENDPOINTS.server}/ipfs/peers`,
    `${namespace(CONFIG)}/ipfs`,
    false
  )

  const depot = await IpfsBase.implementation(async () => ({ ipfs, repo }))

  // Manners
  const manners = Webnative.defaultMannersComponent(CONFIG)

  // Remaining
  const capabilities = FissionLobby.implementation(ENDPOINTS, { crypto, depot })
  const reference = await FissionReference.implementation(ENDPOINTS, { crypto, manners, storage })
  const auth = FissionAuthWithWnfs.implementation(ENDPOINTS, { crypto, reference, storage })

  // Fin
  const components: Components = {
    auth,
    capabilities,
    crypto,
    depot,
    manners,
    reference,
    storage,
  }

  return {
    program: await Webnative.assemble(CONFIG, components),
    ipfs: ipfs as unknown as IPFS,
  }
}