let
  tld = ./../../../..;
  manifests = tld + /manifests;
in
{
  pkgs,
  platform,
  date ? import "${manifests}/sdk/nightly/latest.nix",
  ...
}:
let
  getAsset = (import "${tld}/manifest.nix").getAsset;
  asset = {
    sdk = getAsset {
      manifest = import "${manifests}/sdk/nightly/${date}.nix";
      inherit platform;
    };
    stdx = getAsset {
      manifest = import "${manifests}/stdx/nightly/${date}.nix";
      inherit platform;
    };
  };
  mkCangjie = (import ../../mkCangjieBin.nix);
  cangjieSdkUrl = import ./mkurl.nix;
  cangjieStdxUrl = import ./mkstdxurl.nix;
in
pkgs.callPackage mkCangjie {
  inherit (asset.sdk) version;
  url = cangjieSdkUrl asset.sdk;
  inherit (asset.sdk) hash;

  stdxurl = cangjieStdxUrl asset.stdx;
  stdxhash = asset.stdx.hash;
}
