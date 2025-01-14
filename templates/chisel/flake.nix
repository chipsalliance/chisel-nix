# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>
{
  description = "Chisel Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils }:
    let overlay = import ./nix/overlay.nix;
    in {
      # System-independent attr
      inherit inputs;
      overlays.default = overlay;
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          overlays = [ overlay ];
          inherit system;
        };
      in
      with pkgs;
      {
        formatter = nixpkgs-fmt;
        legacyPackages = pkgs;
        devShells.default = mkShell ({
          inputsFrom = [ gcd.gcd-compiled gcd.tb-dpi-lib ];
          packages = [ cargo rustfmt rust-analyzer nixd nvfetcher ];
          RUST_SRC_PATH =
            "${rust.packages.stable.rustPlatform.rustLibSrc}";
        } // gcd.tb-dpi-lib.env // gcd.gcd-compiled.env);
      });
}
