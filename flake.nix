{
  description = "Chisel Flakes";

  inputs = {
    mill-ivy-fetcher.url = "github:Avimitin/mill-ivy-fetcher";
  };

  outputs = { self, mill-ivy-fetcher }@inputs: {
    templates = import ./templates;
    overlays.mill-flows = mill-ivy-fetcher.overlays.default;
    inherit inputs;
  };
}
