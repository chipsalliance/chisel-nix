{ pkgs
, lib
, newScope
, generateIvyCache
, publishMillJar
, git
, ...
}:
let
  dependencies = pkgs.callPackage ./_sources/generated.nix { };
in
lib.makeScope newScope (scope: {
  chisel =
    let
      chiselDeps = generateIvyCache {
        name = "chisel";
        src = dependencies.chisel.src;
        targets = [ "unipublish" ];
        extraBuildInputs = [
          git
        ];
        hash = "sha256-2hagdxe1JBoNAdkY2QhzU/IVHkxBQ+16ENpPALJ7Gg0=";
      };
    in
    publishMillJar {
      name = "chisel-snapshot";
      src = dependencies.chisel.src;
      publishTargets = [ "unipublish" ];
      buildInputs = chiselDeps.cache.ivyDepsList;
      nativeBuildInputs = [
        git
      ];
      passthru = {
        inherit chiselDeps;
      };
    };
})
