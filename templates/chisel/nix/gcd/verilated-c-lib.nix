# TODO: pass dpi lib to here.
#       maybe for the demo project, we can just use verilator -main to align the dependency w/ vcs?
{ lib
, stdenv
, rtl
, verilator
, zlib
, enable-trace ? false
}:
stdenv.mkDerivation {
  name = "verilated";

  src = rtl;

  nativeBuildInputs = [ verilator ];

  # zlib is required for Rust to link against?
  # IIRC: zlib is required for 
  propagatedBuildInputs = [ zlib ];

  buildPhase = ''
    runHook preBuild

    echo "[nix] running verilator"
    # TODO: maybe leave these args to be passed from nix?
    verilator \
      ${lib.optionalString enable-trace "--trace-fst"} \
      --timing \
      # TODO: pass threads as parameter or $NIX_BUILD_CORES
      --threads 8 \
      -O1 \
      --cc GCD

    echo "[nix] building verilated C lib"

    # backup srcs
    mkdir -p $out/share
    cp -r obj_dir $out/share/verilated_src

    # We can't use -C here because VGCD.mk is generated with relative path
    cd obj_dir
    make -j "$NIX_BUILD_CORES" -f VGCD.mk libVGCD

    runHook postBuild
  '';

  passthru = {
    inherit enable-trace;
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/include $out/lib
    cp *.h $out/include
    cp *.a $out/lib

    runHook postInstall
  '';

  # nix fortify hardening add `-O2` gcc flag,
  # we'd like verilator to controll optimization flags, so disable it.
  # `-O2` will make gcc build time in verilating extremely long
  hardeningDisable = [ "fortify" ];
}
