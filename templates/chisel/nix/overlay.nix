final: prev:
{
  espresso = final.callPackage ./pkgs/espresso.nix { };
  mill = let jre = final.jdk21; in
    (prev.mill.override { inherit jre; }).overrideAttrs (_: {
      passthru = { inherit jre; };
    });
  fetchMillDeps = final.callPackage ./pkgs/mill-builder.nix { };
  circt-full = final.callPackage ./pkgs/circt-full.nix { };
  add-determinism = final.callPackage ./pkgs/add-determinism { }; # faster strip-undetereminism

  riscv-tests = final.callPackage ./pkgs/riscv-tests.nix {
    stdenv = final.pkgsCross.riscv32-embedded.stdenv;

    # Uncomment and replace this to other env
    # riscv-test-env = ./path/to/riscv-test-env;
  };

  nvfetcherSource = final.callPackage ./pkgs/nvfetcher-source.nix { };
}
