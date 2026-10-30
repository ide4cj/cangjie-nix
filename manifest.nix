rec {
  version =
    path:
    let
      manifest = import path;
    in
    manifest.version;

  getAsset =
    { manifest, assetName }:
    let
      findAsset =
        assetName: assets:
        let
          results = builtins.filter (asset: asset.name == assetName) assets;
        in
        if builtins.length results == 1 then
          builtins.head results
        else
          throw "Expected exactly one asset named ${assetName} in manifest ${toString manifest}";

      asset = findAsset assetName manifest.assets;
    in
    {
      inherit (manifest) version;
      inherit (asset) name hash;
    };

  sdkAsset =
    { path, platform }:
    let
      manifest = import path;
    in
    getAsset {
      inherit manifest;
      assetName = "cangjie-sdk-${platform}-${manifest.version}.tar.gz";
    };

  stdxAsset =
    { path, platform }:
    let
      manifest = import path;
    in
    getAsset {
      inherit manifest;
      assetName = "cangjie-stdx-${platform}-${manifest.version}.zip";
    };

  sdk.nightly.latest =
    { platform }:
    let
      date = import manifests/sdk/nightly/latest.nix;
    in
    sdkAsset {
      path = manifests/sdk/nightly/${date}.nix;
      inherit platform;
    };

  sdk.lts.latest =
    { platform }:
    let
      version = import manifests/sdk/lts/latest.nix;
    in
    getAsset {
      path = TODO: fix lts asset name for comparison!!
      assetName = "cangjie-sdk-${platform}-${manifest.version}.tar.gz";
    };
    sdkAsset {
      path = manifests/sdk/lts/${version}.nix;
      inherit platform;
    };

  stdx.stable.latest =
    { platform }:
    let
      version = import manifests/stdx/stable/latest.nix;
    in
    stdxAsset {
      path = manifests/stdx/stable/${version}.nix;
      inherit platform;
    };
}
