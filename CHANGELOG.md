
## 4.2.0

*   Add a new `devShellPkgSetModifier` for giving the user a hook to modify the
    Haskell package set used to generate the development shell.
    See
    [here](https://github.com/cdepillabout/stacklock2nix/blob/ff62905d81884b1ed97243cc1b9854ba9f99e4c5/nix/build-support/stacklock2nix/default.nix#L66-L93)
    for documentation. Added in [#59](https://github.com/cdepillabout/stacklock2nix/pull/59).

*   Add a new `devShellArgsModifier` for giving the user a hook to modify the
    arguments passed to `shellFor` when generating the development shell.
    See
    [here](https://github.com/cdepillabout/stacklock2nix/blob/ff62905d81884b1ed97243cc1b9854ba9f99e4c5/nix/build-support/stacklock2nix/default.nix#L94-L115)
    for documentation. Added in [#59](https://github.com/cdepillabout/stacklock2nix/pull/59).
    Heavily inspired by [#57](https://github.com/cdepillabout/stacklock2nix/pull/57).
    Thanks [@haruki7049](https://github.com/haruki7049)!

*   Various additions to the suggestedOverlay.nix file to get more Haskell
    packages building by default:

    - mark `binary-search` as `dontCheck`
    - mark `haskoin-core` as `dontCheck`
    - mark `hedis` as `dontCheck`
    - mark `http-client` as `dontCheck`
    - mark `http-client-openssl` as `dontCheck`
    - mark `http-client-tls` as `dontCheck`
    - mark `http-conduit` as `dontCheck`
    - mark `js-query` as `dontCheck`
    - mark `prettyprinter` as `dontCheck`
    - mark `servant-openapi3` as `dontCheck`

    Added in [#59](https://github.com/cdepillabout/stacklock2nix/pull/59).

## 4.1.0

*   Add build depend on system `tzdata` package for the Haskell `tz` and
    `tzdata` packages in `nix/build-support/stacklock2nix/suggestedOverlay.nix`.
    Fixed in [#52](https://github.com/cdepillabout/stacklock2nix/pull/52).

*   Make sure Haskell packages specified as Git repos in the `stack.yaml` file
    check out all submodules when fetching their source.
    Fixed in [#53](https://github.com/cdepillabout/stacklock2nix/pull/53).
    Thanks to [@isomorpheme](https://github.com/isomorpheme) for reporting this.

*   Change handling of subdirs for `git` extra-deps.

    `stacklock2nix` internally calls `cabal2nix` to generate Nix expressions
    for Haskell packages.  In previous versions of `stacklock2nix`, the
    actual `subdir` for a `git` extra-dep would be copied to the Nix store,
    and then `cabal2nix` would be run on it.

    This has been fixed to instead call `cabalni2x` on the full Git repo,
    but pass the `--subpath` to specify the sub package.  This likely
    works better where sub paths contain soft links to other paths in the
    Git repo.

    It is unlikely this change will cause any problems for any current users of
    `stacklock2nix`.

    Fixed in [#46](https://github.com/cdepillabout/stacklock2nix/pull/46) and
    [#56](https://github.com/cdepillabout/stacklock2nix/pull/56).
    Thanks to [@isomorpheme](https://github.com/isomorpheme)

*   Make `stacklock2nix`'s `fromYAML` function more reliable.

    `stacklock2nix` internally uses the
    [`remarshal`](https://github.com/remarshal-project/remarshal) tool for
    converting from the `stack.yaml` file to a JSON, in order to read it with
    Nix.

    Recent versions of `remarshal` (>= 0.17.0) changed functionality to fail at
    runtime more often.  An new flag is needed on the command line to fall back
    to the old functionality.

    Fixed in [#55](https://github.com/cdepillabout/stacklock2nix/pull/55).
    Thanks to [@Mr-Andersen](https://github.com/Mr-Andersen)

## 4.0.2

*   Fix a bug where `stacklock2nix` would throw an error if there were
    no local `packages` defined in the input `stack.yaml` file.

    This PR also makes `stacklock2nix` use a default package of `"."` if the
    top-level `packages` key is missing from the `stack.yaml` file.  This
    matches `stack`'s behavior.

    Fixed in [#50](https://github.com/cdepillabout/stacklock2nix/pull/50).
    Thanks [@chris-martin](https://github.com/chris-martin) for reporting this.

## 4.0.1

*   Download `.cabal` file revisions from the public Casa instance instead of
    Hackage.

    We believe this change shouldn't affect any end users, but we now depend on
    <https://casa.stackage.org> instead of Hackage.  If Casa ends up having
    signficantly worse uptime than Hackage, then users may be affected when
    trying to use stacklock2nix.  Please let us know if this ends up affecting
    you.

    Added in [#42](https://github.com/cdepillabout/stacklock2nix/pull/42).
    Thanks [@TeofilC](https://github.com/TeofilC)!

## 4.0.0

*   Make sure the `psqueues` Haskell package gets the `fingertree-psqueue` dep
    depending on what version of `psqueues` you're compiling.

    Added in [#39](https://github.com/cdepillabout/stacklock2nix/pull/39).

*   Change stacklock2nix's handling of Stack's `git` dependencies.

    A `git` dependency looks like the following in `stack.yaml`:

    ```yaml
    extra-deps:
      - git: "https://github.com/haskell-servant/servant-cassava"
        commit: "f76308b42b9f93a6641c70847cec8ecafbad3abc"
    ```

    Up until now, stacklock2nix would download Stack's `git` dependencies using
    Nix's `builtins.fetchGit` function.

    By default, this function doesn't clone the full repository, but only the
    history of the default branch.  This is a problem if you try to specify a
    commit that is not a parent of the default branch.  This may happen if
    you're developing new functionality in a feature branch that hasn't yet
    been merged into `master`.

    stacklock2nix has been changed to additionally specify the `allRefs = true`
    argument to `builtins.fetchGit`.  This causes the full Git repository to be
    downloaded, even commits that aren't ancestors of the default branch.

    Added in [#39](https://github.com/cdepillabout/stacklock2nix/pull/39).
    Thanks to [@isomorpheme](https://github.com/isomorpheme) for reporting this
    and coming up with the fix.

    It is possible this causes increased download times, especially for repos
    that are very big.

    You may be able to work around this by using Stack's functionality for
    downloading given URLs, in order to download a tarball of a repository
    (without any of the Git history).:

    ```yaml
    extra-deps:
      - url: "https://github.com/haskell-servant/servant-cassava/archive/f76308b42b9f93a6641c70847cec8ecafbad3abc.tar.gz"
    ```

## 3.0.5

*   Make sure the `digest` Haskell package gets the system `zlib` as an argument.

    Added in [#35](https://github.com/cdepillabout/stacklock2nix/pull/35).

## 3.0.4

*   Remove `dontCheck` override for `haskeline` in
    `nix/build-support/stacklock2nix/suggestedOverlay.nix`.  `haskeline` is a
    GHC boot package, so it is not built as a separate Nix derivation.
    It is distributed with GHC, so it is set to `null` in the Nixpkgs pkg set.

## 3.0.3

*   A few additional overrides added to
    `nix/build-support/stacklock2nix/suggestedOverlay.nix` to fix some
    breakages in test suites
    [caused by QuickCheck-2.14.3](https://github.com/nick8325/quickcheck/issues/359).
    QuickCheck-2.14.3 is included in LTS-20.24, so you'll likely need these fixes if
    you are using LTS-20.24 or later.

    Added in [#31](https://github.com/cdepillabout/stacklock2nix/pull/31).

## 3.0.2

*   Fix override with splitmix argument, `testu01`.

    Added in [#28](https://github.com/cdepillabout/stacklock2nix/pull/28).

*   A few additional overrides added to
    `nix/build-support/stacklock2nix/suggestedOverlay.nix` to fix some common
    problems on Darwin.

    Added in [#28](https://github.com/cdepillabout/stacklock2nix/pull/28).

## 3.0.1

*   Fix override with unordered-containers argument, `nothunks`.

    Added in [#26](https://github.com/cdepillabout/stacklock2nix/pull/26).

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
