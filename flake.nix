{
  description = "Chisel Flakes";

  outputs = { self }: {
    templates = import ./templates;
  };
}
