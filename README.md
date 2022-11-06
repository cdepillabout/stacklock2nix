# stacklock2nix

This repository provides a Nix function, `stacklock2nix`, that generates a
Nixpkgs-compatible Haskell package set from a `stack.yaml` and `stack.yaml.lock` file.

`stacklock2nix` will be most helpful in the following two cases:

-   You (or your team) are already using Stack, and you want an easy way to build your
    project with Nix.  You want to avoid the complexities of
    [haskell.nix](https://github.com/input-output-hk/haskell.nix).

-   You are a happy user of the Haskell infrastructure in Nixpkgs, but you want an
    easy way to generate a Nixpkgs Haskell package set from an arbitrary Stackage
    resolver.

    At any given time, the main Haskell package set in Nixpkgs only supports a single
    version of GHC. If you have a complex project that needs an older or newer version of
    GHC, `stacklock2nix` can easily generate a package set that is known to compile.

## Quickstart

You can get started with `stacklock2nix` by either adding this repo as a flake
input, and applying the exposed `.overlay` attribute, or just directly importing
and applying the [`./nix/overlay.nix`](./nix/overlay.nix) file.

This overlay exposes a top-level `stacklock2nix` function.  Here's an example of
using this function.  This assumes you have a Haskell package in a directory
`./my-example-haskell-lib/` with a `stack.yaml` and `stack.yaml.lock` file:

`default.nix`:

```nix
let
  nixpkgs-src = builtins.fetchTarball {
    # nixos-unstable from 2022-10-25 (you may want to update this to something more recent!)
    url = "https://github.com/nixos/nixpkgs/archive/f994293d1eb8812f032e8919e10a594567cf6ef7.tar.gz";
    sha256 = "0j81pv6i6psq37250m0x1hjizykfdxmnh90561gkvyskb0klq2hv";
  };

  stacklock2nix-src = builtins.fetchTarball {
    # stacklock2nix from 2022-11-06 (you definitely want to update this to something more recent!!)
    url = "https://github.com/cdepillabout/stacklock2nix/archive/f8a3860a904037b029126c1de9287676002a3e5f.tar.gz";
    sha256 = "02jvliii3grfcwdqnvwqma9zmzr7gzwdz6kjx14wm38qfyx629hx";
  };

  nixpkgs = import nixpkgs-src { overlays = [ (import "${stacklock2nix-src}/nix/overlay.nix") ]; };

  my-example-haskell-lib-stacklock = nixpkgs.stacklock2nix {
    stackYaml = ./my-example-haskell-lib/stack.yaml;
    baseHaskellPkgSet = nixpkgs.haskell.packages.ghc924;
    additionalHaskellPkgSetOverrides = hfinal: hprev: {
      lens = nixpkgs.haskell.lib.compose.dontCheck hprev.lens;
    };
    additionalDevShellNativeBuildInputs = stacklockHaskellPkgSet: [
      nixpkgs.cabal-install
      nixpkgs.ghcid
      nixpkgs.haskell.packages.ghc924.haskell-language-server
    ];
    all-cabal-hashes = nixpkgs.fetchurl {
      url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/9ab160f48cb535719783bc43c0fbf33e6d52fa99.tar.gz";
      sha256 = "sha256-QC07T3MEm9LIMRpxIq3Pnqul60r7FpAdope6S62sEX8=";
    };
  };
in
my-example-haskell-lib-stacklock.pkgSet.my-example-haskell-lib
```


# things to talk about

- you probably want to setup a cache because you'll have to rebuild all haskell packages.
- `stack query` to generate `stack.yaml.lock`
- stacklock2nix vs haskell.nix, and stacklock2nix vs main nixpkgs haskell package set
- sponsor
