{ lib, stdenvNoCC, circt, mlirbc, mfcArgs ? [
  "-O=release"
  "--split-verilog"
  "--preserve-values=all"
  "--verification-flavor=if-else-fatal"
  "--lowering-options=verifLabels,omitVersionComment"
  "--strip-debug-info"
], enable-layers ? [ ] }:
let
  processLayer = lib.map (str: "./" + lib.replaceStrings [ "." ] [ "/" ] str);
  enableLayersDirs = processLayer enable-layers;
in stdenvNoCC.mkDerivation {
  name = "${mlirbc.name}-rtl";
  nativeBuildInputs = [ circt ];

  passthru = { inherit mlirbc; };

  buildCommand = ''
    mkdir -p $out

    firtool ${mlirbc}/${mlirbc.name}-lowered.mlirbc -o $out ${
      lib.escapeShellArgs mfcArgs
    }

    pushd $out
    find . ${
      lib.concatStringsSep " " enableLayersDirs
    } -maxdepth 1 -name "*.sv" -type f -print > ./filelist.f
    popd
  '';
}
