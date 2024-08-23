{ lib, rustPlatform, tbConfig, enable-trace ? false }:

rustPlatform.buildRustPackage rec {
  name = "dpi-lib";
  src = ./../../gcdemu;
  cargoHash = "sha256-soOva+RFpbA74zyoOIms0G6HLt7dpYcpatsBQSI3hsM=";
  buildFeatures = [ "sv2023" ] ++ lib.optionals enable-trace [ "trace" ];

  env = {
    DESIGN_DATA_WIDTH = tbConfig.gcdParameter.width;
    DESIGN_TIMEOUT = tbConfig.timeout;
    DESIGN_TEST_SIZE = tbConfig.testSize;
  };

  passthru = {
    inherit enable-trace;
    inherit env;
  };
}
