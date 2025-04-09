# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

let
  getEnv' =
    key:
    let
      val = builtins.getEnv key;
    in
    if val == "" then builtins.throw "${key} not set or '--impure' not applied" else val;
in
final: prev: {
  espresso = final.callPackage ./pkgs/espresso.nix { };

  mill =
    let
      jre = final.jdk21;
    in
    (prev.mill.override { inherit jre; }).overrideAttrs rec {
      version = "0.12.10";
      src = final.fetchurl {
        url = "https://repo1.maven.org/maven2/com/lihaoyi/mill-dist/${version}/mill-dist-${version}-assembly.jar";
        hash = "sha256-TESwISFz4Xf/F4kgnaTQbi/uVrc75bearih8mydPqHM=";
      };
      passthru = { inherit jre; };
    };

  vcs-fhs-env = final.callPackage ./pkgs/vcs-fhs-env.nix { inherit getEnv'; };

  cds-fhs-env = final.callPackage ./pkgs/cds-fhs-env.nix { inherit getEnv'; };

  gcd = final.callPackage ./gcd { };
}
