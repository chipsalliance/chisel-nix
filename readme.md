## General notes

- To obtain new source code hash, developers can replace old hash with empty string, and let nix figure out the new hash.
- If there are some attribute not exposed in override function, developers can still using the overrideAttrs function.

## Use the fetchMillDeps function

Fetch project dependencies for later offline usage.

The `fetchMillDeps` function accept three args: `name`, `src`, `millDepsHash`:

* name: name of the mill dependencies derivation, suggest using `<module>-mill-deps` as suffix.
* src: path to a directory that contains at least `build.sc` file for mill to obtain dependencies.
* millDepsHash: same functionality as the `sha256`, `hash` attr in stdenv.mkDerivation. To obtain new hash for new dependencies, replace the old hash with empty string, and let nix figure the new hash.

This derivation will read `$JAVA_OPTS` environment varialble, to set http proxy, you can export:

```bash
export JAVA_OPTS="-Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=1234"
```

The returning derivation have `setupHook` attribute to automatically setup dependencies path for mill.
Add the attribute into `nativeBuildInputs`, and let nix run the hook.

Example:

```nix
stdenv.mkDerivation rec {
    # ...
    millDeps = fetchMillDeps {
      inherit name;
      src = with lib.fileset; toSource {
        root = ./.;
        fileset = unions [
          ./build.sc
        ];
      };
      millDepsHash = "sha256-DQeKTqf+MES5ubORu+SMJEiqpOCXsS7VgxUnSqG12Bs=";
    };
    # ...
    nativeBuildInputs = [
        # ...
        millDeps.setupHook
    ];
}
```

## Use the `nvfetcherSource` attribute

`nvfetcherSource` attribute is an nix setup hook that will obtain nvfetcher generated sources
and place them under `dependencies` directory in build root.

Read [nvfetcher](https://github.com/berberman/nvfetcher) document for nvfetcher usage.
By default the `nvfetcherSource` attribute will read `nix/pkgs/_sources/generated.nix`,
so developer should place nvfetcher config and run `nix run .#nvfetcher` under `nix/pkgs`.

Usage:

```nix
stdenv.mkDerivation {
    nativeBuildInputs = [
        nvfetcherSource.setupHook
    ]
}
```

## Exposed overridable attrs

### espresso

To override espresso, use the `override` method:

```nix
final: prev: {
    myEspresso = prev.espresso.override {
        version = "<version>";
        srcHash = "<hash>";
    };
}
```
