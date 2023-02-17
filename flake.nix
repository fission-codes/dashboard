{
  description = "fission-codes/dashboard";


  # Inputs
  # ======

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };


  # Outputs
  # =======

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.simpleFlake {
      inherit self nixpkgs;
      config = { allowBroken = true; };
      name = "fission-codes/dashboard";
      shell = ./shell.nix;
    };
}