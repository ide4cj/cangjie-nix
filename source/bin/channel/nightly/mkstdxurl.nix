{
  version,
  system,
  arch,
  extension ? "zip",
  ...
}:
# For some reason, they name stdx package with ".1" suffix before extension.
"https://gitcode.com/Cangjie/nightly_build/releases/download/${version}/cangjie-stdx-${system}-${arch}-${version}.1.${extension}"
