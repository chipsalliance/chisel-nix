configureMillHome() {
  # NIX_BUILD_TOP should be set by nix internally. However to avoid any unexpected behavior,
  # we should handle the directory creation
  NIX_BUILD_TOP=${NIX_BUILD_TOP:-$(mktemp -d)}

  # This hook might be invoked multiple time in same derivation, so don't create new directory
  # when env is already set.
  if [[ -n "$NIX_COURSIER_DIR" ]]; then
    return 0
  fi

  # NIX_COURSIER_DIR is not used by any program, it just act as a anchor directory.
  export NIX_COURSIER_DIR="$NIX_BUILD_TOP/.coursier"
  mkdir -p "$NIX_COURSIER_DIR"

  # Replace the ~/.cache/coursier/v1 directory
  export COURSIER_CACHE="$NIX_COURSIER_DIR/cache"

  # Replace the ~/.ivy2 directory
  ## This is the official coursier supported local repo modification way
  export JAVA_OPTS="-Dcoursier.ivy.home=$NIX_COURSIER_DIR $JAVA_OPTS"
  ## This is mill vendored modification way
  export JAVA_OPTS="-Divy.home=$NIX_COURSIER_DIR $JAVA_OPTS"
  ## Support both could help us reduce debug time

  # Oracle Java use this env
  export JAVA_TOOL_OPTIONS="$JAVA_OPTS $JAVA_TOOL_OPTIONS"

  # In case mill doesn't pass "$JAVA_OPTS" to fork process
  echo "$JAVA_OPTS" | tr ' ' '\n' > "$NIX_BUILD_TOP/mill-java-opts"
  export MILL_JVM_OPTS_PATH="$NIX_BUILD_TOP/mill-java-opts"

  echo "Couriser cache and repo directory set to $NIX_COURSIER_DIR"
}

preUnpackHooks+=(configureMillHome)
