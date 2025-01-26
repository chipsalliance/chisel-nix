setupIvyLocalRepo() {
  mkdir -p "$NIX_MILL_HOME/.ivy2/local"
  lndir $out/.ivy2/local "$NIX_MILL_HOME/.ivy2/local"

  echo "Copied ivy repo to $NIX_MILL_HOME"
}

postUnpackHooks+=(setupIvyLocalRepo)
