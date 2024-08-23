{ lib, stdenvNoCC, circt, mlirbc, mfcArgs ? [
  "-O=release"
  "--split-verilog"
  "--preserve-values=all"
  "--verification-flavor=if-else-fatal"
  "--lowering-options=verifLabels,omitVersionComment"
  "--strip-debug-info"
] }:
stdenvNoCC.mkDerivation {
  name = "${mlirbc.name}-rtl";
  nativeBuildInputs = [ circt ];

  passthru = { inherit mlirbc; };

  buildCommand = ''
    mkdir -p $out

    firtool ${mlirbc}/${mlirbc.name}-lowered.mlirbc -o $out ${
      lib.escapeShellArgs mfcArgs
    }
  '';
}
