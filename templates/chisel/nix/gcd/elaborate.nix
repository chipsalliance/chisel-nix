# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

# TODO: in the future, we may need to add circtbindng pass and set it by default.
{ lib, stdenvNoCC, espresso, circt, elaborator }:
stdenvNoCC.mkDerivation {
  name = "${elaborator.name}-elaborate";

  nativeBuildInputs = [ espresso circt ];

  src = ./../../configs;
  passthru = {
    inherit elaborator;
    inherit (elaborator) target;
  };

  buildCommand = ''
    mkdir -p elaborate $out

    ${elaborator}/bin/elaborator design --parameter $src/${elaborator.target}.json --target-dir elaborate

    firtool elaborate/*.fir \
      --annotation-file elaborate/*.anno.json \
      --emit-bytecode \
      --parse-only \
      -o $out/$name.mlirbc
  '';
}
