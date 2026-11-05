{
  version,
  url,
  hash,
  cangjie-std,
  stdx,
  stdenv,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  python311,
}:
stdenv.mkDerivation rec {
  inherit version;

  pname = "cangjie-tools";

  src = fetchurl { inherit url hash; };

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
    cangjie-std
  ];
  # LLDB needs Python 3.11; the LTS std FFI links against OpenSSL 3.
  buildInputs = [
    stdenv.cc.cc.lib
    python311
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

    cp -r third_party $out/
    cp -r tools $out/

    mkdir $out/bin
    ln -s $out/tools/bin/LSPServer $out/bin/
    ln -s $out/tools/bin/cjpm $out/bin/
    ln -s $out/tools/bin/cjfmt $out/bin/cjfmt
  '';

  postFixup = ''
    wrapProgram $out/bin/cjpm \
        --set-default CANGJIE_STDX_PATH ${stdx.static}/stdx
  '';
}
