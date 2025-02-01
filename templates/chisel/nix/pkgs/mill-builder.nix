# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

{ stdenvNoCC, mill, rsync, writeText, makeSetupHook, lib }:

{ name, src, millDepModules, millDepsHash, ... }@args:

let
  mill-rt-version = lib.head (lib.splitString "+" mill.jre.version);
  cachePrefix = if stdenvNoCC.hostPlatform.isDarwin then "Library/Caches/Coursier" else ".cache/coursier";
  self = stdenvNoCC.mkDerivation ({
    name = "${name}-mill-deps";
    inherit src;

    nativeBuildInputs = [
      mill
      rsync
    ]
    ++ millDepModules
    ++ (args.nativeBuildInputs or [ ]);

    impureEnvVars = [ "JAVA_OPTS" ];

    buildPhase = ''
      runHook preBuild
      echo "-Duser.home=$TMPDIR $JAVA_OPTS" | tr ' ' '\n' > mill-java-opts
      export MILL_JVM_OPTS_PATH=$PWD/mill-java-opts
      
      mkdir -p $TMPDIR/.ivy2
       ${ lib.concatStringsSep "\n"
       (map (module: "rsync -a --chmod=D775,F664 ${module}/.ivy2/local/ $TMPDIR/.ivy2/local/") millDepModules)}

      # Use "https://repo1.maven.org/maven2/" only to keep dependencies integrity
      export COURSIER_REPOSITORIES="ivy2Local|central"

      mill -i __.prepareOffline
      mill -i __.scalaCompilerClasspath
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/.cache $out/.ivy2

      mv $TMPDIR/${cachePrefix} $out/.cache/coursier
      mv $TMPDIR/.ivy2/local $out/.ivy2/local
      runHook postInstall
    '';

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = millDepsHash;

    dontShrink = true;
    dontPatchELF = true;

    passthru.setupHook = makeSetupHook
      {
        name = "mill-setup-hook.sh";
        propagatedBuildInputs = [ mill ];
      }
      (writeText "mill-setup-hook" ''
        setupMillCache() {
          local tmpdir=$(mktemp -d)
          echo "$JAVA_OPTS -Duser.home=$tmpdir" | tr ' ' '\n' > mill-java-opts
          export MILL_JVM_OPTS_PATH=$PWD/mill-java-opts

          mkdir -p "$tmpdir"/.cache "$tmpdir"/.ivy2 "$tmpdir/.mill/ammonite"

          cp -r "${self}"/.cache/coursier "$tmpdir"/.cache/
          cp -r "${self}"/.ivy2/local "$tmpdir"/.ivy2/
          
          touch "$tmpdir/.mill/ammonite/rt-${mill-rt-version}.jar"

          echo "JAVA HOME dir set to $tmpdir"
        }

        postUnpackHooks+=(setupMillCache)
      '');
  } // (builtins.removeAttrs args [ "name" "src" "millDepsHash" "nativeBuildInputs" ]));
in
self
