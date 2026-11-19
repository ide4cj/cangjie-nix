{
  description = "Cangjie project development environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    cangjie-nix = {
      url = "github:ide4cj/cangjie-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { nixpkgs, cangjie-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      sdk = cangjie-nix.packages.${system}.default;
    in
    {

      devShells.${system}.default = pkgs.mkShell {
        packages = [ sdk ];
      };
    };
}
