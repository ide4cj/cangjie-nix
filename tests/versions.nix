{
  pkgs,
  nightly,
  stable,
}:
let
  inherit (pkgs) lib;

  manifestTests =
    channel: sdk: dir: filename:
    let
      name = lib.removeSuffix ".nix" filename;
      inherit (import (dir + "/${filename}")) version;
    in
    {
      "test-${channel}-${name}-by-name" = {
        expr = sdk.${name}.version;
        expected = version;
      };
      "test-${channel}-${name}-by-version" = {
        expr = sdk.${version}.drvPath;
        expected = sdk.${name}.drvPath;
      };
    };

  channelTests =
    channel: sdk: dir:
    let
      pinned = lib.last (lib.remove "latest.nix" (builtins.attrNames (builtins.readDir dir)));
    in
    manifestTests channel sdk dir "latest.nix"
    // manifestTests channel sdk dir pinned
    // {
      "test-${channel}-default-is-latest" = {
        expr = sdk.drvPath;
        expected = sdk.latest.drvPath;
      };
    };

  failures = lib.runTests (
    channelTests "nightly" nightly ../manifests/sdk/nightly
    // channelTests "stable" stable ../manifests/sdk/stable
  );
in

# NOTE: unsafeDiscardStringContext prevents the derivation from actually building
pkgs.runCommand "cangjie-versions-tests" { } (
  if failures == [ ] then
    "touch $out"
  else
    ''
      cat >&2 <<'EOF'
      ${builtins.unsafeDiscardStringContext (lib.generators.toPretty { } failures)}
      EOF
      exit 1
    ''
)
