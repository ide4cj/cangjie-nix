{ pkgs, system, ... }:
let
  manifest = import ./../../../../manifest.nix;
  platform = (import ./../../../../config.nix).platforms.nix2release.${system};
  asset = {
    sdk = manifest.sdk.lts.latest {
      inherit platform;
    };
    stdx = manifest.stdx.stable.latest {
      inherit platform;
    };
  };
  mkCangjie = (import ../../mkCangjieBin.nix);
  cangjieSdkUrl = import ./mkurl.nix;
  cangjieStdxUrl = import ../../mkstdxurl.nix;
in
pkgs.callPackage mkCangjie {
  inherit (asset.sdk) version;
  url = cangjieSdkUrl asset.sdk;
  inherit (asset.sdk) hash;

  stdxurl = cangjieStdxUrl asset.stdx;
  stdxhash = asset.stdx.hash;
}
