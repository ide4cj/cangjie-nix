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
      in
      {
        # Publish derivation
        packages = {
          # TODO: support LTS
          # version = "1.0.5";
          # url = "https://cangjie-lang.cn/v1/files/auth/downLoad?nsId=142267&fileName=cangjie-sdk-linux-x64-1.0.5.tar.gz&objectKey=698acf46bd66ae22b62330b0";
          # hash = "sha256-usrYTfjgKBxTlbq0xA5IHj6mzHEu7VyVOQOw1WGhRWI=";
          # lts = cangjie-bin.lts;
          nightly = cangjie-bin-nightly;
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
