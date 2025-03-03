{
  description = "Chisel Flakes";

  inputs = {
    mill-ivy-fetcher.url = "github:Avimitin/mill-ivy-fetcher";
  };

  outputs = { self, mill-ivy-fetcher }: {
    templates = import ./templates;
    overlays.mill-flows = final: prev:
      let
        overlays = [
          (import ./overlays/mill-flows.nix)
          (import mill-ivy-fetcher.overlays.default)
        ];
      in
      prev.lib.foldl
        (finalOverlay: overlayFn:
          prev.lib.recursiveUpdate (overlayFn final prev) finalOverlay)
        { } # fold init
        overlays;
  };
}
