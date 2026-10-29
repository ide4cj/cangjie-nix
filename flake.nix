{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      cangjie-bin = import ./bin { inherit pkgs; };
    in
    {
      packages.${system} = {
        lts = cangjie-bin.lts;
        nightly = cangjie-bin.nightly;
      };
      apps.${system} = {
        cjc = {
          type = "app";
          program = "${cangjie-bin.nightly}/bin/cjc";
          meta = {
            description = "Cangjie compiler";
          };
        };
      };
    };
}
