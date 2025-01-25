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
  self = stdenvNoCC.mkDerivation (lib.recursiveUpdate
    {
      name = "${name}-mill-local-ivy";
      inherit src;

      nativeBuildInputs = [
        mill
        configure-mill-home-hook
      ] ++ (args.nativeBuildInputs or [ ]);

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

        runHook postInstall
      '';

      dontShrink = true;
      dontPatchELF = true;

      passthru.setupHook = makeSetupHook
        {
          name = "mill-local-ivy-setup-hook.sh";
          propagatedBuildInputs = [ mill configure-mill-home-hook ];
        }
        (writeText "mill-setup-hook" ''
          setupIvyLocalRepo() {
            mkdir -p "$NIX_MILL_HOME/.ivy2/local"
            ${lndir}/bin/lndir "${self}/.ivy2/local" "$NIX_MILL_HOME/.ivy2/local"

            echo "Copy ivy repo to $NIX_MILL_HOME"
          }

          postUnpackHooks+=(setupIvyLocalRepo)
        '');
    }
    (builtins.removeAttrs args [ "name" "src" "nativeBuildInputs" ]));
in
self
