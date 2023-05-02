
## 3.0.0

*   Add some additional filters to the default `localPkgFilter` argument.

    Now most files from
    [Haskell.gitignore](https://github.com/github/gitignore/blob/main/Haskell.gitignore)
    are filtered out by default.

    While this is technically a breaking change, this shouldn't negatively
    affect most users.

    Added in [#24](https://github.com/cdepillabout/stacklock2nix/pull/24).

## 2.0.1

*   Fixes a bug in the implementation of the new `localPkgFilter` argument added
    in v2.0.0.  This bug is not a correctness problem (so if you accidentally use
    v2.0.0, you should not get incorrectly built Haskell packages).  The bug is
    just that files will get pulled into the Nix store that you may expect to be
    filtered out.

    See [#23](https://github.com/cdepillabout/stacklock2nix/pull/23) for the
    details.

## 2.0.0

*   (WARNING: There is a bug in the implementation of this new `localPkgFilter`
    feature.  You are recommended to use v2.0.1 instead of v2.0.0!)

    Add a `localPkgFilter` argument to `stacklock2nix`.  This can be used to
    filter the sources of local Haskell packages.

    Here's an example of how you might use it:

    ```nix
    stacklock2nix {
      stackYaml = ./stack.yaml;
      localPkgFilter = defaultLocalPkgFilter: pkgName: path: type:
        if pkgName == "my-example-haskell-lib" && baseNameOf path == "extra-file" then
          false
        else
          defaultLocalPkgFilter path type;
    }
    ```

    This is an example of filtering out a file called `extra-file` from the input
    source of the Haskell package `my-example-haskell-lib`.

    This is a major version bump because if you don't specify the
    `localPkgFilter` argument to `stacklock2nix`, it defaults to using a filter
    that filters out the `.stack-work/` directory, as well as directories like
    `dist-newstyle`.  It also passes input files through the
    `lib.cleanSourceFilter` function, which filters out `.git/`, as well as a
    few other types of files.

    While this is technically a major version bump, most users won't be
    negatively affected by this change.  It is quite likely this won't
    affect most people.

    Added in [#22](https://github.com/cdepillabout/stacklock2nix/pull/22).

## 1.3.0

*   Add `all-cabal-hashes` as an output from `stacklock2nix`.  This can be
    used as in the ["advanced" example](./my-example-haskell-lib-advanced/nix/overlay.nix):

    ```nix
    final: prev: {
      my-example-haskell-stacklock = final.stacklock2nix {
        stackYaml = ../stack.yaml;
        all-cabal-hashes = final.fetchFromGitHub {
          owner = "commercialhaskell";
          repo = "all-cabal-hashes";
          rev = "9ab160f48cb535719783bc43c0fbf33e6d52fa99";
          sha256 = "sha256-Hz/xaCoxe4cJBH3h/KIfjzsrEyD915YEVEK8HFR7nO4=";
        };
      };

      my-example-haskell-pkg-set = final.haskell.packages.ghc924.override (oldAttrs: {
        inherit (final.my-example-haskell-stacklock) all-cabal-hashes;
        ...
    ```

    Added in [#19](https://github.com/cdepillabout/stacklock2nix/pull/19).

## 1.2.0

*   Make sure that `stacklock2nix` will work if the input `all-cabal-hashes`
    argument is a directory (instead of a tarball).

    Passing `all-cabal-hashes` as a directory will make the initial build
    process a little faster (although shouldn't affect future rebuilds).

    You can easily pass `all-cabal-hashes` as a directory by pulling it down
    with `fetchFromGitHub` like the following:

    ```nix
    final: prev: {
      my-stacklock2nix-proj = final.stacklock2nix {
        stackYaml = ./stack.yaml;

        ...

        all-cabal-hashes = final.fetchFromGitHub {
          owner = "commercialhaskell";
          repo = "all-cabal-hashes";
          rev = "9ab160f48cb535719783bc43c0fbf33e6d52fa99";
          sha256 = "sha256-Hz/xaCoxe4cJBH3h/KIfjzsrEyD915YEVEK8HFR7nO4=";
        };
      };
    }
    ```

    Implemented in [#15](https://github.com/cdepillabout/stacklock2nix/pull/15),
    [#16](https://github.com/cdepillabout/stacklock2nix/pull/16), and
    [#17](https://github.com/cdepillabout/stacklock2nix/pull/17).

## 1.1.0

*   Added two new attributes to the attribute set returned from a call to
    `stacklock2nix`: `newPkgSet` and `newPkgSetDevShell`.  These two values are
    similar to the existing `pkgSet` and `devShell` attributes.  Whereas
    `pkgSet` and `devShell` take the `baseHaskellPkgSet` argument and overlay
    it with package overrides created from your `stack.yaml` file, `newPkgSet`
    and `newPkgSetDevShell` are a completely new package set, containing _only_
    packages from your `stack.yaml`.

    The effect of this is that `pkgSet` will contain packages that are in
    Nixpkgs, but not in Stackage.  For instance, when using `pkgSet`, you
    should be able to access the package
    [`pkgSet.termonad`](https://hackage.haskell.org/package/termonad) because
    it is available on Hackage (and in Nixpkgs), even though it is not in any
    Stackage resolver.

    However, `newPkgSet` will only contain packages in your `stack.yaml` file.
    For instance, you'll never be able to access `newPkgSet.termonad` or
    `newPkgSet.spago`, because they will likely never be available on Stackage.

    In general, in your own projects, should you use `pkgSet` or `newPkgSet`?

    For building your own projects, most of the time `pkgSet` and `newPkgSet`
    should be similar.  `newPkgSet` may be slightly safer, since there is
    almost no chance you accidentally use a Haskell package outside of your
    `stack.yaml`.  `pkgSet` may be slightly more convenient depending on what
    you're trying to do.

## 1.0.0

*   This is the 1.0 release of `stacklock2nix`.  I've tested `stacklock2nix` on
    building a few
    [real-world Haskell projects](https://functor.tokyo/blog/2022-12-15-stacklock2nix),
    and it has worked well.  `stacklock2nix` is ready to be widely used.

*   There have been a some overrides added to
    `nix/build-support/stacklock2nix/suggestedOverlay.nix` since the 0.2.0
    release, but no API changes to `stacklock2nix` itself.  This would normally
    be a patch-release (to 0.2.1), but I instead wanted to release version 1.0.

## 0.2.0

*   Add a `callPackage` argument to `stacklock2nix` so that users can easily
    statically-compile Haskell packages.

    This could be used like the following:

    ```nix
    my-haskell-stacklock = final.stacklock2nix {
      stackYaml = ./stack.yaml;
      baseHaskellPkgSet = final.pkgsStatic.haskell.packages.ghc924;
      callPackage = final.pkgsStatic.callPackage;
      ...
    };
    ```

    [#2](https://github.com/cdepillabout/stacklock2nix/pull/2)

*   Make sure `github` types of `extra-deps` in `stack.yaml` are handled
    correctly.  Previous version did not handle `github` deps correctly
    when they had no subdirs.

    `extra-deps` in `stack.yaml` like the following will now work:

    ```yaml
    extra-deps:
      - github: "cdepillabout/pretty-simple"
        commit: "d8ef1b3c2d913a05515b2d1c4fec0b52d2744434"
    ```

    Thanks [@TeofilC](https://github.com/TeofilC)!
    [#6](https://github.com/cdepillabout/stacklock2nix/pull/6)

## 0.1.0

*   Initial release.
