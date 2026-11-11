{
  pkgs,
  asset,
  sdkUrl,
  stdxUrl,
  ...
}:
rec {
  unwrapped = pkgs.callPackage ./cangjie-unwrapped.nix {
    inherit (asset.sdk) version;
    url = sdkUrl asset.sdk;
    inherit (asset.sdk) hash;
  };

  stdx =
    let
      mkStdxSubdir =
        subdir:
        pkgs.callPackage ./cangjie-stdx.nix {
          inherit (asset.stdx) version;
          url = stdxUrl asset.stdx;
          inherit (asset.stdx) hash;
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

}
