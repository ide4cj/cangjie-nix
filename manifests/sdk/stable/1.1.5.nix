{
  # note: hash transformation: sha256 from website as bytes -> to base64 + 'sha256-' prefix.
  version = "1.1.5";
  assets = [
    {
      system = "linux";
      arch = "x64";
      hash = "sha256-mMlShFyYK6lz3tB9C/JsSHlBJFeVHU0oFdIz3JYwyfo=";
      objectKey = "6af2e977e4bd101f57762f70";
    }
    {
      system = "linux";
      arch = "aarch64";
      hash = "sha256-Luew+zjGtcOJlq6HENBhYXv1TUKeD5gXzVeupxo+Drg=";
      objectKey = "6af2e781e4bd101f57762f6d";
    }
    {
      system = "mac";
      arch = "aarch64";
      hash = "sha256-MHZu922R/n2z1L07z3Y9KTH1NukLx6gHDFmBIOpaotk=";
      objectKey = "6af2e393e4bd101f57762f68";
    }
  ];
}
