# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  chisel = {
    pname = "chisel";
    version = "f347914dee389cebbe48ac4ef2e350e5ac1d267a";
    src = fetchFromGitHub {
      owner = "chipsalliance";
      repo = "chisel";
      rev = "f347914dee389cebbe48ac4ef2e350e5ac1d267a";
      fetchSubmodules = false;
      sha256 = "sha256-4sdVOhXt2Y4pmzLpImi+jvpi2exJ5f0vuN+iLnueESk=";
    };
    date = "2024-08-15";
  };
}