{ pkgs, system, ... }:
let
  manifest = (import ./../../../../manifest.nix).nightly.latest {
    platform = (import ./../../../../config.nix).platforms.nix2release.${system};
  };
in
(import ./../../../../utils.nix).mkCangjie {
  inherit (manifest) version;
  url = "https://gitcode.com/Cangjie/nightly_build/releases/download/${manifest.version}/${manifest.asset.cangjie.name}";
  hash = manifest.asset.cangjie.hash;

  stdxurl = "https://gitcode.com/Cangjie/cangjie_stdx/releases/download/v${manifest.stdxVersion}/${manifest.asset.stdx.name}";
  stdxhash = manifest.asset.stdx.hash;

  fetchurl = pkgs.fetchurl;
  stdenv = pkgs.stdenv;
  openssl = pkgs.openssl;
  python311 = pkgs.python311;
  autoPatchelfHook = pkgs.autoPatchelfHook;
  makeWrapper = pkgs.makeWrapper;
  unzip = pkgs.unzip;
}
