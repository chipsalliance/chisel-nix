# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

{
  lib,
  bash,
  stdenv,
  rtl,
  dpi-lib,
  vcs-fhs-env,
  runCommand,
  enableCover ? true,
}:

let
  binName = "gcd-vcs-simulator";
  coverageName = "coverage.vdb";
in
stdenv.mkDerivation (finalAttr: {
  name = "vcs";

  # Add "sandbox = relaxed" into /etc/nix/nix.conf, and run `systemctl restart nix-daemon`
  #
  # run nix build with "--impure" flag to build this package without chroot
  # require license
  __noChroot = true;
  dontPatchELF = true;

  src = rtl;

  meta.mainProgram = binName;

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
      ${lib.optionalString dpi-lib.enable-trace ''
        -debug_access+pp+dmptf+thread \
        -kdb=common_elab,hgldd_all \
        -assert enable_diag ''} \
      ${lib.optionalString enableCover ''
        -cm line+cond+fsm+tgl+branch+assert \
        -cm_dir ${coverageName} ''} \
      -file filelist.f \
      ${dpi-lib}/lib/${dpi-lib.libOutName} \
      -o ${binName}

    runHook postBuild
  '';

  passthru = {
    inherit (dpi-lib) enable-trace;
    inherit vcs-fhs-env;
    inherit dpi-lib;
    inherit rtl;

    tests.simple-sim = runCommand "${binName}-test" { __noChroot = true; } ''
      export GCD_SIM_RESULT_DIR="$(mktemp -d)"
      export DATA_ONLY=1
      ${finalAttr.finalPackage}/bin/${binName}

      mkdir -p "$out"
      cp -vr "$GCD_SIM_RESULT_DIR"/result/* "$out/"
    '';
  };

  shellHook = ''
    echo "[nix] entering fhs env"
    ${vcs-fhs-env}/bin/vcs-fhs-env
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib
    cp ${binName} $out/lib
    cp -r ${binName}.daidir $out/lib

    ${lib.optionalString enableCover ''cp -r ${coverageName} $out/lib''} \

    substitute ${./scripts/vcs-wrapper.sh} $out/bin/${binName} \
      --subst-var-by lib "$out/lib" \
      --subst-var-by shell "${bash}/bin/bash" \
      --subst-var-by dateBin "$(command -v date)" \
      --subst-var-by vcsSimBin "$out/lib/${binName}" \
      --subst-var-by vcsSimDaidir "$out/lib/${binName}.daidir" \
      --subst-var-by vcsCovDir "${lib.optionalString enableCover "${coverageName}"}" \
      --subst-var-by vcsFhsEnv "${vcs-fhs-env}/bin/vcs-fhs-env"
    chmod +x $out/bin/${binName}

    runHook postInstall
  '';
})
