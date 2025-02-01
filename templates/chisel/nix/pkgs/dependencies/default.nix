{ pkgs
, stdenv
, mill
, add-determinism
, ...
}:
{ name
, version
, outputHash
, publishPhase
, ...
}@args:
let
  dependencies = pkgs.callPackage ./_sources/generated.nix { };
in
stdenv.mkDerivation {
  pname = name;
  src = dependencies.${name}.src;

  inherit version outputHash;

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";

  nativeBuildInputs = [ mill ] ++ (args.nativeBuildInputs or [ ]);

  impureEnvVars = [ "JAVA_OPTS" ];

  buildPhase = ''
    runHook preBuild
    echo "-Duser.home=$TMPDIR -Divy.home=$TMPDIR/ivy $JAVA_OPTS" | tr ' ' '\n' > mill-java-opts
    export MILL_JVM_OPTS_PATH=$PWD/mill-java-opts

    # Use "https://repo1.maven.org/maven2/" only to keep dependencies integrity
    export COURSIER_REPOSITORIES="ivy2Local|central"
    
    ${publishPhase}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/.ivy2
    mv $TMPDIR/ivy/local $out/.ivy2/local

    export SOURCE_DATE_EPOCH=1669810380
    find $out -type f -name '*.jar' -exec '${add-determinism}/bin/add-determinism' -j "$NIX_BUILD_CORES" '{}' ';'

    runHook postInstall
  '';
}
