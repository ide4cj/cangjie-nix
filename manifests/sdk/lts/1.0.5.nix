{
  # note: hash transformation: sha256 from website as bytes -> to base64 + 'sha256-' prefix.
  version = "1.0.5";
  assets = [
    {
      system = "linux";
      arch = "x64";
      hash = "sha256-usrYTfjgKBxTlbq0xA5IHj6mzHEu7VyVOQOw1WGhRWI=";
      objectKey = "698acf46bd66ae22b62330b0";
    }
    {
      system = "linux";
      arch = "aarch64";
      hash = "sha256-wNxIuIUf2HhTMIvw71zOcED4aBropTAF1drIFld0WjU=";
      objectKey = "698acfa3bd66ae22b62330b1";
    }
    # {
    #   system = "windows";
    #   arch = "x64";
    #   hash = "sha256-CMbB3Q3nM5b2OshQhdY155zoT++Y0zDLAIabT8jxyy4=";
    #   objectKey = "698acebfbd66ae22b62330af";
    # }
    {
      system = "mac";
      arch = "aarch64";
      hash = "sha256-4H0iWEI38GWzCncbcRCoeokxM0xAvjoUgJCUSukW7R8=";
      objectKey = "698acea5bd66ae22b62330ae";
    }
  ];
}
