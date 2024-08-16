{ stdenvNoCC
, circt
, elaborate
}:

stdenvNoCC.mkDerivation {
  name = "${elaborate.name}-mlirbc";

  nativeBuildInputs = [ circt ];

  passthru = {
    inherit elaborate;
  };

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
