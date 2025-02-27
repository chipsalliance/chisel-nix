{ pkgs
, lib
, newScope
, fetchMillDeps
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
      chiselDeps = fetchMillDeps {
        name = "chisel";
        src = dependencies.chisel.src;
        fetchTargets = [ "unipublish" ];
        nativeBuildInputs = [
          git
        ];
        millDepsHash = "sha256-TmjZTFDXkWkQJTj4U9zZW6VxcJWNyHBuKL8op/2u/LI=";
      };
    in
    publishMillJar {
      name = "chisel";
      src = dependencies.chisel.src;
      publishTargets = [ "unipublish" ];
      buildInputs = [ chiselDeps.setupHook ];
      nativeBuildInputs = [
        git
      ];
      passthru = {
        inherit chiselDeps;
      };
    };
})
