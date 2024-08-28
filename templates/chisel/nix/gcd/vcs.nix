# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

{ lib, bash, stdenv, rtl, dpi-lib, vcs-fhs-env }:

stdenv.mkDerivation {
  name = "vcs";

  # Add "sandbox = relaxed" into /etc/nix/nix.conf, and run `systemctl restart nix-daemon`
  #
  # run nix build with "--impure" flag to build this package without chroot
  # require license
  __noChroot = true;
  dontPatchELF = true;

  src = rtl;

  buildPhase = ''
    runHook preBuild

    echo "[nix] running VCS"
    fhsBash=${vcs-fhs-env}/bin/vcs-fhs-env
    VERDI_HOME=$("$fhsBash" -c "printenv VERDI_HOME")
    "$fhsBash" vcs \
      -sverilog \
      -full64 \
      -timescale=1ns/1ps \
      -P $VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab $VERDI_HOME/share/PLI/VCS/LINUX64/pli.a \
      ${
        lib.optionalString dpi-lib.enable-trace ''
          -debug_access+pp+dmptf+thread \
          -kdb=common_elab,hgldd_all''
      } \
      -file filelist.f \
      -assert enable_diag \
      ${dpi-lib}/lib/libgcdemu.a \
      -o gcd-vcs-simulator

    runHook postBuild
  '';

  passthru = {
    inherit (dpi-lib) enable-trace;
    inherit vcs-fhs-env;
    inherit dpi-lib;
    inherit rtl;
  };

  shellHook = ''
    echo "[nix] entering fhs env"
    ${vcs-fhs-env}/bin/vcs-fhs-env
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib
    cp gcd-vcs-simulator $out/lib
    cp -r gcd-vcs-simulator.daidir $out/lib

    # We need to carefully handle string escape here, so don't use makeWrapper
    tee $out/bin/gcd-vcs-simulator <<EOF
    #!${bash}/bin/bash
    export LD_LIBRARY_PATH="$out/lib/gcd-vcs-simulator.daidir:\$LD_LIBRARY_PATH"
    _argv="\$@"
    ${vcs-fhs-env}/bin/vcs-fhs-env -c "$out/lib/gcd-vcs-simulator \$_argv"
    EOF
    chmod +x $out/bin/gcd-vcs-simulator

    runHook postInstall
  '';
}
