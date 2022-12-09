
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
