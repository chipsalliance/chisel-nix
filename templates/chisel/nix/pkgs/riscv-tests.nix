{ lib, stdenv, fetchFromGitHub, riscv-test-env ? null }:

stdenv.mkDerivation rec {
  pname = "riscv-tests";
  version = "7878085d2546af0eb7af72a1df00996d5d8c43fb";
  src = fetchFromGitHub {
    owner = "riscv-software-src";
    repo = "riscv-tests";
    rev = "${version}";
    hash = "sha256-CruSrXVO5Qlk63HPBVbwzl/RdxAAl2bknWawDHJwEKY=";
  };

  # Use users env when specified
  postUnpack = lib.optionalString (riscv-test-env != null) ''
    rm -rf $sourceRoot/env
    cp -r ${riscv-test-env} $sourceRoot/env
  '';

  enableParallelBuilding = true;

  configureFlags = [
    # to match rocket-tools path
    "--prefix=${placeholder "out"}/${stdenv.targetPlatform.config}"
  ];

  buildPhase = ''
    runHook preBuild

    make RISCV_PREFIX=${stdenv.targetPlatform.config}-

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    make install
    mkdir -p $out/debug/
    cp debug/*.py $out/debug/

    runHook postInstall
  '';
}
