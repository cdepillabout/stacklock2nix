
{ haskell, lib, pkgs }:

# This is an Haskell package set overlay of suggested overrides to Haskell
# packages.  Most users will likely want to use this.
#
# These overrides are very similar to the overrides from
# `pkgs/development/haskell/configuration-common.nix` and
# `pkgs/development/haskell/configuration-nix.nix` in Nixpkgs.  You may even
# want to try using those two overlays instead of this file.
#
# If there are additional overrides that need to be copied over from one of the
# above files, please feel free to send a PR to stacklock2nix.
#
# The benefit of having this file in the stacklock2nix sources is that we can
# have Haskell package version-specific overrides, similar to the overrides
# from poetry2nix.  The two above files from Nixpkgs mostly only work with
# a single Haskell package version.
#
# For instance, stacklock2nix should provide overrides similar to the following:
#
# ```
# lens =
#   if lib.versionOlder hprev.lens.version "5.0" then
#     # lens tests are broken on all versions before 5.0
#     dontCheck hprev.lens
#   else hprev.lens;
# ```
#
# These will be maintained on a best-effort basis.  Again, please send PRs.
#
# Make sure to keep this list in alphabetical order.

hfinal: hprev: with haskell.lib.compose; {

  # Test suite is broken with QuickCheck-2.14.3:
  # https://github.com/nick8325/quickcheck/issues/359
  aeson = dontCheck hprev.aeson;

  # the testsuite fails because of not finding tsc without some help
  aeson-typescript = overrideCabal (drv: {
    testToolDepends = drv.testToolDepends or [] ++ [ pkgs.nodePackages.typescript ];
    # the testsuite assumes that tsc is in the PATH if it thinks it's in
    # CI, otherwise trying to install it.
    #
    # https://github.com/codedownio/aeson-typescript/blob/ee1a87fcab8a548c69e46685ce91465a7462be89/test/Util.hs#L27-L33
    preCheck = "export CI=true";
    # Even with the above fixes, it appears that the test suite fails depending
    # on what version of tsc you're using.
    doCheck = false;
  }) hprev.aeson-typescript;

  # requires a version of QuickCheck that is not in the stackage resolver
  algebraic-graphs = dontCheck hprev.algebraic-graphs;

  ansi-terminal = dontCheck hprev.ansi-terminal;

  async = dontCheck hprev.async;

  base-orphans = dontCheck hprev.base-orphans;

  # doctests fail
  bsb-http-chunked = dontCheck hprev.bsb-http-chunked;

  # Tests don't include all necessary files.
  c2hs = dontCheck hprev.c2hs;

  clock = dontCheck hprev.clock;

  colour = dontCheck hprev.colour;

  doctest = dontCheck hprev.doctest;

  doctest-parallel = dontCheck hprev.doctest-parallel;

  dyre =
    lib.pipe
      hprev.dyre
      [
        # Dyre needs special support for reading the NIX_GHC env var.  This is
        # available upstream in https://github.com/willdonnelly/dyre/pull/43, but
        # hasn't been released to Hackage as of dyre-0.9.1.  Likely included in
        # next version.
        (appendPatch
          (pkgs.fetchpatch {
            url = "https://github.com/willdonnelly/dyre/commit/c7f29d321aae343d6b314f058812dffcba9d7133.patch";
            sha256 = "10m22k35bi6cci798vjpy4c2l08lq5nmmj24iwp0aflvmjdgscdb";
          }))
        # dyre's tests appear to be trying to directly call GHC.
        dontCheck
      ];

  # Tests have a dependency on a QuickCheck version that is not in Stackage.
  edit-distance = dontCheck hprev.edit-distance;

  focuslist = dontCheck hprev.focuslist;

  # Test suite uses git exe
  githash = dontCheck hprev.githash;

  glib =
    lib.pipe
      hprev.glib
      [ (disableHardening ["fortify"])
        (addPkgconfigDepend pkgs.glib.dev)
        # (addBuildTool hfinal.gtk2hs-buildtools)
      ];

  # Version constraints on tests are too strict.
  haddock-library = dontCheck hprev.haddock-library;

  # Old versions of the happy testsuite will segfault on ARM due to an LLVM bug:
  # https://github.com/llvm/llvm-project/issues/52844
  happy = dontCheck hprev.happy;

  hashable = dontCheck hprev.hashable;

  # This propagates this to everything depending on haskell-gi-base
  haskell-gi-base = addBuildDepend pkgs.gobject-introspection hprev.haskell-gi-base;

  # Tests access the network
  hnix = dontCheck hprev.hnix;

  hourglass = dontCheck hprev.hourglass;

  # fails because tests don't expect a revised cabal file
  hpack = dontCheck hprev.hpack;

  # hslua-core has tests that appear to break when using musl.
  # https://github.com/hslua/hslua/issues/106
  hslua-core = dontCheck hprev.hslua-core;

  # tests aren't included in the sdist
  hslua-list = dontCheck hprev.hslua-list;

  hspec = dontCheck hprev.hspec;

  hspec-core = dontCheck hprev.hspec-core;

  # hspec-discover tests rely on the hspec-meta package, which is not in Stackage, so
  # frequently causes failed builds.
  hspec-discover = dontCheck hprev.hspec-discover;

  # Needs internet to run tests
  HTTP = dontCheck hprev.HTTP;

  # Due to tests restricting base in 0.8.0.0 release
  http-media = doJailbreak hprev.http-media;

  HUnit = dontCheck hprev.HUnit;

  logging-facade = dontCheck hprev.logging-facade;

  logict = dontCheck hprev.logict;

  # Tests appear to not include all required files
  lsp-test = dontCheck hprev.lsp-test;

  # Test suite is broken with QuickCheck-2.14.3:
  # https://github.com/nick8325/quickcheck/issues/359
  math-functions = dontCheck hprev.math-functions;

  # Tests seem to make incorrect assumptions about URLs and order of items from Maps.
  mmark = dontCheck hprev.mmark;

  mockery = dontCheck hprev.mockery;

  nanospec = dontCheck hprev.nanospec;

  # circular dependency in tests
  options = dontCheck hprev.options;

  # tests require postgres running
  pg-transact = dontCheck hprev.pg-transact;

  random = dontCheck hprev.random;

  # Disabling doctests.
  regex-tdfa = overrideCabal { testTarget = "regex-tdfa-unittest"; } hprev.regex-tdfa;

  # the rio test suite calls functions from unliftio that are broken:
  # https://github.com/fpco/unliftio/issues/87
  rio = dontCheck hprev.rio;

  # https://github.com/ndmitchell/shake/issues/804
  shake = dontCheck hprev.shake;

  smallcheck = dontCheck hprev.smallcheck;

  # Tests require node.
  sourcemap = dontCheck hprev.sourcemap;

  splitmix = dontCheck hprev.splitmix;

  # Test suite is broken with QuickCheck-2.14.3:
  # https://github.com/nick8325/quickcheck/issues/359
  statistics = dontCheck hprev.statistics;

  syb = dontCheck hprev.syb;

  # requires a version of chell that is not in the stackage resolver
  system-fileio = dontCheck hprev.system-fileio;

  # requires a version of chell that is not in the stackage resolver
  system-filepath = dontCheck hprev.system-filepath;

  tasty = dontCheck hprev.tasty;

  tasty-discover =
    if hprev.tasty-discover.version == "4.2.2" then
      # Test suite is missing an import from hspec
      # https://github.com/haskell-works/tasty-discover/issues/9
      # https://github.com/commercialhaskell/stackage/issues/6584#issuecomment-1326522815
      dontCheck hprev.tasty-discover
    else
      hprev.tasty-discover;

  tasty-expected-failure = dontCheck hprev.tasty-expected-failure;

  test-framework = dontCheck hprev.test-framework;

  # requires a version of tasty that is not in the stackage resolver
  text-short = dontCheck hprev.text-short;

  # Flaky tests: https://github.com/jfischoff/tmp-postgres/issues/274
  tmp-postgres = dontCheck hprev.tmp-postgres;

  # Depends on system tzdata library.
  # https://github.com/NixOS/nixpkgs/commit/0c2ff42913035c83d56b53aeafd24b39b31d4152
  tz = addBuildDepends [ pkgs.tzdata ] hprev.tz;

  # Depends on system tzdata library.
  # https://github.com/NixOS/nixpkgs/commit/0c2ff42913035c83d56b53aeafd24b39b31d4152
  tzdata = addBuildDepends [ pkgs.tzdata ] hprev.tzdata;

  unagi-chan = dontCheck hprev.unagi-chan;

  # tests don't support musl
  unix-time = dontCheck hprev.unix-time;

  # unliftio test suite has functions that are broken on darwin
  # https://github.com/fpco/unliftio/issues/87
  unliftio = dontCheck hprev.unliftio;

  # Test suite requires the nothunks library, which isn't on stackage.
  unordered-containers = dontCheck hprev.unordered-containers;

  vector = dontCheck hprev.vector;

  # test suite uses phantom js
  wai-cors = dontCheck hprev.wai-cors;

  # http://hydra.cryp.to/build/501073/nixlog/5/raw
  warp = dontCheck hprev.warp;

  # https://github.com/jgm/zip-archive/issues/57
  zip-archive = dontCheck hprev.zip-archive;
}
