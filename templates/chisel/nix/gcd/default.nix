# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

{ lib, newScope, }:
lib.makeScope newScope (scope: {
  design-target = "GCD";
  tb-target = "GCDTestBench";

  # RTL
  gcd-compiled = scope.callPackage ./gcd.nix { target = scope.design-target; };
  elaborate = scope.callPackage ./elaborate.nix {
    elaborator = scope.gcd-compiled.elaborator;
  };
  mlirbc = scope.callPackage ./mlirbc.nix { };
  rtl = scope.callPackage ./rtl.nix { };

  # Testbench
  tb-compiled = scope.callPackage ./gcd.nix { target = scope.tb-target; };
  tb-elaborate = scope.callPackage ./elaborate.nix {
    elaborator = scope.tb-compiled.elaborator;
  };
  tb-mlirbc =
    scope.callPackage ./mlirbc.nix { elaborate = scope.tb-elaborate; };
  tb-rtl = scope.callPackage ./rtl.nix { mlirbc = scope.tb-mlirbc; };
  tb-dpi-lib = scope.callPackage ./dpi-lib.nix { };

  verilated = scope.callPackage ./verilated.nix {
    rtl = scope.tb-rtl.override { enable-layers = [ "Verification" ]; };
    dpi-lib = scope.tb-dpi-lib;
  };
  verilated-trace = scope.verilated.override {
    dpi-lib = scope.verilated.dpi-lib.override { enable-trace = true; };
  };
  vcs = scope.callPackage ./vcs.nix {
    dpi-lib = scope.tb-dpi-lib.override {
      sv2023 = false;
      vpi = true;
    };
    rtl = scope.tb-rtl.override {
      enable-layers =
        [ "Verification" "Verification.Assert" "Verification.Cover" ];
    };
  };
  vcs-trace = scope.vcs.override {
    dpi-lib = scope.vcs.dpi-lib.override {
      enable-trace = true;
      timescale = 1000;
    };
  };

  # TODO: designConfig should be read from OM
  tbConfig = with builtins;
    fromJSON (readFile ./../../configs/${scope.tb-target}.json);

})

