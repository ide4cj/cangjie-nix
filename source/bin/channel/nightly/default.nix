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
in
import ../../mkCangjie.nix {
  inherit pkgs asset;
  sdkUrl = import ./mkurl.nix;
  stdxUrl = import ./mkstdxurl.nix;
}
