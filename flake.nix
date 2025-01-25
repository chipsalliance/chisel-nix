{
  description = "Chisel Flakes";

  outputs = { self }: {
    templates = import ./templates;
    overlays.mill-flows = import ./overlays/mill-flows.nix;
  };
}
