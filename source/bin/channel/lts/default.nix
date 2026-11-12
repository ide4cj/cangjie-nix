{
  pkgs,
  platform,
  sdkVersion ? "latest",
  stdxVersion ? "latest",
  ...
}:
let
  tld = ./../../../..;
  manifests = tld + /manifests;
  manifest = {
    sdk = import "${manifests}/sdk/lts/${sdkVersion}.nix";
    stdx = import "${manifests}/stdx/stable/${stdxVersion}.nix";
  };
  mkUrl = {
    sdk = import ./mkurl.nix;
    stdx = import ../../mkstdxurl.nix;
  };
in
import ../../mkCangjie.nix {
  inherit pkgs manifest mkUrl platform;
}
