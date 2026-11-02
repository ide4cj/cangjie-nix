{
  version,
  system,
  arch,
  extension ? "zip",
  ...
}:
"https://gitcode.com/Cangjie/cangjie_stdx/releases/download/v${version}/cangjie-stdx-${system}-${arch}-${version}.${extension}"
