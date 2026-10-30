rec {
  version =
    path:
    let
      manifest = import path;
    in
    manifest.version;

  sdk =
    { path, platform }:
    let
      manifest = import path;
      cangjieAssetName = "cangjie-sdk-${platform}-${manifest.version}.tar.gz";
      stdxAssetName = "cangjie-stdx-${platform}-${manifest.stdxVersion}.zip";
      findAsset =
        assetName: assets:
        let
          results = builtins.filter (asset: asset.name == assetName) assets;
        in
        if builtins.length results == 1 then
          builtins.head results
        else
          throw "Expected exactly one asset named ${assetName} in ${toString path}";

      asset = {
        cangjie = findAsset cangjieAssetName manifest.assets.cangjie;
        stdx = findAsset stdxAssetName manifest.assets.stdx;
      };
    in
    {
      inherit (manifest) version stdxVersion;
      inherit asset;
    };

  nightly.latest =
    { platform }:
    let
      date = import manifests/nightly/latest.nix;
    in
    sdk {
      path = manifests/nightly/${date}.nix;
      inherit platform;
    };
}
