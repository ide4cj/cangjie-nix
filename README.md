# nix-cangjie

Declarative and reproducible Cangjie packages with Nix.

Features:
- Automatically manages up-to-date Cangjie SDK version.
- Supports SDK version pinning.

## Platforms

The following cangjie packages are provided.

| system | architecture    | source |
|--------|-----------------|--------|
| linux  | aarch64, x86_64 | bin    |
| mac    | TBD             | TBD    |

> [!NOTE]
> Currently, SDK flavor for cross-compilation is not supported.

> [!NOTE]
> SDK package from git source with local build is not yet supported. Only prebilt artifacts are packaged. 

## Versions

Cangjie is provided from the following up-to-date channels:
- Stable (LTS)
- Nightly

Provided packages:
- `cangjie-nix` which is defaulted to `cangjie-nix.lts`
- `cangjie-nix.lts` which is defaulted to `cangjie-nix.lts.latest`
- `cangjie-nix.nightly` which is defaulted to `cangjie-nix.nightly.latest`

Besides latest SDK, you can pin specific version, like:
- `cangjie-nix.lts."1.0.5"` (format: `major.minor.patch`)
- `cangjie-nix.nightly."2026-11-06"` (format: `yyyy-mm-dd`)

Stable versions support:
- `1.0.5` (LTS)

## Usage example

### Quick shell

Latest LTS SDK:
```sh
nix env shell github:ide4cj/cangjie-nix#lts
```

Latest nightly SDK:
```sh
nix env shell github:ide4cj/cangjie-nix#nightly
```

Specific pinned nightly SDK:
```sh
nix env shell github:ide4cj/cangjie-nix#nightly.2026-11-06
```

Latest nightly `cjc`:
```sh
nix run github:ide4cj/cangjie-nix#nightly.cjc
```

### As a flake
```nix
# flake.nix
{
  description = "devenv.cangjie";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    cangjie-nix = {
      url = "github:ide4cj/cangjie-nix";
    };
  };

  outputs = { self, nixpkgs, cangjie-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      sdk = cangjie-nix.packages.${system};
      nightly = sdk.nightly.override { 
        inherit (pkgs) stdenv;
        stdx = null;
      };
      #      OR sdk.lts
    in {
      devShells.${system} = {
        nightly = pkgs.mkShell {
          packages = [ nightly ];

          CANGJIE_HOME = "${nightly}";
          CANGJIE_STDX_PATH = "${sdk.stdx.lts.dynamic}/stdx";

          shellHook = ''
            echo "~~ in cangjie environment ~~"
            echo "$(cjc --version)"
          '';
        };

        default = self.devShells.${system}.nightly;
      };
    };
}

```
