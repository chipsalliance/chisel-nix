# chisel nix

Here we provide nix templates for setting up a Chisel project.

```bash
mkdir my-shining-new-chip
cd my-shining-new-chip
git init
nix flake init -t github:chipsalliance/chisel-nix#chisel
```

Use the above commands to setup a chisel project skeleton.
It will provide you the below code structure:

* elaborator/: source code to the chisel elaborator
* gcd/: source code for the [GCD](https://en.wikipedia.org/wiki/Greatest_common_divisor) example
* nix/: nix build script for the whole lowering process
* build.sc & common.sc: Scala build script
* flake.nix: the root for nix to search scripts

Our packaging strategy is using the `overlay.nix` to "overlay" the nixpkgs.
Every thing that developers want to add or modify should go into the `overlay.nix` file.

This skeleton provides a simple [GCD](https://en.wikipedia.org/wiki/Greatest_common_divisor) example.
It's build script is in `nix/gcd` folder, providing the below attributes:

* gcd-compiled: JVM bytecode for the GCD and elaborator
* elaborator: a bash wrapper for running the elaborator with JDK
* elaborate: Unlowered MLIR bytecode output from firrtl elaborated by elaborator
* mlirbc: MLIR bytecode lowered by circt framework
* rtl: system verilog generated from the lowered MLIR bytecode
* verilated-c-lib: C library verilated from system verilog

To get the corresponding output, developers can use:

```bash
nix build '.#gcd.<attr>'
```

For example, to get the final lowered system verilog, developer can run:

```bash
nix build '.#gcd.rtl'
```

The build result will be a symlink to nix store placed under the `./result`.

To have same environment as the build script for developing purpose, developer can use:

```bash
nix develop '.#gcd.<attr>'
```

For example, to modify the GCD sources, developer can run:

```bash
nix develop '.#gcd.gcd-compiled'
```

The above command will provide a new bash shell with `mill`, `circt`, `chisel`... dependencies set up.

## References


### Use the fetchMillDeps function

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
      millDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
    # ...
    nativeBuildInputs = [
        # ...
        millDeps.setupHook
    ];
}
```

### Use the `nvfetcherSource` attribute

`projectDependencies` attribute is an nix setup hook that will obtain nvfetcher generated sources
and place them under `dependencies` directory in build root.

Read [nvfetcher](https://github.com/berberman/nvfetcher) document for nvfetcher usage.
By default the `nvfetcherSource` attribute will read `nix/pkgs/dependencies/_sources/generated.nix`,
so developer should place nvfetcher config and run `nix run .#nvfetcher` under `nix/pkgs/dependencies`.

Usage:

```nix
stdenv.mkDerivation {
    nativeBuildInputs = [
        projectDependencies.setupHook
    ]
}
```

# License
The build system is released under the Apache-2.0 license, including all Nix and mill build system, All rights reserved by Jiuyang Liu <liu@Jiuyang.me>