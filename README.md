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
Both of these projects contain the same Haskell code, but they use
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

# things to talk about

- you probably want to setup a cache because you'll have to rebuild all haskell packages.
- `stack query` to generate `stack.yaml.lock`
- stacklock2nix vs haskell.nix, and stacklock2nix vs main nixpkgs haskell package set
- sponsor
