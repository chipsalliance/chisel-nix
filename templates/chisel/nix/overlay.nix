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

  mill-dependencies = final.callPackage ./pkgs/dependencies { };

  circt-full = final.callPackage ./pkgs/circt-full.nix { };

  vcs-fhs-env = final.callPackage ./pkgs/vcs-fhs-env.nix { inherit getEnv'; };

  cds-fhs-env = final.callPackage ./pkgs/cds-fhs-env.nix { inherit getEnv'; };

  gcd = final.callPackage ./gcd { };
}
