# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

final: prev: {
  espresso = final.callPackage ./pkgs/espresso.nix { };
  mill = let jre = final.jdk21;
  in (prev.mill.override { inherit jre; }).overrideAttrs
  (_: { passthru = { inherit jre; }; });
  fetchMillDeps = final.callPackage ./pkgs/mill-builder.nix { };
  circt-full = final.callPackage ./pkgs/circt-full.nix { };
  add-determinism =
    final.callPackage ./pkgs/add-determinism { }; # faster strip-undetereminism

  # Using VCS need to set VC_STATIC_HOME and SNPSLMD_LICENSE_FILE to impure env, and add sandbox dir to VC_STATIC_HOME
  # Remember to add "--impure" flag for nix to read this value from environment
  vcStaticHome = builtins.getEnv "VC_STATIC_HOME";
  snpslmdLicenseFile = builtins.getEnv "SNPSLMD_LICENSE_FILE";
  vcs-fhs-env = assert final.lib.assertMsg (final.vcStaticHome != "")
    "You forget to set VC_STATIC_HOME or the '--impure' flag";
    assert final.lib.assertMsg (final.snpslmdLicenseFile != "")
      "You forget to set SNPSLMD_LICENSE_FILE or the '--impure' flag";
    final.callPackage ./pkgs/vcs-fhs-env.nix { };

  projectDependencies = final.callPackage ./pkgs/project-dependencies.nix { };

  gcd = final.callPackage ./gcd { };
}
