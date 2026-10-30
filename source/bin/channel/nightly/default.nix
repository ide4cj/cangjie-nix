{ pkgs, system, ... }:
let
manifest = import ./../../../../manifest.nix;
platform = (import ./../../../../config.nix).platforms.nix2release.${system};
asset = {
  sdk = manifest.sdk.nightly.latest {
    inherit platform;
  };
  stdx = manifest.stdx.stable.latest {
    inherit platform;
  };
};
  mkCangjie = (import ../../mkCangjieBin.nix);
  cangjieSdkUrl = { version, asset }:
    "https://gitcode.com/Cangjie/nightly_build/releases/download/${version}/${asset}";
  cangjieStdxUrl = { version, asset }:
    "https://gitcode.com/Cangjie/cangjie_stdx/releases/download/v${version}/${asset}";
in
pkgs.callPackage mkCangjie {
  inherit (asset.sdk) version;
  url = cangjieSdkUrl {
    inherit (asset.sdk) version;
    asset = asset.sdk.name;
  };
  inherit (asset.sdk) hash;

  stdxurl = cangjieStdxUrl {
    inherit (asset.stdx) version;
    asset = asset.stdx.name;
  };
  stdxhash = asset.stdx.hash;
}
