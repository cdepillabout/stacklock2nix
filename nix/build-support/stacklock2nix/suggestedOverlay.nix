
{ haskell, lib, pkgs }:

hfinal: hprev: with haskell.lib.compose; {
  HUnit = dontCheck hprev.HUnit;
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
  # This propagates this to everything depending on haskell-gi-base
  haskell-gi-base = addBuildDepend pkgs.gobject-introspection hprev.haskell-gi-base;
  hourglass = dontCheck hprev.hourglass;
  hspec = dontCheck hprev.hspec;
  hspec-core = dontCheck hprev.hspec-core;
  # Due to tests restricting base in 0.8.0.0 release
  http-media = doJailbreak hprev.http-media;
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
  tasty-expected-failure = dontCheck hprev.tasty-expected-failure;
  test-framework = dontCheck hprev.test-framework;
  unagi-chan = dontCheck hprev.unagi-chan;
  vector = dontCheck hprev.vector;
  # http://hydra.cryp.to/build/501073/nixlog/5/raw
  warp = dontCheck hprev.warp;
}
