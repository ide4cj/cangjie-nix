let
  tld = ./../../../..;
  manifests = tld + /manifests;
in
{
  pkgs,
  platform,
  sdkVersion ? "latest",
  stdxVersion ? sdkVersion,
  ...
}:
let
  manifest = {
    sdk = import "${manifests}/sdk/nightly/${sdkVersion}.nix";
    stdx = import "${manifests}/stdx/nightly/${stdxVersion}.nix";
  };
  mkUrl = {
    sdk = import ./mkurl.nix;
    stdx = import ./mkstdxurl.nix;
  };
in
import ../../mkCangjie.nix {
  inherit pkgs manifest mkUrl platform;
}
