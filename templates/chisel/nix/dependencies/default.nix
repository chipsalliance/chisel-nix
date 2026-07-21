{
  lib,
  callPackage,
  newScope,
  stdenvNoCC,
  symlinkJoin,
  writeShellApplication,
  addDeterminismHook,
  coreutils,
  git,
  mill,
  mif,
  mkMavenRepository,
  mlir-install,
  circt-install,
  jextract-21,
  ...
}:
let
  dependencies = callPackage ./_sources/generated.nix { };

  publishLocalIvy =
    {
      name,
      src,
      lockFile,
      publishTargets,
      nativeBuildInputs ? [ ],
      env ? { },
      passthru ? { },
    }:
    let
      mavenRepository = mkMavenRepository {
        inherit lockFile;
        name = "${name}-maven-repository";
      };
    in
    stdenvNoCC.mkDerivation {
      name = "${name}-mill-local-ivy";

      inherit src env;

      buildInputs = [ mavenRepository ];

      nativeBuildInputs = [
        addDeterminismHook
        mill
      ] ++ nativeBuildInputs;

      buildPhase = ''
        runHook preBuild

        localIvyHome="$NIX_BUILD_TOP/local-ivy-home"
        export JAVA_TOOL_OPTIONS="''${JAVA_TOOL_OPTIONS:-} -Dcoursier.ivy.home=$localIvyHome -Divy.home=$localIvyHome"

        ${lib.concatMapStringsSep "\n" (target: "mill -i '${target}.publishLocal'") publishTargets}

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p "$out"
        mv "$NIX_BUILD_TOP/local-ivy-home/local" "$out/local"

        runHook postInstall
      '';

      fixupPhase = ''
        runHook preFixup

        # Chisel's generated Scaladoc JARs are not reproducible yet.
        # https://github.com/chipsalliance/chisel/issues/4666
        find "$out/local" -wholename '*/docs/*.jar' -type f -delete

        runHook postFixup
      '';

      dontPatchELF = true;
      dontShrink = true;

      passthru = {
        inherit mavenRepository;
      } // passthru;
    };
in
lib.makeScope newScope (scope: {
  ivy-chisel = publishLocalIvy {
    name = "chisel-snapshot";
    src = dependencies.chisel.src;

    lockFile = ./locks/chisel-lock.json;

    publishTargets = [
      "unipublish"
    ];

    nativeBuildInputs = [
      # chisel requires git to generate version
      git
    ];

    passthru.bump = writeShellApplication {
      name = "bump-chisel-mill-lock";

      runtimeInputs = [
        coreutils
        git
        mill
        mif
      ];

      text = ''
        workdir="$(mktemp -d)"
        cleanup() {
          rm -rf "$workdir"
        }
        trap cleanup EXIT

        cp -R --no-preserve=mode,ownership "${dependencies.chisel.src}/." "$workdir/"

        mif archive \
          -p "$workdir" \
          --lock ./nix/dependencies/locks/chisel-lock.json \
          --fresh \
          -- mill -i __.prepareOffline

        rm -rf "$workdir/out"

        mif archive \
          -p "$workdir" \
          --lock ./nix/dependencies/locks/chisel-lock.json \
          -- mill -i __.scalaCompilerClasspath

        rm -rf "$workdir/out"

        mif archive \
          -p "$workdir" \
          --lock ./nix/dependencies/locks/chisel-lock.json \
          -- mill -i __.scalaDocClasspath
      '';
    };
  };

  ivy-omlib = publishLocalIvy {
    name = "omlib-snapshot";
    src = dependencies.zaozi.src;

    publishTargets = [
      "mlirlib"
      "circtlib"
      "omlib"
    ];

    env = {
      CIRCT_INSTALL_PATH = circt-install;
      MLIR_INSTALL_PATH = mlir-install;
      JEXTRACT_INSTALL_PATH = jextract-21;
    };

    lockFile = ./locks/zaozi-lock.json;

    passthru.bump = writeShellApplication {
      name = "bump-zaozi-mill-lock";

      runtimeInputs = [
        coreutils
        git
        mill
        mif
      ];

      text = ''
        workdir="$(mktemp -d)"
        cleanup() {
          rm -rf "$workdir"
        }
        trap cleanup EXIT

        cp -R --no-preserve=mode,ownership "${dependencies.zaozi.src}/." "$workdir/"

        mif archive \
          -p "$workdir" \
          --lock ./nix/dependencies/locks/zaozi-lock.json \
          --fresh \
          -- mill -i __.prepareOffline

        rm -rf "$workdir/out"

        mif archive \
          -p "$workdir" \
          --lock ./nix/dependencies/locks/zaozi-lock.json \
          -- mill -i __.scalaCompilerClasspath

        rm -rf "$workdir/out"

        mif archive \
          -p "$workdir" \
          --lock ./nix/dependencies/locks/zaozi-lock.json \
          -- mill -i __.scalaDocClasspath
      '';
    };

    nativeBuildInputs = [ git ];
  };

  ivyLocalRepo = symlinkJoin {
    name = "chisel-local-ivy-repository";
    paths = with scope; [
      ivy-chisel
      ivy-omlib
    ];
  };
})
