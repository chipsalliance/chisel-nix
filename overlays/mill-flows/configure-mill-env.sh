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
  export JAVA_OPTS="$JAVA_OPTS -Dcoursier.ivy.home=$NIX_COURSIER_DIR"
  # Duplicate the cache dir settings to java system property, to avoid any env issues
  export JAVA_OPTS="$JAVA_OPTS -Dcoursier.cache=$COURSIER_CACHE"

  # Oracle Java use this env
  export JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS $JAVA_OPTS"

  # In case mill doesn't pass "$JAVA_OPTS" to fork process
  echo "$JAVA_OPTS" | tr ' ' '\n' > "$NIX_BUILD_TOP/mill-java-opts"
  export MILL_JVM_OPTS_PATH="$NIX_BUILD_TOP/mill-java-opts"

  echo "Couriser cache and repo directory set to $NIX_COURSIER_DIR"
}

preUnpackHooks+=(configureMillHome)
