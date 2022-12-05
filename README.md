# stacklock2nix

This repository provides a Nix function: `stacklock2nix`. This function
generates a Nixpkgs-compatible Haskell package set from a `stack.yaml` and
`stack.yaml.lock` file.

`stacklock2nix` will be most helpful in the following two cases:

-   You (or your team) are already using Stack, and you want an easy way to build your
    project with Nix.  You want to avoid the complexities of
    [haskell.nix](https://github.com/input-output-hk/haskell.nix).

-   You are a happy user of the Haskell infrastructure in Nixpkgs, but you want an
    easy way to generate a Nixpkgs Haskell package set from an arbitrary Stackage
    resolver.

    At any given time, the main Haskell package set in Nixpkgs only supports a single
    version of GHC. If you have a complex project that needs an older or newer version of
    GHC, `stacklock2nix` can easily generate a package set that is likely to compile.

## Quickstart

You can get started with `stacklock2nix` by either adding this repo as a flake
input and applying the exposed `.overlay` attribute, or just directly importing
and applying the [`./nix/overlay.nix`](./nix/overlay.nix) file. This overlay
exposes a top-level `stacklock2nix` function.

This repo contains two example projects showing how to use `stacklock2nix`.
Both of these projects contain mostly the same Haskell code, but they use
different features of `stacklock2nix`:

-   [Easy example](./my-example-haskell-lib-easy/)

    This is an easy example to get started with using `stacklock2nix`.  This
    method is recommended for people that want to play around with
    `stacklock2nix`, or just easily build their Stack-based projects with Nix.
    All the interesting code is documented in the
    [`flake.nix`](./my-example-haskell-lib-easy/flake.nix) file.

    From the [`./my-example-haskell-lib-easy`](./my-example-haskell-lib-easy)
    directory, you can build the Haskell app with the command:

    ```console
    $ nix build
    ```

    You can get into a development shell with the command:

    ```console
    $ nix develop
    ```

    From this development shell, you can use `cabal` to build your project like
    normal:

    ```console
    $ cabal build all
    ```

    Development tools like `haskell-language-server` are also available.

-   [Advanced example](./my-example-haskell-lib-advanced/)

    This is an example that uses more of the advanced features of
    `stacklock2nix`.  This method is recommended for people that need extra
    flexibility, or people who also want to use `stack` for development.  The
    interesting code is spread out between the
    [`flake.nix`](./my-example-haskell-lib-advanced/flake.nix) file, and the
    [`overlay.nix`](./my-example-haskell-lib-advanced/nix/overlay.nix) file.

    Just like the above, you can run `nix build` to build the application, and
    `nix develop` to get into a development shell.  From the development shell,
    you can run `cabal` commands.

    In addition, you can also use the old-style Nix commands.  To build the application:

    ```console
    $ nix-build
    ```

    To get into a development shell:

    ```console
    $ nix-shell
    ```

    You can also use `stack` to build your application:

    ```console
    $ stack --nix build
    ```

## `stacklock2nix` Arguments and Return Values

The arguments to `stacklock2nix` and return values are documented in
[`./nix/build-support/stacklock2nix/default.nix`](nix/build-support/stacklock2nix/default.nix).

Please open an issue or send a PR for anything that is not sufficiently
documented.

## How to Generate `stack.yaml` and `stack.yaml.lock`

If you're not already a Stack user, you'll need to generate a `stack.yaml` and
`stack.yaml.lock` file for your Haskell project before you can use
`stacklock2nix`.

In order to generate a `stack.yaml` file, you will need to make `stack`
available and run `stack init`:

```console
$ nix-shell -p stack --command "stack init"
```

One unfortunate thing about `stack` is that if you're on NixOS, `stack` tries
to re-exec itself in a `nix-shell` with GHC available (run
`stack --verbose init` and look for `nix-shell` to see exactly what `stack`
is trying to do). `stack` will try to take GHC from your current Nix channel.
However, it is possible that `stack` will try to use a GHC version that is not
available in your current Nix channel.

In order to deal with this, you can force stack to use a `NIX_PATH` with
a different channel available.  You should pick a channel (or Nixpkgs commit) that
contains the GHC version `stack` is trying to use.  For example, here's a
shortcut for forcing `stack` to use the latest commit from the
`nixpkgs-unstable` channel:

```console
$ nix-shell -p stack --command "stack --nix-path nixpkgs=channel:nixpkgs-unstable init"
```

Once you have a `stack.yaml` available, you can generate a `stack.yaml.lock` file
with the following command:

```console
$ nix-shell -p stack --command "stack query"
```

Note that the `--nix-path` argument may be necessary here as well.

If you have any problems with Stack, make sure to check the
[upstream Stack documentation](https://docs.haskellstack.org/en/stable/GUIDE/).
You may also be interested in Stack's
[Nix integration](https://docs.haskellstack.org/en/stable/nix_integration/).

## Nix Cache

Because of how `stacklock2nix` works, you won't be able to pull any pre-built
Haskell packages from the shared NixOS Hydra cache. Its recommended that you
use some sort of Nix cache, like [Cachix](https://www.cachix.org/).

This is especially important if you're trying to introduce Nix into a
professional setting.  Not having to locally build transitive dependencies is a
big selling-point for doing Haskell development with Nix.

## `stacklock2nix` vs haskell.nix

If you want to build a Haskell project with Nix using a `stack.yaml` and
`stack.yaml.lock` file as a single source of truth, your two main choices are
`stacklock2nix` and [haskell.nix](https://github.com/input-output-hk/haskell.nix).

haskell.nix is a much more comprehensive solution, but it also comes with much
more complexity.  `stacklock2nix` is effectively just a small wrapper around
existing functionality in the Haskell infrastructure in Nixpkgs.

Advantages of haskell.nix:

-   The ability to build a Haskell project without a `stack.yaml` file,
    just using the Cabal solver to generate a package set.
-   The ability to build a project based just on a `stack.yaml` file
    (without also requiring a `stack.yaml.lock` file).
-   A shared cache from IOHK.  (Although users commonly report not
    getting cache hits for various reasons.)
-   The ability to cross-compile Haskell libraries.  (For instance,
    building an ARM64 binary on an x86_64 machine.)

Advantages of `stacklock2nix`:

-   Integrates with the Haskell infrastructure in Nixpkgs.  Easy to use if
    you're already familiar with Nixpkgs.
-   Code is simple and well-documented.
-   Unlike haskell.nix, Nix evaluation is very fast (so you don't have to wait
    10s of seconds to jump into a development shell).

## Versioning

`stacklock2nix` is versioned by [Semantic Versioning](https://semver.org/).
It is recommended you pin to one of the
[Release](https://github.com/cdepillabout/stacklock2nix/releases)
versions instead of the `main` branch.  You may also be interested in
the [`CHANGELOG.md`](./CHANGELOG.md) file.

## Contributions and Where to Get Help

Contributions are highly appreciated.  If there is something you would like to
add to `stacklock2nix`, or if you find a bug, please submit an
[issue](https://github.com/cdepillabout/stacklock2nix/issues) or
[PR](https://github.com/cdepillabout/stacklock2nix/pulls)!

The easiest way to get help with `stacklock2nix` is to open an issue describing
your problem.  If you link to a repository (even a simple example) that can
be cloned and demonstrates your problem, it is much easier to help.

## Sponsor `stacklock2nix`

Sponsoring `stacklock2nix` enables me to spend more time fixing bugs, reviewing
PRs, and helping people who run into problems.  I prioritize issues and PRs
from people who are sponsors.

You can find the sponsor page [here](https://github.com/sponsors/cdepillabout).

## FAQ

-   **Is it possible to use `stacklock2nix` to build a statically-linked Haskell library?**

    Recent versions (since mid-2022) of the Haskell infrastructure in Nixpkgs
    have the ability to link Haskell executables completely statically.  An
    easy way to test this out is to use the
    [`pkgsStatic` subpackage set](https://functor.tokyo/blog/2021-10-20-nix-cross-static)
    in Nixpkgs.

    Instead of passing a value like `pkgs.haskell.packages.ghc924` to the
    `baseHaskellPkgSet` of the `stacklock2nix` function, pass
    `pkgs.pkgsStatic.haskell.packages.ghc924`:

    ```nix
    my-haskell-stacklock = final.stacklock2nix {
      stackYaml = ./stack.yaml;
      baseHaskellPkgSet = final.pkgsStatic.haskell.packages.ghc924;
      callPackage = final.pkgsStatic.callPackage;
      ...
    };
    ```

-   **When using `stacklock2nix` do you ever need to compile GHC?**

    In general, no.

    `stacklock2nix` uses the Haskell infrastructure from Nixpkgs.  As long as
    you're on a standard [Nixpkgs Channel](https://status.nixos.org/), you
    should be able to pull any available version of GHC from the stanard
    Nixpkgs/NixOS/Hydra cache.  `stacklock2nix` doesn't override the GHC
    derivations in any way, so you should almost never have to recompile GHC.

    `stacklock2nix` does override all the Haskell packages in your Stackage
    resolver, so you _will_ have to compile all the Haskell packages you use
    (similar to when you use `stack`).
