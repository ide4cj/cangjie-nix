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
        platform = (import ./config.nix).platforms.nix2release.${system};

        mkCangjieNightly = import ./source/bin/channel/nightly;
        cangjie-bin-lts = pkgs.callPackage ./source/bin/channel/lts { inherit system; };

        nightlyBuilds = builtins.listToAttrs (
          map (name: {
            name = pkgs.lib.removeSuffix ".nix" name;
            value = pkgs.callPackage mkCangjieNightly {
              inherit platform;
              date = pkgs.lib.removeSuffix ".nix" name;
            };
          }) (import ./manifest.nix).sdk.nightly.manifests
        );
        latestNightly = pkgs.callPackage mkCangjieNightly {
          inherit platform;
        };
        nightly = latestNightly.overrideAttrs (old: {
          passthru =
            (old.passthru or { })
            // nightlyBuilds
            // {
              latest = latestNightly;
            };
        });

      in
      {
        # Publish derivation
        legacyPackages = {
          inherit nightly;
          default = nightly;
          lts = cangjie-bin-lts;
        };
        # Publish app for "nix run"
        apps = {
          nightly.cjc = {
            type = "app";
            program = "${nightly.latest}/bin/cjc";
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
              nightly.latest
            ];
            shellHook = ''
              echo "Cangjie nightly development environment"
              echo "$(cjc --version)"
            '';
          };
          lts = pkgs.mkShellNoCC {
            packages = [
              cangjie-bin-lts
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
