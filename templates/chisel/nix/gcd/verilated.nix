# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

{
  lib,
  stdenv,
  rtl,
  verilator,
  zlib,
  python3,
  dpi-lib,
  thread-num ? 8,
}:
let
  vName = "V${rtl.target}";
in
stdenv.mkDerivation {
  name = "verilated";

  src = rtl;

  nativeBuildInputs = [
    verilator
    python3
  ];

  # zlib is required for Rust to link against?
  # IIRC: zlib is required for
  propagatedBuildInputs = lib.optionals dpi-lib.enable-trace [ zlib ];

  passthru = {
    inherit dpi-lib;
    inherit (rtl) target;
  };

  meta.mainProgram = vName;

  buildPhase = ''
    runHook preBuild

    echo "[nix] running verilator"
    verilator \
      ${lib.optionalString dpi-lib.enable-trace "--trace-fst"} \
      --timing \
      --threads ${toString thread-num} \
      -O1 \
      --main \
      --exe \
      --cc -f filelist.f --top ${rtl.target} ${dpi-lib}/lib/${dpi-lib.libOutName}

    echo "[nix] building verilated C lib"

    # backup srcs
    mkdir -p $out/share
    cp -r obj_dir $out/share/verilated_src

    # We can't use -C here because the Makefile is generated with relative path
    cd obj_dir
    make -j "$NIX_BUILD_CORES" -f ${vName}.mk ${vName}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{include,lib,bin}
    cp *.h $out/include
    cp *.a $out/lib
    cp ${vName} $out/bin

    runHook postInstall
  '';

  # nix fortify hardening add `-O2` gcc flag,
  # we'd like verilator to controll optimization flags, so disable it.
  # `-O2` will make gcc build time in verilating extremely long
  hardeningDisable = [ "fortify" ];
}
