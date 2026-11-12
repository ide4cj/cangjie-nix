let
  mkCangjieFromAsset =
    {
      pkgs,
      asset,
      url,
    }:
    rec {
      unwrapped = pkgs.callPackage ./cangjie-unwrapped.nix {
        inherit (asset.sdk) version hash;
        url = url.sdk;
      };

      stdx =
        let
          mkStdxSubdir =
            subdir:
            pkgs.callPackage ./cangjie-stdx.nix {
              inherit (asset.stdx) version hash;
              url = url.stdx;
              inherit subdir unwrapped;
            };
        in
        {
          dynamic = mkStdxSubdir "dynamic";
          static = mkStdxSubdir "static";
        };

      cangjie = pkgs.callPackage ./wrap-cangjie.nix {
        inherit unwrapped;
        stdx = stdx.static;
      };
    };

  latestManifest = {
    sdk = import ../../manifests/sdk/lts/latest.nix;
    stdx = import ../../manifests/stdx/stable/latest.nix;
  };
  defaultUrlBuilder = {
    sdk = import channel/lts/mkurl.nix;
    stdx = import ./mkstdxurl.nix;
  };
in
{
  pkgs,
  manifest ? latestManifest,
  mkUrl ? defaultUrlBuilder,
  platform,
}:
let
  getAsset = (import ../../manifest.nix).getAsset;
  asset = {
    sdk = getAsset {
      inherit platform;
      manifest = manifest.sdk;
    };
    stdx = getAsset {
      inherit platform;
      manifest = manifest.stdx;
    };
  };
  url = {
    sdk = mkUrl.sdk asset.sdk;
    stdx = mkUrl.stdx asset.stdx;
  };
in
mkCangjieFromAsset {
  inherit pkgs asset url;
}
