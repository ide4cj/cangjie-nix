{ pkgs, system }: {
  nightly = pkgs.callPackage ./channel/nightly { inherit system; };
  lts = pkgs.callPackage ./channel/lts { inherit system; };
}
