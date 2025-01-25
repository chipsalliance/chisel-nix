configureMillHome() {
  # This hook might be invoked multiple time in same derivation, so don't create new directory
  # when NIX_MILL_HOME is already set.
  export NIX_MILL_HOME="${NIX_MILL_HOME:-$(mktemp -d)}"

  # Set home directory to a custom directory, so that we can easily filter clean sources
  if [[ ! "$JAVA_OPTS" =~ "-Duser.home" ]]; then
    export JAVA_OPTS="$JAVA_OPTS -Duser.home=$NIX_MILL_HOME"
  fi

  # In case mill doesn't pass "$JAVA_OPTS" to fork process
  if [[ ! -r "$NIX_MILL_HOME/mill-java-opts" ]]; then
    echo "$JAVA_OPTS" | tr ' ' '\n' > "$NIX_MILL_HOME/mill-java-opts"
    export MILL_JVM_OPTS_PATH="$NIX_MILL_HOME/mill-java-opts"
  fi

  echo "Java and Mill home directory set to $NIX_MILL_HOME"
}

preUnpackHooks+=(configureMillHome)
