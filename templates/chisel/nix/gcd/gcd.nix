# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

{
  lib,
  stdenv,
  makeWrapper,
  writeShellApplication,
  coreutils,
  jdk21,
  git,

  # chisel deps
  mill,
  espresso,
  mlir-install,
  circt-install,
  jextract-21,
  add-determinism,

  dependencies,
  mif,
  mkMavenRepository,

  target,
}:

let
  gcdMavenRepository = mkMavenRepository {
    lockFile = ../dependencies/locks/gcd-lock.json;
    name = "gcd-maven-repository";
  };

  archiveMill = writeShellApplication {
    name = "mill";
    runtimeInputs = [ mill ];
    text = ''
      ivyHome="$PWD/.ivy2"
      export JAVA_TOOL_OPTIONS="''${JAVA_TOOL_OPTIONS:-} -Dcoursier.ivy.home=$ivyHome -Divy.home=$ivyHome"
      exec mill "$@"
    '';
  };

  self = stdenv.mkDerivation rec {
    name = "gcd";

    mainClass = "org.chipsalliance.gcd.elaborator.${target}Main";

    src =
      with lib.fileset;
      toSource {
        root = ./../..;
        fileset = unions [
          ./../../build.mill
          ./../../common.mill
          ./../../gcd
          ./../../elaborator
        ];
      };

    buildInputs = [ gcdMavenRepository ];

    nativeBuildInputs = with dependencies; [
      makeWrapper

      mill
      circt-install
      jextract-21
      add-determinism
      espresso
      git
    ];

    passthru = {
      bump = writeShellApplication {
        name = "bump-gcd-mill-lock";
        runtimeInputs = [
          coreutils
          mill
          mif
        ];
        text = ''
          workdir="$(mktemp -d)"
          cleanup() {
            rm -rf "$workdir"
          }
          trap cleanup EXIT

          cp -R --no-preserve=mode,ownership "${src}/." "$workdir/"
          mkdir -p "$workdir/.ivy2"
          cp -R --no-preserve=mode,ownership "${dependencies.ivyLocalRepo}/." "$workdir/.ivy2/"
          ln -s "${archiveMill}/bin/mill" "$workdir/mill"

          mif archive \
            -p "$workdir" \
            --lock ./nix/dependencies/locks/gcd-lock.json \
            --fresh \
            -- ./mill -i __.prepareOffline

          rm -rf "$workdir/out"

          mif archive \
            -p "$workdir" \
            --lock ./nix/dependencies/locks/gcd-lock.json \
            -- ./mill -i __.scalaCompilerClasspath
        '';
      };
      inherit target;
      inherit env;
      inherit gcdMavenRepository;
    };

    shellHook = ''
      mill -i mill.bsp.BSP/install
    '';

    env = {
      CIRCT_INSTALL_PATH = circt-install;
      MLIR_INSTALL_PATH = mlir-install;
      JEXTRACT_INSTALL_PATH = jextract-21;
      JAVA_TOOL_OPTIONS = "-Dcoursier.ivy.home=${dependencies.ivyLocalRepo} -Divy.home=${dependencies.ivyLocalRepo}";
      COURSIER_REPOSITORIES = "ivy2Local|file://${gcdMavenRepository}";
    };

    outputs = [
      "out"
      "elaborator"
    ];

    meta.mainProgram = "elaborator";

    buildPhase = ''
      mill -i '__.assembly'
    '';

    installPhase = ''
      mkdir -p $out/share/java

      add-determinism -j $NIX_BUILD_CORES out/elaborator/assembly.dest/out.jar

      mv out/elaborator/assembly.dest/out.jar $out/share/java/elaborator.jar

      mkdir -p $elaborator/bin
      makeWrapper ${jdk21}/bin/java $elaborator/bin/elaborator \
        --add-flags "--enable-preview -Djava.library.path=${mlir-install}/lib:${circt-install}/lib -cp $out/share/java/elaborator.jar ${mainClass}"
    '';
  };
in
self
