{
  lib,
  callPackage,
  newScope,
  writeShellApplication,
  runCommand,
  publishMillJar,
  git,
  mill,
  mill-ivy-fetcher,
  mlir-install,
  circt-install,
  jextract-21,
  ...
}:
let
  dependencies = callPackage ./_sources/generated.nix { };
in
lib.makeScope newScope (scope: {
  ivy-chisel = publishMillJar {
    name = "chisel-snapshot";
    src = dependencies.chisel.src;

    lockFile = ./locks/chisel-lock.nix;

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
        mill
        mill-ivy-fetcher
      ];

      text = ''
        mif run -p "${dependencies.chisel.src}" -o ./nix/dependencies/locks/chisel-lock.nix "$@"
      '';
    };
  };

  ivy-omlib = publishMillJar {
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

    lockFile = ./locks/zaozi-lock.nix;

    passthru.bump = writeShellApplication {
      name = "bump-zaozi-mill-lock";

      runtimeInputs = [
        mill
        mill-ivy-fetcher
      ];

      text = ''
        mif run -p "${dependencies.zaozi.src}" -o ./nix/dependencies/locks/zaozi-lock.nix "$@"
      '';
    };

    nativeBuildInputs = [ git ];
  };

  ivyLocalRepo =
    runCommand "build-coursier-env"
      {
        buildInputs = with scope; [
          ivy-chisel.setupHook
          ivy-omlib.setupHook
        ];
      }
      ''
        runHook preUnpack
        runHook postUnpack
        cp -r "$NIX_COURSIER_DIR" "$out"
      '';
})
