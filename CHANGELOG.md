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
