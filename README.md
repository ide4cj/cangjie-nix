# Nix Cangjie packages

## Usage example

### Quick shell

#### LTS (currently doesn't work)

```sh
nix env shell github:ide4cj/cangjie-nix#lts
```

#### Nightly

```sh
nix env shell github:ide4cj/cangjie-nix#nightly

# Or just cjc
nix run github:ide4cj/cangjie-nix#nightly.cjc
```

### As a flake
```nix
# flake.nix
{
  description = "devenv.cangjie";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    cangjie-nix = {
      url = "github:/ide4cj/cangjie-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, cangjie-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
        devShells.${system}.default = pkgs.mkShellNoCC {
            packages = [
                cangjie-nix.packages.${system}.nightly
            ];
            CANGJIE_HOME = "${cangjie-nix.packages.${system}.nightly}";

            shellHook = ''
                echo "~~ in cangjie environment ~~"
                echo "$(cjc --version)"
            '';
        };
    };
}

```
