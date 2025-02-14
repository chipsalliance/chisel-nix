final: prev:
{
  configure-mill-home-hook = final.callPackage ./mill-flows/configure-mill-home.nix { };
  publishMillJar = final.callPackage ./mill-flows/publish-mill-jar.nix { inherit (final.xorg) lndir; };
  mill-ivy-builder =
    let
      src = final.fetchFromGitHub {
        owner = "Avimitin";
        repo = "mill-ivy-builder";
        rev = "e8451bd89494e6c5d23be52e39b515f4dec29edc";
        hash = "";
      };
    in
    {
      generator = final.callPackage "${src}/package.nix" { };
      dep-builder = final.callPackage "${src}/dep-builder.nix" { };
    };
}
