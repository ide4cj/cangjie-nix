{
  pkgs,
  system,
  asset,
  sdkUrl,
  stdxUrl,
  ...
}:
rec {
  cangjie-std = pkgs.callPackage (import ./cangjie-std.nix) {
    inherit (asset.sdk) version;
    url = sdkUrl asset.sdk;
    inherit (asset.sdk) hash;
  };

  stdx =
    let
      mkStdxSubdir =
        subdir:
        pkgs.callPackage (import ./cangjie-stdx.nix) {
          inherit (asset.stdx) version;
          url = stdxUrl asset.stdx;
          inherit (asset.stdx) hash;
          subdir = "static";
          inherit cangjie-std;
        };
    in
    {
      dynamic = mkStdxSubdir "dynamic";
      static = mkStdxSubdir "static";
    };

  cangjie-tools = pkgs.callPackage (import ./cangjie-tools.nix) {
    inherit (asset.sdk) version;
    url = sdkUrl asset.sdk;
    inherit (asset.sdk) hash;
    inherit stdx cangjie-std;
  };

  cangjie = pkgs.symlinkJoin {
    name = "cangjie";
    inherit (asset.sdk) version;
    paths = [
      cangjie-std
      cangjie-tools
    ];
  };
}
