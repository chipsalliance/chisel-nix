{ lib
, newScope
,
}:
lib.makeScope newScope (scope: {
  elaborator = scope.callPackage ./elaborator.nix { };
  elaborate = scope.callPackage ./elaborate.nix { };
  mlirbc = scope.callPackage ./mlirbc.nix { };
  rtl = scope.callPackage ./rtl.nix { };

  verilated-c-lib = scope.callPackage ./verilated-c-lib.nix { };
  vcs = scope.callPackage ./vcs.nix { };
})

