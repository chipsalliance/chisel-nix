# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  chisel = {
    pname = "chisel";
    version = "57ab35eb940224f1fd93651d87b83842c416db70";
    src = fetchFromGitHub {
      owner = "chipsalliance";
      repo = "chisel";
      rev = "57ab35eb940224f1fd93651d87b83842c416db70";
      fetchSubmodules = false;
      sha256 = "sha256-8YqpmZ2Fz9l5T5vHhnsnpFZqLgBRsCE1reHsvirCI9U=";
    };
    date = "2025-03-02";
  };
}
