{
  version,
  system,
  arch,
  extension ? "tar.gz",
  ...
}:
"https://gitcode.com/Cangjie/nightly_build/releases/download/${version}/cangjie-sdk-${system}-${arch}-${version}.${extension}"
