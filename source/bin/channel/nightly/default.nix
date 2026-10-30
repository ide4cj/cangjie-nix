{ pkgs, system, ... }:
let
  manifest = (import ./../../../../manifest.nix).nightly.latest {
    platform = (import ./../../../../config.nix).platforms.nix2release.${system};
  };
  mkCangjie = (import ../../mkCangjieBin.nix);
  cangjieSdkUrl = version: asset:
    "https://gitcode.com/Cangjie/nightly_build/releases/download/${version}/${asset}";
  cangjieStdxUrl = version: asset:
    "https://gitcode.com/Cangjie/cangjie_stdx/releases/download/v${version}/${asset}";
in
pkgs.callPackage mkCangjie {
  inherit (manifest) version;
  url = cangjieSdkUrl manifest.version manifest.asset.cangjie.name;
  hash = manifest.asset.cangjie.hash;

  stdxurl = cangjieStdxUrl manifest.stdxVersion manifest.asset.stdx.name;
  stdxhash = manifest.asset.stdx.hash;
}
