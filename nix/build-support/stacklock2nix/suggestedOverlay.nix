
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

hfinal: hprev: with haskell.lib.compose; {

  ansi-terminal = dontCheck hprev.ansi-terminal;

  async = dontCheck hprev.async;

  base-orphans = dontCheck hprev.base-orphans;

  # doctests fail
  bsb-http-chunked = dontCheck hprev.bsb-http-chunked;

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

  focuslist = dontCheck hprev.focuslist;

  glib =
    lib.pipe
      hprev.glib
      [ (disableHardening ["fortify"])
        (addPkgconfigDepend pkgs.glib.dev)
        # (addBuildTool hfinal.gtk2hs-buildtools)
      ];

  hashable = dontCheck hprev.hashable;

  haskeline = dontCheck hprev.haskeline;

  # This propagates this to everything depending on haskell-gi-base
  haskell-gi-base = addBuildDepend pkgs.gobject-introspection hprev.haskell-gi-base;

  hourglass = dontCheck hprev.hourglass;

  # fails because tests don't expect a revised cabal file
  hpack = dontCheck hprev.hpack;

  hspec = dontCheck hprev.hspec;

  hspec-core = dontCheck hprev.hspec-core;

  # Needs internet to run tests
  HTTP = dontCheck hprev.HTTP;

  # Due to tests restricting base in 0.8.0.0 release
  http-media = doJailbreak hprev.http-media;

  HUnit = dontCheck hprev.HUnit;

  logging-facade = dontCheck hprev.logging-facade;

  logict = dontCheck hprev.logict;

  mockery = dontCheck hprev.mockery;

  nanospec = dontCheck hprev.nanospec;

  # test suite doesn't build
  nothunks = dontCheck hprev.nothunks;

  random = dontCheck hprev.random;

  # Disabling doctests.
  regex-tdfa = overrideCabal { testTarget = "regex-tdfa-unittest"; } hprev.regex-tdfa;

  smallcheck = dontCheck hprev.smallcheck;

  splitmix = dontCheck hprev.splitmix;

  syb = dontCheck hprev.syb;

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

  unagi-chan = dontCheck hprev.unagi-chan;

  vector = dontCheck hprev.vector;

  # http://hydra.cryp.to/build/501073/nixlog/5/raw
  warp = dontCheck hprev.warp;
}
