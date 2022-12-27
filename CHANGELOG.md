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
