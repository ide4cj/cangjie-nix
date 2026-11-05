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
in
import ../../mkCangjie.nix {
  inherit pkgs asset;
  sdkUrl = import ./mkurl.nix;
  stdxUrl = import ../../mkstdxurl.nix;
}
