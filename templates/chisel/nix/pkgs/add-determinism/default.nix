# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, zlib
, python3
, cargoLockFile ? ./Cargo.lock
, ...
}@args:

let
  marshalparser = args.marshalparser or python3.pkgs.callPackage ./marshalparser.nix { };
  pyEnv = python3.withPackages (ps: [ marshalparser ]);
in
rustPlatform.buildRustPackage {
  pname = "add-determinism";
  version = "unstable-2024-05-11";

  src = fetchFromGitHub {
    owner = "keszybz";
    repo = "add-determinism";
    rev = "f27f0ac8899876d0e3ad36cd4450f51bf6fa3195";
    hash = "sha256-a4PIiQ9T4cTUv7Y4nMjJB+sWLBoOi4ptQF5ApgykO4Y=";
  };

  # this project has no Cargo.lock now
  cargoLock = {
    lockFile = cargoLockFile;
  };

  postPatch = ''
    ln -s ${cargoLockFile} Cargo.lock
  '';

  passthru = { inherit pyEnv marshalparser; };

  nativeBuildInputs = [
    pyEnv
    pkg-config
  ];

  propagatedBuildInputs = [ pyEnv ];

  buildInputs = [
    zlib
  ];

  meta = with lib; {
    description = "Build postprocessor to reset metadata fields for build reproducibility";
    homepage = "https://github.com/keszybz/add-determinism";
    license = licenses.gpl3Only;
    mainProgram = "add-determinism";
  };
}
