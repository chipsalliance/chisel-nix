# TODO: in the future, we may need to add circtbindng pass and set it by default.
{ stdenvNoCC

, espresso
, circt

, elaborator
}:

stdenvNoCC.mkDerivation {
  name = "${elaborator.name}-elaborate";

  nativeBuildInputs = [ espresso circt ];

  passthru = {
    inherit elaborator;
  };

  buildCommand = ''
    mkdir -p elaborate $out

    ${elaborator}/bin/elaborator --target-dir elaborate

    firtool elaborate/*.fir \
      --annotation-file elaborate/*.anno.json \
      --emit-bytecode \
      --parse-only \
      -o $out/$name.mlirbc
  '';
}
