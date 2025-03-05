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

# Check that our additional passthru values are working. We expect that local
# packages have is-local-pkg set to true, and all other values set to false.
assert stacklock.newPkgSet.my-example-haskell-lib.passthru.stacklock2nix.is-local-pkg;
assert !stacklock.newPkgSet.my-example-haskell-lib.passthru.stacklock2nix.is-extra-dep;
assert !stacklock.newPkgSet.my-example-haskell-lib.passthru.stacklock2nix.is-hackage-dep;
assert !stacklock.newPkgSet.my-example-haskell-lib.passthru.stacklock2nix.is-git-dep;
assert !stacklock.newPkgSet.my-example-haskell-lib.passthru.stacklock2nix.is-url-dep;

# We expect that unagi-streams is Hackage extra-dep.
assert !stacklock.newPkgSet.unagi-streams.passthru.stacklock2nix.is-local-pkg;
assert stacklock.newPkgSet.unagi-streams.passthru.stacklock2nix.is-extra-dep;
assert stacklock.newPkgSet.unagi-streams.passthru.stacklock2nix.is-hackage-dep;
assert !stacklock.newPkgSet.unagi-streams.passthru.stacklock2nix.is-git-dep;
assert !stacklock.newPkgSet.unagi-streams.passthru.stacklock2nix.is-url-dep;

# We expect that servant-cassava is a Git extra-dep.
assert !stacklock.newPkgSet.servant-cassava.passthru.stacklock2nix.is-local-pkg;
assert stacklock.newPkgSet.servant-cassava.passthru.stacklock2nix.is-extra-dep;
assert !stacklock.newPkgSet.servant-cassava.passthru.stacklock2nix.is-hackage-dep;
assert stacklock.newPkgSet.servant-cassava.passthru.stacklock2nix.is-git-dep;
assert !stacklock.newPkgSet.servant-cassava.passthru.stacklock2nix.is-url-dep;

# TODO: Add a similar test for a URL extra-dep.

# We expect that other packages from Stackage are Hackage deps, but not extra deps.
# For example, aeson.
assert !stacklock.newPkgSet.aeson.passthru.stacklock2nix.is-local-pkg;
assert !stacklock.newPkgSet.aeson.passthru.stacklock2nix.is-extra-dep;
assert stacklock.newPkgSet.aeson.passthru.stacklock2nix.is-hackage-dep;
assert !stacklock.newPkgSet.aeson.passthru.stacklock2nix.is-git-dep;
assert !stacklock.newPkgSet.aeson.passthru.stacklock2nix.is-url-dep;

# We expect that packages not included in Stackage, but from Nixpkgs (from Hackage) don't
# have any of our stacklock2nix passthru values.
#
# For example, this uses vault-tool, a random old package unlikely to be added to stackage.
assert ! stacklock.pkgSet.vault-tool.passthru ? stacklock2nix;

stacklock.newPkgSet.my-example-haskell-app
