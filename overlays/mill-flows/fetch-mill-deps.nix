{ stdenvNoCC
, mill
, writeText
, makeSetupHook
, runCommand
, lib
, configure-mill-home-hook
, lndir
}:

{ name
, src
, millDepsHash
, ...
}@args:

let
  buildAttr = {
    name = "${name}-mill-deps";
    inherit src;

    propagatedBuildInputs = [
      mill
      configure-mill-home-hook
      lndir
    ] ++ (args.propagatedBuildInputs or [ ]);

    impureEnvVars = [ "JAVA_OPTS" ];

    buildPhase = ''
      runHook preBuild

      # Use "https://repo1.maven.org/maven2/" only to keep dependencies integrity
      export COURSIER_REPOSITORIES="ivy2local|central"

      mill -i __.prepareOffline
      mill -i __.scalaCompilerClasspath

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/.cache
      mv "$NIX_MILL_HOME"/.cache/coursier $out/.cache/coursier

      mkdir -p $out/nix-support
      cp ${./setup-mill-deps.sh} $out/nix-support/setup-hook
      recordPropagatedDependencies

      runHook postInstall
    '';

    postFixup = ''
      cat "$out"/nix-support/setup-hook
      cat "$out"/nix-support/propagated-build-inputs
    '';

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = millDepsHash;

    dontShrink = true;
    dontPatchELF = true;
  };
in
stdenvNoCC.mkDerivation
  (lib.recursiveUpdate buildAttr
    (builtins.removeAttrs args [ "name" "src" "millDepsHash" "propagatedBuildInputs" ]))
