{ stdenvNoCC
, mill
, writeText
, makeSetupHook
, runCommand
, lib
, lndir
, configure-mill-home-hook
, add-determinism
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

      # It is hard to handle shell escape for bracket, let's just codegen build script
      buildPhase = lib.concatStringsSep "\n" (
        [ "runHook preBuild" ]
        ++ (map (target: "mill -i '${target}'.publishLocal") publishTargets)
        ++ [ "runHook postBuild" ]
      );

      installPhase = ''
        runHook preInstall

        mkdir -p $out/.ivy2
        mv $NIX_MILL_HOME/.ivy2/local $out/.ivy2/

        runHook postInstall
      '';

      fixupPhase = ''
        runHook preFixup

        # Fix reproducibility

        # https://github.com/chipsalliance/chisel/issues/4666
        find $out/.ivy2/local -wholename '*/docs/*.jar' -type f -delete

        # Align datetime
        export SOURCE_DATE_EPOCH=1669810380
        find $out/.ivy2/local -type f -name '*.jar' -exec '${add-determinism}/bin/add-determinism' -j "$NIX_BUILD_CORES" '{}' ';'

        runHook postFixup
      '';

      dontShrink = true;
      dontPatchELF = true;

      passthru.setupHook = makeSetupHook
        {
          name = "mill-local-ivy-setup-hook.sh";
          propagatedBuildInputs = [ mill configure-mill-home-hook ];
        }
        (writeText "mill-setup-hook" ''
          setup${name}IvyLocalRepo() {
            mkdir -p "$NIX_MILL_HOME/.ivy2/local"
            ${lndir}/bin/lndir "${self}/.ivy2/local" "$NIX_MILL_HOME/.ivy2/local"

            echo "Copy ivy repo to $NIX_MILL_HOME"
          }

          postUnpackHooks+=(setup${name}IvyLocalRepo)
        '');
    }
    (builtins.removeAttrs args [ "name" "src" "publishTargets" "nativeBuildInputs" ]));
in
self
