# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  chisel = {
    pname = "chisel";
    version = "058f1624f274240c27592953c28b52a8c2af5d6a";
    src = fetchFromGitHub {
      owner = "chipsalliance";
      repo = "chisel";
      rev = "058f1624f274240c27592953c28b52a8c2af5d6a";
      fetchSubmodules = false;
      sha256 = "sha256-VZ4yV0QC7tOumr45IEs/oqOsMFC2xNUxynA20uQjbm4=";
    };
    date = "2024-11-18";
  };
}
