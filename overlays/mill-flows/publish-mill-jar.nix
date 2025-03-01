{ stdenvNoCC
, mill
, writeText
, makeSetupHook
, runCommand
, lib
, lndir
, configure-mill-env-hook
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
        configure-mill-env-hook
      ] ++ (args.nativeBuildInputs or [ ]);

      # It is hard to handle shell escape for bracket, let's just codegen build script
      buildPhase = lib.concatStringsSep "\n" (
        [ "runHook preBuild" ]
        ++ (map (target: "mill -i '${target}'.publishLocal") publishTargets)
        ++ [ "runHook postBuild" ]
      );

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        mv $NIX_COURSIER_DIR/local $out/

        runHook postInstall
      '';

      fixupPhase = ''
        runHook preFixup

        # Fix reproducibility

        # https://github.com/chipsalliance/chisel/issues/4666
        find $out/local -wholename '*/docs/*.jar' -type f -delete

        # Align datetime
        export SOURCE_DATE_EPOCH=1669810380
        find $out/local -type f -name '*.jar' -exec '${add-determinism}/bin/add-determinism' -j "$NIX_BUILD_CORES" '{}' ';'

        runHook postFixup
      '';

      dontShrink = true;
      dontPatchELF = true;

      passthru.setupHook = makeSetupHook
        {
          name = "mill-local-ivy-setup-hook.sh";
          propagatedBuildInputs = [ mill configure-mill-env-hook ];
        }
        (writeText "mill-setup-hook" ''
          setup${name}IvyLocalRepo() {
            mkdir -p "$NIX_COURSIER_DIR/local"
            ${lndir}/bin/lndir "${self}/local" "$NIX_COURSIER_DIR/local"

            echo "Copy ivy repo to $NIX_COURSIER_DIR"
          }

          postUnpackHooks+=(setup${name}IvyLocalRepo)
        '');
    }
    (builtins.removeAttrs args [ "name" "src" "publishTargets" "nativeBuildInputs" ]));
in
self
