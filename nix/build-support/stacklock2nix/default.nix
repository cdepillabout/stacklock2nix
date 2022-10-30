
{ callPackage, fetchurl, lib, haskell, stdenv, readYAML, remarshal, runCommand }:

# This is the main purescript2nix function.  See ../../overlay.nix for an
# example of how this can be used.

{ # Package name.  Should be a string.
  #
  # Example: "aeson"
  pname
, # Package version.  Should be a string.
  #
  # Example: "1.2.3.4"
  version ? ""
, stack-yaml
, stack-yaml-lock
}:

let

  stackYamlLockParsed = readYAML stack-yaml-lock;

  snapshotInfo =
    let
      fstSnapshot = builtins.elemAt stackYamlLockParsed.snapshots 0;
    in
    { inherit (fstSnapshot.completed) url sha256; };

  resolverRawYaml = fetchurl {
    inherit (snapshotInfo) url sha256;
  };

  resolverParsed = readYAML resolverRawYaml;

  fetchCabalFileRevision = callPackage ./fetchCabalFileRevision.nix {};

  overrideCabalFileRevision = pkgName: pkgVersion: pkgCabalFileHash: haskPkgDrv:
    let
      cabalFile = fetchCabalFileRevision {
        name = pkgName;
        version = pkgVersion;
        hash = pkgCabalFileHash;
      };
    in
    haskell.lib.compose.overrideCabal
      (oldAttrs: {
        editedCabalFile = null;
        revision = null;
        prePatch = ''
          echo "Replace Cabal file with edited version from ${cabalFile}."
          cp "${cabalFile}" "${oldAttrs.pname}.cabal"
        '' + (oldAttrs.prePatch or "");
      })
      haskPkgDrv;

  resolverPackagesToOverlay = resolverPackages: hfinal: hprev:
    let
      resolverPkgToNixHaskPkg = resolverPkg:
        let
          # example: "cassava-0.5.3.0@sha256:06e6dbc0f3467f3d9823321171adc08d6edc639491cadb0ad33b2dca1e530d29,6083"
          hackageStr = resolverPkg.hackage;
          splitHackageStr = builtins.split "(.*)@sha256:(.*),(.*)" hackageStr;
          hackageStrMatches = builtins.elemAt splitHackageStr 1;
          pkgNameAndVersion = builtins.elemAt hackageStrMatches 0;
          pkgName = lib.getName pkgNameAndVersion;
          pkgVersion = lib.getVersion pkgNameAndVersion;
          pkgCabalFileHash = builtins.elemAt hackageStrMatches 1;
          pkgCabalFileLen = builtins.elemAt hackageStrMatches 2;
          # TODO: My idea for a hacky cabal file fetcher:
          # just try downloading revisions from 0, and look for the first one
          # that has a matching hash.
          additionalArgs = if pkgName == "splitmix" then { testu01 = null; } else {};
        in
        {
          name = pkgName;
          value =
            overrideCabalFileRevision pkgName pkgVersion pkgCabalFileHash (hfinal.callHackage pkgName pkgVersion additionalArgs);
        };
    in
    builtins.listToAttrs (map resolverPkgToNixHaskPkg resolverPackages);

  additionalOverrides = hfinal: hprev: {
    doctest = haskell.lib.dontCheck hprev.doctest;
    tasty = haskell.lib.dontCheck hprev.tasty;
    syb = haskell.lib.dontCheck hprev.syb;
    HUnit = haskell.lib.dontCheck hprev.HUnit;
    hspec = haskell.lib.dontCheck hprev.hspec;
    hspec-core = haskell.lib.dontCheck hprev.hspec-core;
    nanospec = haskell.lib.dontCheck hprev.nanospec;
    test-framework = haskell.lib.dontCheck hprev.test-framework;
    smallcheck = haskell.lib.dontCheck hprev.smallcheck;
    async = haskell.lib.dontCheck hprev.async;
    ansi-terminal = haskell.lib.dontCheck hprev.ansi-terminal;
    colour = haskell.lib.dontCheck hprev.colour;
    clock = haskell.lib.dontCheck hprev.clock;
    hashable = haskell.lib.dontCheck hprev.hashable;
    logict = haskell.lib.dontCheck hprev.logict;
    random = haskell.lib.dontCheck hprev.random;
    base-orphans = haskell.lib.dontCheck hprev.base-orphans;
    mockery = haskell.lib.dontCheck hprev.mockery;
    logging-facade = haskell.lib.dontCheck hprev.logging-facade;
    splitmix =
      haskell.lib.dontCheck
        (haskell.lib.compose.overrideCabal
          (_: {
            testHaskellDepends = [];
            testSystemDepends = [];
          })
          (hprev.splitmix.override {
            testu01 = null;
          })
        );
  };

  haskPkgs = haskell.packages.ghc902.override (oldAttrs: {
    overrides = lib.composeManyExtensions [
      (oldAttrs.overrides or (_: _: {}))
      (resolverPackagesToOverlay resolverParsed.packages)
      additionalOverrides
    ];
    all-cabal-hashes = fetchurl {
      name = "all-cabal-hashes";
      url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/9ab160f48cb535719783bc43c0fbf33e6d52fa99.tar.gz";
      sha256 = "sha256-QC07T3MEm9LIMRpxIq3Pnqul60r7FpAdope6S62sEX8=";
    };
  });

in

# stackYamlLockParsed
# snapshotInfo
# resolverRawYaml
# resolverParsed
haskPkgs
# fetchCabalFileRevision
