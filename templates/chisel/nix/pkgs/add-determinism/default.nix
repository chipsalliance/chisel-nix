# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

{ lib
, rustPlatform
, fetchFromGitHub
, fetchpatch
, pkg-config
, zlib
, python3
, stdenv
, cargoLockFile ? ./Cargo.lock
, ...
}@args:

let
  marshalparser = args.marshalparser or python3.pkgs.callPackage ./marshalparser.nix { };
  pyEnv = python3.withPackages (ps: [ marshalparser ]);
in
rustPlatform.buildRustPackage {
  pname = "add-determinism";
  version = "unstable-2024-11-12";

  src = fetchFromGitHub {
    owner = "keszybz";
    repo = "add-determinism";
    rev = "aadcc2fc4648ce8c485fdd9c861eb11adb40c344";
    hash = "sha256-AanKDeFLBeLV5oHWiuPWNJirxDqQwKdZ9Szo5A7fVU8=";
  };

  # this project has no Cargo.lock now
  cargoLock = {
    lockFile = cargoLockFile;
  };

  patches = [
    (fetchpatch {
      url = "https://github.com/Emin017/add-determinism/commit/0c6c4d1c78c845ab6b6b0666aee0e2dc85492205.patch";
      sha256 = "sha256-y5blOfQuZ5GMug4cDkDDKc5jaGgQEYtLTuuLl041sZs=";
    })
  ];

  postPatch = ''
    ln -s ${cargoLockFile} Cargo.lock
  '';

  doCheck = !stdenv.hostPlatform.isDarwin; # it seems to be running forever on darwin

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
