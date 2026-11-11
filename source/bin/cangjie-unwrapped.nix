{
  version,
  url,
  hash,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  openssl,
  python311,
}:
stdenv.mkDerivation rec {
  inherit version;

  pname = "cangjie-unwrapped";

  src = fetchurl { inherit url hash; };

  nativeBuildInputs = [
    autoPatchelfHook
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    python311
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
    runHook preInstall
    mkdir $out
    cp envsetup.sh $out/
    cp -r bin $out/
    cp -r lib $out/
    cp -r modules $out/
    cp -r runtime $out/

    cp -r third_party $out/
    cp -r tools $out/

    ln -s ../tools/bin/LSPServer $out/bin/
    ln -s ../tools/bin/cjpm $out/bin/
    ln -s ../tools/bin/cjfmt $out/bin/
    runHook postInstall
  '';

}
