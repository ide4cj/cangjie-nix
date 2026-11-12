rec {
  version =
    path:
    let
      manifest = import path;
    in
    manifest.version;

  getManifests =
    dir:
    map (filename: {
      inherit filename;
      version = version (dir + "/${filename}");
    }) (builtins.attrNames (builtins.readDir dir));

  getAsset =
    { manifest, platform }:
    let
      findAsset =
        assets:
        let
          results = builtins.filter (asset: platform == "${asset.system}-${asset.arch}") assets;
        in
        if builtins.length results == 1 then
          builtins.head results
        else
          throw "Expected exactly one asset for ${platform} in manifest ${toString manifest}";

      asset = findAsset manifest.assets;
    in
    asset
    // {
      inherit (manifest) version;
    };

  sdk.nightly.latest =
    { platform }:
    let
      date = import manifests/sdk/nightly/latest.nix;
    in
    getAsset {
      manifest = import manifests/sdk/nightly/${date}.nix;
      inherit platform;
    };

  sdk.nightly.manifests = getManifests manifests/sdk/nightly;

  sdk.lts.latest =
    { platform }:
    let
      version = import manifests/sdk/lts/latest.nix;
    in
    getAsset {
      manifest = import manifests/sdk/lts/${version}.nix;
      inherit platform;
    };

  sdk.lts.manifests = getManifests manifests/sdk/lts;

  stdx.nightly.latest =
    { platform }:
    let
      version = import manifests/stdx/nightly/latest.nix;
    in
    getAsset {
      manifest = import manifests/stdx/nightly/${version}.nix;
      inherit platform;
    };

  stdx.stable.latest =
    { platform }:
    let
      version = import manifests/stdx/stable/latest.nix;
    in
    getAsset {
      manifest = import manifests/stdx/stable/${version}.nix;
      inherit platform;
    };
}
