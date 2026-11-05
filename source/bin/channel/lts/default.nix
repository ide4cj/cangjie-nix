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
in
import ../../mkCangjie.nix {
  inherit pkgs system asset;
  sdkUrl = import ./mkurl.nix;
  stdxUrl = import ../../mkstdxurl.nix;
}
