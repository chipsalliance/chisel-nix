{ stdenvNoCC
, mill
, writeText
, makeSetupHook
, runCommand
, lib
, lndir
, configure-mill-home-hook
}:

{ name, src, publishTargets, ... }@args:

let
  buildAttr = {
    name = "${name}-mill-local-ivy";
    inherit src;

    propagatedBuildInputs = [
      mill
      configure-mill-home-hook
      lndir
    ] ++ (args.propagatedBuildInputs or [ ]);

    publishTargets = lib.escapeShellArgs publishTargets;

    buildPhase = ''
      runHook preBuild

      publishTargetsArray=( "$publishTargets" )
      for target in "''${publishTargetsArray[@]}"; do
        mill -i "$target.publishLocal"
      done

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/.ivy2
      mv $NIX_MILL_HOME/.ivy2/local $out/.ivy2/

      mkdir -p "$out"/nix-support
      cp ${./install-ivy-repo.sh} "$out"/nix-support/setup-hook
      recordPropagatedDependencies

      runHook postInstall
    '';

    dontShrink = true;
    dontPatchELF = true;
  };
in
stdenvNoCC.mkDerivation
  (lib.recursiveUpdate buildAttr
    (builtins.removeAttrs args [ "name" "src" "propagatedBuildInputs" ]))
