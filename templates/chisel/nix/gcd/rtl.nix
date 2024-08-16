{ lib
, stdenvNoCC
, circt
, mlirbc
, mfcArgs ? [
    "-O=release"
    "--split-verilog"
    "--preserve-values=all"
    "--verification-flavor=if-else-fatal"
    "--lowering-options=verifLabels,omitVersionComment"
    "--strip-debug-info"
  ]
}:

stdenvNoCC.mkDerivation {
  name = "t1-${mlirbc.elaborateConfig}-${mlirbc.elaborateTarget}-rtl";
  nativeBuildInputs = [ circt ];

  passthru = {
    inherit (mlirbc) elaborateTarget elaborateConfig;
  };

  buildCommand = ''
    mkdir -p $out

    firtool ${mlirbc}/${mlirbc.name}-lowered.mlirbc -o $out ${lib.escapeShellArgs mfcArgs}

    # For blackbox module, there are also some manually generated system verilog file for test bench.
    # Those files are now recorded in a individual file list.
    # However, verilator still expect on "filelist.f" file to record all the system verilog file.
    # Below is a fix that concat them into one file to make verilator happy.
    echo "Fixing generated filelist.f"
    cp $out/filelist.f original.f
    cat $out/firrtl_black_box_resource_files.f original.f > $out/filelist.f
  '';
}
