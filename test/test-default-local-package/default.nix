
{ stacklock2nix
, haskell
, cabal-install
, fetchFromGitHub
}:

let
  hasklib = haskell.lib.compose;

  stacklock = stacklock2nix {
    stackYaml = ./stack.yaml;
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
    additionalDevShellNativeBuildInputs = stacklockHaskellPkgSet: [
      cabal-install
    ];
    all-cabal-hashes = fetchFromGitHub {
      owner = "commercialhaskell";
      repo = "all-cabal-hashes";
      rev = "578b09df5072f21768cfe13edfc3e4c3e41428fc";
      sha256 = "sha256-fmf4LukOJ2c0bCmNfuN+n2R6bxGhJqag9CBvZQEl3kA=";
    };
  };
in

let
  # A list of all the names of the local packages.
  localPkgNames = builtins.attrNames (stacklock.stackYamlLocalPkgsOverlay null null);
in

# The local packages overlay should contain a single local package.
assert  builtins.length localPkgNames == 1;

let
  localPkgName = builtins.head localPkgNames;
in

# The name of the local package should be read correctly from the .cabal file.
assert localPkgName == "my-cool-package-foobar";

[ # We should be able to build the local package:
  stacklock.pkgSet.my-cool-package-foobar

  # We should also be able to build other packages from stack.yaml.
  # Two random packages to check:
  stacklock.pkgSet.amazonka-core
  stacklock.newPkgSet.lens

  # Also be able to build the devshell:
  stacklock.newPkgSetDevShell
]
