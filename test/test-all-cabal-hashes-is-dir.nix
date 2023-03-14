{ stacklock2nix
, haskell
, cabal-install
, fetchFromGitHub
}:

let
  hasklib = haskell.lib.compose;

  stacklock = stacklock2nix {
    stackYaml = ../my-example-haskell-lib-easy/stack.yaml;
    baseHaskellPkgSet = haskell.packages.ghc924;
    additionalHaskellPkgSetOverrides = hfinal: hprev: {
      # The servant-cassava.cabal file is malformed on GitHub:
      # https://github.com/haskell-servant/servant-cassava/pull/29
      servant-cassava =
        hasklib.overrideCabal
          { editedCabalFile = null; revision = null; }
          hprev.servant-cassava;

      amazonka = hasklib.dontCheck hprev.amazonka;
      amazonka-core = hasklib.dontCheck hprev.amazonka-core;
      amazonka-sso = hasklib.dontCheck hprev.amazonka-sso;
      amazonka-sts = hasklib.dontCheck hprev.amazonka-sts;
    };
    cabal2nixArgsOverrides = args: args // {
      amazonka-sso = ver: { amazonka-test = null; };
      amazonka-sts = ver: { amazonka-test = null; };
    };
    # XXX: Make sure to keep the call to fetchFromGitHub here, since it is
    # testing that fetchCabalFileRevision is able to handle all-cabal-hashes
    # being a directory.  (fetchFromGitHub makes the output derivation a
    # directory.)
    all-cabal-hashes = fetchFromGitHub {
      owner = "commercialhaskell";
      repo = "all-cabal-hashes";
      rev = "80869091dcb9f932c15fe57e30d4d0730c5f87df";
      sha256 = "sha256-LAD3/5qeJWbzfqkcWccMOq0pHBnSkNnvBjWnlLzWFvQ=";
    };
  };
in
stacklock.newPkgSet.my-example-haskell-app
