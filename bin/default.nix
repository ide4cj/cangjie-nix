{ pkgs, ... }:
let
  stdxVersion = "1.2.0.1";
  stdx = pkgs.fetchurl {
    url = "https://gitcode.com/Cangjie/cangjie_stdx/releases/download/v${stdxVersion}/cangjie-stdx-linux-x64-${stdxVersion}.zip";
    hash = "sha256-wDahkuj9Qga4TKmpRhGCC8ZmIxmJdfPf+HT3SNZai0c=";
  };

  mkCangjie =
    {
      version,
      url,
      hash,
      linkOption,
    }:
    pkgs.stdenv.mkDerivation {
      inherit version;

      pname = "cangjie";
      src = pkgs.fetchurl { inherit url hash; };

      nativeBuildInputs = with pkgs; [
        makeWrapper
        autoPatchelfHook
        unzip
      ];
      # LLDB needs Python 3.11; the LTS std FFI links against OpenSSL 3.
      buildInputs = [
        pkgs.stdenv.cc.cc.lib
        pkgs.python311
        pkgs.openssl
      ];

      installPhase = ''
        mkdir $out
        cp envsetup.sh $out/
        cp -r bin $out/
        cp -r lib $out/
        cp -r modules $out/
        cp -r runtime $out/
        cp -r third_party $out/
        cp -r tools $out/

        unzip -q ${stdx} -d "$out/third_party/stdx"

        ln -s $out/tools/bin/LSPServer $out/bin/
        ln -s $out/tools/bin/cjpm $out/bin/
        ln -s $out/tools/bin/cjfmt $out/bin/cjfmt
      '';

      # bintuils: Use `ld` from Nix binutils, which saves dynamic libraries path to binary's rpath
      postFixup = ''
        wrapProgram $out/bin/cjc \
            --append-flags "-B${pkgs.glibc}/lib" \
            --append-flags "-B${pkgs.stdenv.cc.cc}/lib" \
            --append-flags "-B${pkgs.binutils}/bin" \
            --append-flags "-L${pkgs.glibc}/lib" \
            --append-flags "-L${pkgs.stdenv.cc.cc.lib}/lib" \
            --append-flags "${linkOption} -I${pkgs.stdenv.cc.bintools.dynamicLinker}"
      '';
    };
in
{
  lts = mkCangjie {
    version = "1.0.5";
    url = "https://cangjie-lang.cn/v1/files/auth/downLoad?nsId=142267&fileName=cangjie-sdk-linux-x64-1.0.5.tar.gz&objectKey=698acf46bd66ae22b62330b0";
    hash = "sha256-usrYTfjgKBxTlbq0xA5IHj6mzHEu7VyVOQOw1WGhRWI=";
    linkOption = "--link-options";
  };

  nightly = mkCangjie rec {
    version = "1.3.0-alpha.20261023001052";
    url = "https://gitcode.com/Cangjie/nightly_build/releases/download/${version}/cangjie-sdk-linux-x64-${version}.tar.gz";
    hash = "sha256-ag1dawk+eLXPYeDlPnFLQEW/Hu1RYoiAptfx37+OqI8=";
    linkOption = "--link-option";
  };
}
