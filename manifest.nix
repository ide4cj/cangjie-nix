let
  getManifests =
    dir: versionFormat:
    builtins.filter (
      name:
      (builtins.readDir dir).${name} == "regular" # regular files only
      && builtins.match "${versionFormat}\\.nix" name != null
    ) (builtins.attrNames (builtins.readDir dir));
in
rec {
  version =
    path:
    let
      manifest = import path;
    in
    manifest.version;

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

  # <year>-<month>-<day>
  sdk.nightly.versionFormat = "[0-9]{4}-[0-9]{2}-[0-9]{2}";

  sdk.nightly.manifests = getManifests manifests/sdk/nightly sdk.nightly.versionFormat;

  sdk.lts.latest =
    { platform }:
    let
      version = import manifests/sdk/lts/latest.nix;
    in
    getAsset {
      manifest = import manifests/sdk/lts/${version}.nix;
      inherit platform;
    };

  # <major>-<minor>-<patch>
  sdk.lts.versionFormat = "[0-9]+\.[0-9]+\.[0-9]+";

  sdk.lts.manifests = getManifests manifests/sdk/lts sdk.lts.versionFormat;

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
