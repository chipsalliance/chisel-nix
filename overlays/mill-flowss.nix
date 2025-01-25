final: prev:
{
  configure-mill-home-hook = final.callPackage ./mill-flows/configure-mill-home.nix { };
  fetchMillDeps = final.callPackage ./mill-flows/fetch-mill-deps.nix { inherit (final.xorg) lndir; };
  publishMillJar = final.callPackage ./mill-flows/publish-mill-jar.nix { inherit (final.xorg) lndir; };
}
