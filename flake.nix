{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{ nixpkgs, flake-utils, ... }:
    # TODO: add support for other systems
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        cangjie-bin-nightly = pkgs.callPackage ./source/bin/channel/nightly { inherit system; };
        cangjie-bin-lts = pkgs.callPackage ./source/bin/channel/lts { inherit system; };
      in
      {
        # Publish derivation
        packages = {
          nightly = cangjie-bin-nightly;
          lts = cangjie-bin-lts;
        };
        # Publish app for "nix run"
        apps = {
          nightly.cjc = {
            type = "app";
            program = "${cangjie-bin-nightly}/bin/cjc";
            meta = {
              description = "Cangjie compiler";
            };
          };
          lts.cjc = {
            type = "app";
            program = "${cangjie-bin-lts}/bin/cjc";
            meta = {
              description = "Cangjie compiler";
            };
          };
        };

        # Publish devShell for "nix develop"
        devShells = {
          nightly = pkgs.mkShellNoCC {
            packages = [
              cangjie-bin-nightly
            ];
            shellHook = ''
              echo "Cangjie nightly development environment"
              echo "$(cjc --version)"
            '';
          };
        };
      }
    );
}
