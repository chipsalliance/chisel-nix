# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

let
  getEnv' = key:
    let
      val = builtins.getEnv key;
    in
    if val == "" then
      builtins.throw "${key} not set or '--impure' not applied"
    else val;
in
final: prev: {
  espresso = final.callPackage ./pkgs/espresso.nix { };

  mill =
    let jre = final.jdk21;
    in (prev.mill.override { inherit jre; }).overrideAttrs
      (_: { passthru = { inherit jre; }; });

  fetchMillDeps = final.callPackage ./pkgs/mill-builder.nix { };

  circt-full = final.callPackage ./pkgs/circt-full.nix { };

  # faster strip-undetereminism
  add-determinism = final.callPackage ./pkgs/add-determinism { };

  vcs-fhs-env = final.callPackage ./pkgs/vcs-fhs-env.nix { inherit getEnv'; };

  cds-fhs-env = final.callPackage ./pkgs/cds-fhs-env.nix { inherit getEnv'; };

  projectDependencies = final.callPackage ./pkgs/project-dependencies.nix { };

  gcd = final.callPackage ./gcd { };
}
