# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  chisel = {
    pname = "chisel";
    version = "1aa41cdb7e7406c0aba3e9de3ebb06c3eb8c40d9";
    src = fetchFromGitHub {
      owner = "chipsalliance";
      repo = "chisel";
      rev = "1aa41cdb7e7406c0aba3e9de3ebb06c3eb8c40d9";
      fetchSubmodules = false;
      sha256 = "sha256-mPywOo115q7jc/2KZWf5m+bdyGF/kh6cVBIBJwSgWXI=";
    };
    date = "2024-10-10";
  };
}
