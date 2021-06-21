let

  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {};

  node = pkgs.nodejs-16_x;
  node_pnpm = pkgs.nodePackages_latest.pnpm;

  pnpm = pkgs.writeScriptBin "pnpm" "${node}/bin/node ${node_pnpm}/lib/node_modules/pnpm/bin/pnpm.cjs $@";
  pnpx = pkgs.writeScriptBin "pnpx" "${node}/bin/node ${node_pnpm}/lib/node_modules/pnpm/bin/pnpx.cjs $@";

in

  pkgs.mkShell {
    buildInputs = [

      # Dev Tools
      pkgs.devd
      pkgs.just
      pkgs.watchexec
      pkgs.jq
      pkgs.niv

      # Elm
      pkgs.elmPackages.elm
      pkgs.elmPackages.elm-format

      # Node
      node
      pnpm
      pnpx

    ];
  }
