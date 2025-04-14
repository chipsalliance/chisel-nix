{
  description = "Chisel Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zaozi.url = "github:sequencer/zaozi";
    mill-ivy-fetcher.url = "github:Avimitin/mill-ivy-fetcher";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    let
      overlay = import ./nix/overlay.nix;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      flake.overlays.default = overlay;

      perSystem =
        { system, pkgs, ... }:
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            # TODO: Do not depend on overlay of zaozi in favor of importing its outputs explicitly to avoid namespace pollution.
            overlays = with inputs; [
              zaozi.overlays.default
              mill-ivy-fetcher.overlays.default
              overlay
            ];
          };

          legacyPackages = pkgs;

          treefmt = {
            projectRootFile = "flake.nix";
            programs.scalafmt = {
              enable = true;
              includes = [ "*.mill" ];
            };
            programs.nixfmt = {
              enable = true;
              excludes = [ "*/generated.nix" ];
            };
            programs.rustfmt.enable = true;
          };

          devShells.default =
            with pkgs;
            mkShell (
              {
                inputsFrom = [ gcd.gcd-compiled ];
                packages = [
                  cargo
                  rust-analyzer
                  nixd
                  nvfetcher
                ];
                RUST_SRC_PATH = "${rust.packages.stable.rustPlatform.rustLibSrc}";
              }
              // gcd.tb-dpi-lib.env
              // gcd.gcd-compiled.env
            );
        };
    };
}
