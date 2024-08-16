{ lib
, newScope
,
}:
lib.makeScope newScope (scope: {
  gcd-compiled = scope.callPackage ./gcd.nix { };
  inherit (scope.gcd-compiled) elaborator;

  elaborate = scope.callPackage ./elaborate.nix { };
  mlirbc = scope.callPackage ./mlirbc.nix { };
  rtl = scope.callPackage ./rtl.nix { };

  verilated-c-lib = scope.callPackage ./verilated-c-lib.nix { };
  vcs = scope.callPackage ./vcs.nix { };
})

