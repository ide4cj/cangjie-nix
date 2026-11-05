{
  version,
  url,
  hash,
  stdenv,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  openssl,
}:
stdenv.mkDerivation rec {
  inherit version;

  pname = "cangjie-std";

  src = fetchurl { inherit url hash; };

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    openssl
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    tar -xzf ${src}
    sourceRoot="cangjie"
    runHook postUnpack
  '';

  installPhase = ''
    mkdir $out
    cp envsetup.sh $out/
    cp -r bin $out/
    cp -r lib $out/
    cp -r modules $out/
    cp -r runtime $out/

    mkdir -p $out/third_party/llvm/bin
    cp third_party/llvm/bin/opt $out/third_party/llvm/bin/
    cp third_party/llvm/bin/llc $out/third_party/llvm/bin/
    cp third_party/llvm/bin/llvm-objcopy $out/third_party/llvm/bin/

    mkdir -p $out/third_party/llvm/lib
    cp third_party/llvm/lib/libLLVM-15.so $out/third_party/llvm/lib/
  '';

  # stdenv.cc.bintools: Use `ld` from Nix binutils, which saves dynamic libraries path to binary's rpath
  # stdenv.cc.libc: Search path for Scrt1.o, crti.o
  # stdenv.cc.cc: Search path for crtbeginS.o
  #
  # Could it make sense to include rpath into final binary?
  #  --append-flags "--set-runtime-rpath" \
  postFixup = ''
    wrapProgram $out/bin/cjc \
        --append-flags "-B${stdenv.cc.bintools}/bin" \
        --append-flags "-B${stdenv.cc.libc}/lib" \
        --append-flags "-B${stdenv.cc.cc}/lib" \
        --append-flags "-L${stdenv.cc.libc}/lib" \
        --append-flags "--link-options" \
        --append-flags "-I${stdenv.cc.bintools.dynamicLinker}"
  '';
}
