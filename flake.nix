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
        manifest = import ./manifest.nix;
        bin = import ./source/bin { inherit pkgs system; };

        mkBuilds =
          {
            manifests,
            mkPackage,
          }:
          builtins.listToAttrs (
            builtins.concatMap (
              manifest:
              let
                name = pkgs.lib.removeSuffix ".nix" manifest.filename;
                build = mkPackage name;
              in
              [
                {
                  inherit name;
                  value = build;
                }
                {
                  name = manifest.version;
                  value = build;
                }
              ]
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

        nightlyBuilds = mkBuilds {
          manifests = manifest.sdk.nightly.manifests;
          mkPackage = sdkVersion: (bin.nightly { inherit sdkVersion; }).cangjie;
        };

        stableBuilds = mkBuilds {
          manifests = manifest.sdk.stable.manifests;
          mkPackage = sdkVersion: (bin.stable { inherit sdkVersion; }).cangjie;
        };

        nightlyStdxBuilds = mkBuilds {
          manifests = manifest.stdx.nightly.manifests;
          mkPackage = sdkVersion: (bin.nightly { inherit sdkVersion; }).stdx;
        };

        stableStdxBuilds = mkBuilds {
          manifests = manifest.stdx.stable.manifests;
          mkPackage = stdxVersion: (bin.stable { inherit stdxVersion; }).stdx;
        };

        nightlyPackages = bin.nightly { };
        stablePackages = bin.stable { };
        nightly = populateDerivations nightlyPackages.cangjie nightlyBuilds;
        stable = populateDerivations stablePackages.cangjie stableBuilds;
      in
      {
        # Publish derivation
        packages = {
          inherit nightly stable;
          default = stable;
          stdx = {
            nightly =
              nightlyPackages.stdx
              // nightlyStdxBuilds
              // {
                latest = nightlyPackages.stdx;
              };
            stable =
              stablePackages.stdx
              // stableStdxBuilds
              // {
                latest = stablePackages.stdx;
              };
          };
        };
        apps = {
          nightly = mkApps nightly.latest;
          stable = mkApps stable.latest;
        }
        // mkApps stable.latest;

        checks = {
          versions = import ./tests/versions.nix { inherit pkgs nightly stable; };
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
          stable = pkgs.mkShellNoCC {
            packages = [
              stable.latest
            ];
            shellHook = ''
              echo "Cangjie LTS development environment"
              echo "$(cjc --version)"
            '';
          };
          default = self.devShells.${system}.stable;
        };
      }
    );
}
