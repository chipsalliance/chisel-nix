# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

{ lib
, stdenv
, fetchMillDeps
, makeWrapper
, jdk21
, git

  # chisel deps
, mill-dependencies
, mill
, espresso
, circt-full
, jextract-21
, add-determinism

, target
}:

let
  self = stdenv.mkDerivation rec {
    name = "gcd";

    mainClass = "org.chipsalliance.gcd.elaborator.${target}Main";

    src = with lib.fileset;
      toSource {
        root = ./../..;
        fileset = unions [
          ./../../build.mill
          ./../../common.mill
          ./../../gcd
          ./../../elaborator
        ];
      };

    passthru = {
      millDeps = fetchMillDeps {
        inherit name;
        src = with lib.fileset;
          toSource {
            root = ./../..;
            fileset = unions [ ./../../build.mill ./../../common.mill ];
          };
        buildInputs = with mill-dependencies; [ chisel.setupHook ];
        millDepsHash = "sha256-NybS2AXRQtXkgHd5nH4Ltq3sxZr5aZ4VepiT79o1AWo=";
      };

      inherit target;
      inherit env;
    };

    nativeBuildInputs = with mill-dependencies; [
      makeWrapper

      mill
      circt-full
      jextract-21
      add-determinism
      espresso
      git

      passthru.millDeps.setupHook
      chisel.setupHook
    ];

    env = {
      CIRCT_INSTALL_PATH = circt-full;
      JEXTRACT_INSTALL_PATH = jextract-21;
    };

    outputs = [ "out" "elaborator" ];

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
        --add-flags "--enable-preview -Djava.library.path=${circt-full}/lib -cp $out/share/java/elaborator.jar ${mainClass}"
    '';
  };
in
self
