{ stdenvNoCC
, circt
, elaborate
}:

stdenvNoCC.mkDerivation {
  name = "mlirbc";

  nativeBuildInputs = [ circt ];

  inherit (elaborate) passthru;

  buildCommand = ''
    mkdir $out

    firtool ${elaborate}/${elaborate.name}.mlirbc \
      --emit-bytecode \
      -O=debug \
      --preserve-values=named \
      --lowering-options=verifLabels \
      --output-final-mlir=$out/$name-lowered.mlirbc
  '';
}
