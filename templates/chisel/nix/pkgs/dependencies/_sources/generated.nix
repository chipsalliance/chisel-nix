# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  chisel = {
    pname = "chisel";
    version = "ba49fcc524db56b00ab880ba043c8b6815d2e53d";
    src = fetchFromGitHub {
      owner = "chipsalliance";
      repo = "chisel";
      rev = "ba49fcc524db56b00ab880ba043c8b6815d2e53d";
      fetchSubmodules = false;
      sha256 = "sha256-kl/GWNkcQduecT5t8ykGh87kcIB+sK+YYKe9yevhOFs=";
    };
    date = "2025-02-11";
  };
}
