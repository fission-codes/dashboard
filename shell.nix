{ pkgs ? import <nixpkgs> {} }: with pkgs;

mkShell {

  buildInputs = [

    # Dev Tools
    just
    jq
    miniserve
    watchexec

    # Elm
    elmPackages.elm
    elmPackages.elm-format

    # Node
    nodejs

  ];

}