let
  tld = ./../../../..;
  manifests = tld + /manifests;
in
{
  pkgs,
  platform,
  version ? (import "${manifests}/sdk/lts/latest.nix"),
  stdxVersion ? (import "${manifests}/stdx/stable/latest.nix"),
  ...
}:
let
  getAsset = (import "${tld}/manifest.nix").getAsset;
  asset = {
    sdk = getAsset {
      manifest = import "${manifests}/sdk/lts/${version}.nix";
      inherit platform;
    };
    stdx = getAsset {
      manifest = import "${manifests}/stdx/stable/${stdxVersion}.nix";
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
