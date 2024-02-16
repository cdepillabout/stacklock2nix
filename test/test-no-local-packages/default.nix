
{ stacklock2nix
, haskell
, cabal-install
, fetchFromGitHub
}:

let
  hasklib = haskell.lib.compose;

  stacklock = stacklock2nix {
    stackYaml = ./stack.yaml;
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
    all-cabal-hashes = fetchFromGitHub {
      owner = "commercialhaskell";
      repo = "all-cabal-hashes";
      rev = "80869091dcb9f932c15fe57e30d4d0730c5f87df";
      sha256 = "sha256-LAD3/5qeJWbzfqkcWccMOq0pHBnSkNnvBjWnlLzWFvQ=";
    };
  };
in

# The local packages overlay should not contain any packages, so it should just
# be an empty attrset.
assert stacklock.stackYamlLocalPkgsOverlay null null == {};


# The localPkgsSelector function shouldn't contain any packages, and so should
# return an empty list.
assert stacklock.localPkgsSelector null == [];

[ # The devShell shouldn't really contain anything, but it should at least be buildable.
  stacklock.devShell

  # Same with the newPkgSetDevShell
  stacklock.newPkgSetDevShell

  # The package set should contain all the packages from our stack.yaml
  # resolver, as well as everything added as extra-deps.
  # Two random examples:
  stacklock.pkgSet.amazonka-core
  stacklock.newPkgSet.lens
]