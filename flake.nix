{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    # TODO: add support for other systems
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        platform = (import ./config.nix).platforms.nix2release.${system};
        bin = import ./source/bin { inherit pkgs system; };

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
                value = (mkCangjie truncatedName).cangjie;
              }
            ) manifests
          );

        mkApp =
          {
            sdk,
            appName,
            description ? appName,
          }:
          {
            type = "app";
            program = "${sdk}/bin/${appName}";
            meta = {
              inherit description;
            };
          };

        mkApps = channel: {
          cjc = mkApp {
            sdk = channel;
            appName = "cjc";
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
          mkCangjie = bin.nightly;
        };

        ltsBuilds = pkgs.callPackage mkBuilds {
          manifests = (import ./manifest.nix).sdk.lts.manifests;
          mkCangjie = bin.lts;
        };

        nightly = populateDerivations (bin.nightly {}).cangjie nightlyBuilds;
        lts = populateDerivations (bin.lts {}).cangjie ltsBuilds;
      in
      {
        # Publish derivation
        packages = {
          inherit nightly lts;
          default = lts;
          # TODO: versioning for stdx
          stdx = {
            nightly = (bin.nightly {}).stdx;
            lts = (bin.lts {}).stdx;
          };
        };
        apps = {
          nightly = mkApps nightly.latest;
          lts = mkApps lts.latest;
        }
        // mkApps lts.latest;

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
          default = self.devShells.${system}.lts;
        };
      }
    );
}
