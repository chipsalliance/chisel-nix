{
  description = "Chisel Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    chisel-nix.url = "github:chipsalliance/chisel-nix";
    zaozi.url = "github:sequencer/zaozi";
    mill-ivy-fetcher.url = "github:Avimitin/mill-ivy-fetcher";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      chisel-nix,
      zaozi,
      mill-ivy-fetcher,
      treefmt-nix,
    }:
    let
      overlay = import ./nix/overlay.nix;
    in
    {
      # System-independent attr
      inherit inputs;
      overlays.default = overlay;
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          # TODO: Do not depend on overlay of zaozi in favor of importing its outputs explicitly to avoid namespace pollution.
          overlays = [
            zaozi.overlays.default
            mill-ivy-fetcher.overlays.default
            (final: prev: { mill-ivy-fetcher = mill-ivy-fetcher.packages.${system}.default; })
            overlay
          ];
          inherit system;
        };

        treefmtEval = treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.scalafmt = {
            enable = true;
            includes = [ "*.mill" ];
          };
          programs.nixfmt.enable = true;
          programs.rustfmt.enable = true;
        };
      in
      with pkgs;
      {
        formatter = treefmtEval.config.build.wrapper;
        legacyPackages = pkgs;
        devShells.default = mkShell (
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
      }
    );
}
