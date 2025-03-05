{ lib
, stacklock2nix
, haskell
, cabal-install
, fetchFromGitHub
}:

let
  hasklib = haskell.lib.compose;

  stacklock = stacklock2nix {
    stackYaml = ../my-example-haskell-lib-easy/stack.yaml;
    baseHaskellPkgSet = haskell.packages.ghc984;
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
      rev = "578b09df5072f21768cfe13edfc3e4c3e41428fc";
      sha256 = "sha256-fmf4LukOJ2c0bCmNfuN+n2R6bxGhJqag9CBvZQEl3kA=";
    };
    # This is an example of using the `locakPkgFilter` argument in order to
    # filter out extra files that aren't needed.
    #
    # TODO: This should also actually test that the resulting derivation doesn't
    # depend on `extra-file` existing or not existing (since it should be filtered
    # out).
    localPkgFilter = defaultLocalPkgFilter: pkgName: path: type:
      # This filters out the file called `extra-file`
      if pkgName == "my-example-haskell-lib" && baseNameOf path == "extra-file" then
        false
      else
        defaultLocalPkgFilter path type;
  };
in
stacklock.newPkgSet.my-example-haskell-app
