{ pkgs, system }:
let
  platform = (import ../../config.nix).platforms.nix2release.${system};
in
{
  nightly = args: pkgs.callPackage ./channel/nightly ({ inherit platform; } // args);
  lts = args: pkgs.callPackage ./channel/lts ({ inherit platform; } // args);
}
