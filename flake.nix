{
  description = "Chisel Flakes";

  inputs = {
    mill-ivy-fetcher = "github:Avimitin/mill-ivy-fetcher";
  };

  outputs = { self, mill-ivy-fetcher }: {
    templates = import ./templates;
    overlays.mill-flows = mill-ivy-fetcher.default;
  };
}
