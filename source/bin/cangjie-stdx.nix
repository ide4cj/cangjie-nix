{
  version,
  url,
  hash,
  subdir,
  unwrapped,
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
    unwrapped
    openssl
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    unzip -q ${src}
    runHook postUnpack
  '';

  # NOTE: lib-macro_stdx.plugin.so depends on libstdx.plugin.manager.so and
  # stdx.chir.so, which exists only in "dynamic" version
  installPhase = ''
    mkdir $out
    stdx=${platformDir}_cjnative
    cp -r $stdx/${subdir}/stdx $out/

    for lib in libstdx.plugin.manager.so libstdx.chir.so; do
      [ -f "$out/stdx/$lib" ] || cp "$stdx/dynamic/stdx/$lib" "$out/stdx/"
    done
  '';
}
