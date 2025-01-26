setupMillCache() {
  mkdir -p "$NIX_MILL_HOME/.cache/coursier"
  lndir $out/.cache/coursier "$NIX_MILL_HOME"/.cache/coursier

  echo "Copied mill deps into $NIX_MILL_HOME"
}

postUnpackHooks+=(setupMillCache)
