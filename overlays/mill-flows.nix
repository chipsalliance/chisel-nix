final: prev:
{
  configure-mill-home-hook = final.callPackage ./mill-flow/configure-mill-home.nix { };
  fetchMillDeps = final.callPackage ./mill-flow/fetch-mill-deps.nix { inherit (final.xorg) lndir; };
  publishMillJar = final.callPackage ./mill-flow/publish-mill-jar.nix { inherit (final.xorg) lndir; };
}
