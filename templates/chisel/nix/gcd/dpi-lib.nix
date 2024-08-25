{ lib, rustPlatform, tbConfig, sv2023 ? true, vpi ? false, enable-trace ? false
}:

rustPlatform.buildRustPackage rec {
  name = "dpi-lib";
  src = ./../../gcdemu;
  cargoHash = "sha256-soOva+RFpbA74zyoOIms0G6HLt7dpYcpatsBQSI3hsM=";
  buildFeatures = lib.optionals sv2023 [ "sv2023" ]
    ++ lib.optionals vpi [ "vpi" ] ++ lib.optionals enable-trace [ "trace" ];

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
