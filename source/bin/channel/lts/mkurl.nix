{
  version,
  system,
  arch,
  objectKey,
  extension ? "tar.gz",
  ...
}:
let
  nsId = "142267";
in
"https://cangjie-lang.cn/v1/files/auth/downLoad?nsId=${nsId}&fileName=cangjie-sdk-${system}-${arch}-${version}.${extension}&objectKey=${objectKey}"
