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
        mkCangjieLts = import ./source/bin/channel/lts;

        mkBuilds =
          {
            pkgs,
            manifests,
            mkCangjie,
          }:
          builtins.listToAttrs (
            map (
              name:
              let
                truncatedName = pkgs.lib.removeSuffix ".nix" name;
              in
              {
                name = truncatedName;
                value = mkCangjie truncatedName;
              }
            ) manifests
          );

        mkApp = sdk: {
          type = "app";
          program = "${sdk}/bin/cjc";
          meta = {
            description = "Cangjie compiler";
          };
        };

        populateDerivations =
          latestDerivation: allDerivations:
          latestDerivation.overrideAttrs (old: {
            passthru =
              (old.passthru or { })
              // allDerivations
              // {
                latest = latestDerivation;
              };
          });

        nightlyBuilds = pkgs.callPackage mkBuilds {
          manifests = (import ./manifest.nix).sdk.nightly.manifests;
          mkCangjie =
            date:
            (pkgs.callPackage mkCangjieNightly {
              inherit platform;
              inherit date;
            });
        };

        ltsBuilds = pkgs.callPackage mkBuilds {
          manifests = (import ./manifest.nix).sdk.lts.manifests;
          mkCangjie =
            version:
            (pkgs.callPackage mkCangjieLts {
              inherit platform;
              inherit version;
            });
        };

        latestNightly = pkgs.callPackage mkCangjieNightly {
          inherit platform;
        };
        latestLts = pkgs.callPackage mkCangjieLts {
          inherit platform;
        };

        nightly = populateDerivations latestNightly nightlyBuilds;
        lts = populateDerivations latestLts ltsBuilds;
      in
      {
        # Publish derivation
        packages = {
          inherit nightly;
          inherit lts;
          default = lts;
        };
        apps = {
          nightly.cjc = mkApp nightly.latest;
          cjc = mkApp nightly.latest;
          lts.cjc = mkApp lts.latest;
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
              lts.latest
            ];
            shellHook = ''
              echo "Cangjie LTS development environment"
              echo "$(cjc --version)"
            '';
          };
          default = lts;
        };
      }
    );
}
