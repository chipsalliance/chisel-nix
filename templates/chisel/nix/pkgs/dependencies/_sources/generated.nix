# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  chisel = {
    pname = "chisel";
    version = "e7178e57aeefb77b6a991d6d8804547c6136ad26";
    src = fetchFromGitHub {
      owner = "chipsalliance";
      repo = "chisel";
      rev = "e7178e57aeefb77b6a991d6d8804547c6136ad26";
      fetchSubmodules = false;
      sha256 = "sha256-mClcIrG+bpNZX8etS5FieQ4/0IjnXEHVGJk7oeAacag=";
    };
    date = "2024-09-27";
  };
}
