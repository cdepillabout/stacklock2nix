{ stacklock2nix
, haskell
, cabal-install
, fetchurl
}:

let
  hasklib = haskell.lib.compose;

  stacklock = stacklock2nix {
    stackYaml = ../my-example-haskell-lib-advanced/stack.yaml;
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
    additionalDevShellNativeBuildInputs = stacklockHaskellPkgSet: [
      cabal-install
    ];
    devShellArgsModifier = shellForArgs: shellForArgs // { MY_ENV_VAR = "hello"; };
    # XXX: Make sure to keep the call to fetchurl here, since it is partly
    # testing that fetchCabalFileRevision is able to handle all-cabal-hashes
    # being a tarball. (fetchurl makes the output derivation a tarball.)
    all-cabal-hashes = fetchurl {
      name = "all-cabal-hashes";
      url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/80869091dcb9f932c15fe57e30d4d0730c5f87df.tar.gz";
      sha256 = "sha256-FI1Z1zMPnOXRBAPJiSI5VIyH6JkOuY9Cu1qdq1vwjK0=";
    };
  };
in
[ stacklock.newPkgSet.my-example-haskell-app
  stacklock.newPkgSetDevShell
]
