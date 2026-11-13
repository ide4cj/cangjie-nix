{ pkgs, system }:
let
  platform = (import ../../config.nix).platforms.nix2release.${system};
in
{
  nightly = args: pkgs.callPackage ./channel/nightly ({ inherit platform; } // args);
  stable = args: pkgs.callPackage ./channel/stable ({ inherit platform; } // args);
}
