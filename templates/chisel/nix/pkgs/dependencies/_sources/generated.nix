# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  chisel = {
    pname = "chisel";
    version = "d2fd2f9b5c75a00a8cbc6e42ce3ce49ba9797f16";
    src = fetchFromGitHub {
      owner = "chipsalliance";
      repo = "chisel";
      rev = "d2fd2f9b5c75a00a8cbc6e42ce3ce49ba9797f16";
      fetchSubmodules = false;
      sha256 = "sha256-/xxGYQPmE/fPB2v9zN6WmmMuJgbfTx/aB7cK0ezX1F8=";
    };
    date = "2025-02-27";
  };
}
