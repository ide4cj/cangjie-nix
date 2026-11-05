{
  version,
  url,
  hash,
  subdir,
  cangjie-std,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  openssl,
  unzip,
}:
let
  systemMapping = import ./../../config.nix;
  platformDir = systemMapping.platforms.nix2reversed.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation rec {
  inherit version;

  pname = "cangjie-stdx";

  src = fetchurl { inherit url hash; };

  nativeBuildInputs = [
    autoPatchelfHook
    unzip
  ];
  buildInputs = [
    cangjie-std
    openssl
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    unzip -q ${src}
    runHook postUnpack
  '';

  # NOTE(iliayar): lib-macro_stdx.plugin.so depends on libstdx.plugin.manager.so, which is not found anywhere
  installPhase = ''
    mkdir $out
    cp -r ${platformDir}_cjnative/${subdir}/stdx $out/

    rm $out/stdx/lib-macro_stdx.plugin.so
  '';
}
