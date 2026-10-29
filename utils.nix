{
  mkCangjie =
    {
      version,
      url,
      hash,
      stdxurl,
      stdxhash,
      stdenv,
      fetchurl,
      makeWrapper,
      autoPatchelfHook,
      python311,
      openssl,
      unzip,
    }:
    let
      cangjieSrc = fetchurl { inherit url hash; };
      stdxSrc = fetchurl {
        url = stdxurl;
        hash = stdxhash;
      };
    in
    stdenv.mkDerivation {
      inherit version;

      pname = "cangjie";

      srcs = [
        cangjieSrc
        stdxSrc
      ];

      nativeBuildInputs = [
        makeWrapper
        autoPatchelfHook
        unzip
      ];
      # LLDB needs Python 3.11; the LTS std FFI links against OpenSSL 3.
      buildInputs = [
        stdenv.cc.cc.lib
        python311
        openssl
      ];

      dontConfigure = true;
      dontBuild = true;

      unpackPhase = ''
        runHook preUnpack

        mkdir -p src/cangjie src/stdx
        tar -xzf ${cangjieSrc} -C src
        unzip -q ${stdxSrc} -d src/stdx
        sourceRoot="src"

        runHook postUnpack
      '';

      installPhase = ''
        mkdir $out
        cp cangjie/envsetup.sh $out/
        cp -r cangjie/bin $out/
        cp -r cangjie/lib $out/
        cp -r cangjie/modules $out/
        cp -r cangjie/runtime $out/
        cp -r cangjie/third_party $out/
        cp -r cangjie/tools $out/

        cp -r stdx $out/third_party/

        ln -s $out/tools/bin/LSPServer $out/bin/
        ln -s $out/tools/bin/cjpm $out/bin/
        ln -s $out/tools/bin/cjfmt $out/bin/cjfmt
      '';

      # bintuils: Use `ld` from Nix binutils, which saves dynamic libraries path to binary's rpath
      # Could it make sense to include rpath into final binary?
      #  --append-flags "--set-runtime-rpath" \
      postFixup = ''
        wrapProgram $out/bin/cjc \
            --append-flags "-B${stdenv.cc.bintools}/bin" \
            --append-flags "-B${stdenv.cc.libc}/lib" \
            --append-flags "-L${stdenv.cc.libc}/lib" \
            --append-flags "--link-options" \
            --append-flags "-I${stdenv.cc.bintools.dynamicLinker}"
      '';
    };

}
