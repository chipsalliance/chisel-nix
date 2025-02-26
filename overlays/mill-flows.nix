final: prev:
{
  configure-mill-env-hook = final.callPackage ./mill-flows/configure-mill-env.nix { };
  fetchMillDeps = final.callPackage ./mill-flows/fetch-mill-deps.nix { inherit (final.xorg) lndir; };
  publishMillJar = final.callPackage ./mill-flows/publish-mill-jar.nix { inherit (final.xorg) lndir; };
}
