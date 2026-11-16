{
  # note: hash transformation: sha256 from website as bytes -> to base64 + 'sha256-' prefix.
  version = "1.2.1";
  assets = [
    {
      system = "linux";
      arch = "x64";
      hash = "sha256-VhZiT8tI2xUN8qzN5maaLIzF6FHXnmI6VGnE5M16SR8="; 
      objectKey = "6af2edbae4bd101f57762f7c";
    }
    {
      system = "linux";
      arch = "aarch64";
      hash = "sha256-XA9YFm8ofX0TF+ykFkRrzf0i0P6L/GLDjePkv9qLeR0="; 
      objectKey = "6af2edbbe4bd101f57762f7d";
    }
    {
      system = "mac";
      arch = "aarch64";
      hash = "sha256-a3vcO+1bjs184HdBs3k7kR93XVxwotijFgiOLcYh2Nk="; 
      objectKey = "6af2ec43e4bd101f57762f78";
    }
  ];
}
