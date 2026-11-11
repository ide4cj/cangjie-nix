{
  unwrapped,
  stdx,
  stdenv,
  symlinkJoin,
  makeWrapper,
}:
symlinkJoin {
  name = "cangjie-${unwrapped.version}";
  inherit (unwrapped) version;
  paths = [ unwrapped ];
  nativeBuildInputs = [ makeWrapper ];

  passthru = { inherit unwrapped; };
  meta.mainProgram = "cjc";

  postBuild =
    let
      cangjie-stdx-path = if stdx == null then "" else "${stdx}/stdx";
    in
    ''
      rm "$out/bin/cjc" "$out/bin/cjpm"

      makeWrapper "${unwrapped}/bin/cjc" "$out/bin/cjc" \
        --append-flags "-B${stdenv.cc.bintools}/bin" \
        --append-flags "-B${stdenv.cc.libc}/lib" \
        --append-flags "-B${stdenv.cc.cc}/lib" \
        --append-flags "-L${stdenv.cc.libc}/lib" \
        --append-flags "-L${stdenv.cc.cc.lib}/lib" \
        --append-flags "--link-options" \
        --append-flags "-I${stdenv.cc.bintools.dynamicLinker}"

      makeWrapper "${unwrapped}/bin/cjpm" "$out/bin/cjpm" \
        --set-default CANGJIE_STDX_PATH "${cangjie-stdx-path}" \
        --set CANGJIE_HOME "$out" \
        --prefix PATH : "$out/bin" \
    '';
}
