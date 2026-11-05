{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{ nixpkgs, flake-utils, ... }:
    # TODO: add support for other systems
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        bin = import ./source/bin { inherit pkgs system; };
      in
      {
        # Publish derivation
        packages = {
          nightly = bin.nightly.cangjie;
          lts = bin.lts.cangjie;

          stdx = {
            nightly = bin.nightly.stdx;
            # TODO: lts
          };
        };
        # Publish app for "nix run"
        apps = {
          nightly.cjc = {
            type = "app";
            program = "${bin.nightly.cangjie}/bin/cjc";
            meta = {
              description = "Cangjie compiler";
            };
          };
          lts.cjc = {
            type = "app";
            program = "${bin.lts.cangjie}/bin/cjc";
            meta = {
              description = "Cangjie compiler";
            };
          };
        };

        # Publish devShell for "nix develop"
        devShells = {
          nightly = pkgs.mkShellNoCC {
            packages = [
              bin.nightly.cangjie
            ];
            shellHook = ''
              echo "Cangjie nightly development environment"
              echo "$(cjc --version)"
            '';
          };
          lts = pkgs.mkShellNoCC {
            packages = [
              bin.lts.cangjie
            ];
            shellHook = ''
              echo "Cangjie LTS development environment"
              echo "$(cjc --version)"
            '';
          };
        };
      }
    );
}
