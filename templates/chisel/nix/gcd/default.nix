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
  tb-dpi-lib-trace = scope.tb-dpi-lib.override { enable-trace = true; };

  verilated = scope.callPackage ./verilated.nix { rtl = scope.tb-rtl; };
  verilated-trace =
    scope.verilated.override { tb-dpi-lib = scope.tb-dpi-lib-trace; };
  vcs = scope.callPackage ./vcs.nix { };

  # TODO: designConfig should be read from OM
  tbConfig = with builtins;
    fromJSON (readFile ./../../configs/${scope.tb-target}.json);

})

