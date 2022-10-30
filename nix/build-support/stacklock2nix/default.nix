
{ callPackage, fetchurl, lib, haskell, stdenv, readYAML, remarshal, runCommand, pkgs }:

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
          echo "stacklock2nix: replace Cabal file with revision from ${cabalFile}."
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
          additionalArgs =
            if pkgName == "gi-gmodule" then { gmodule = null; } else
            if pkgName == "gi-harfbuzz" then { harfbuzz-gobject = null; } else
            if pkgName == "gi-vte" then { vte_291 = pkgs.vte; } else
            if pkgName == "splitmix" then { testu01 = null; } else
            if pkgName == "termonad" then { vte_291 = pkgs.vte; } else
            if pkgName == "zlib" then { zlib = pkgs.zlib; } else
            {};
        in
        {
          name = pkgName;
          value =
            overrideCabalFileRevision pkgName pkgVersion pkgCabalFileHash (hfinal.callHackage pkgName pkgVersion additionalArgs);
        };
    in
    builtins.listToAttrs (map resolverPkgToNixHaskPkg resolverPackages);

  additionalOverrides = hfinal: hprev: {
    HUnit = haskell.lib.dontCheck hprev.HUnit;
    ansi-terminal = haskell.lib.dontCheck hprev.ansi-terminal;
    async = haskell.lib.dontCheck hprev.async;
    base-orphans = haskell.lib.dontCheck hprev.base-orphans;
    clock = haskell.lib.dontCheck hprev.clock;
    colour = haskell.lib.dontCheck hprev.colour;
    doctest = haskell.lib.dontCheck hprev.doctest;
    hashable = haskell.lib.dontCheck hprev.hashable;
    hspec = haskell.lib.dontCheck hprev.hspec;
    hspec-core = haskell.lib.dontCheck hprev.hspec-core;
    logging-facade = haskell.lib.dontCheck hprev.logging-facade;
    logict = haskell.lib.dontCheck hprev.logict;
    mockery = haskell.lib.dontCheck hprev.mockery;
    nanospec = haskell.lib.dontCheck hprev.nanospec;
    random = haskell.lib.dontCheck hprev.random;
    smallcheck = haskell.lib.dontCheck hprev.smallcheck;
    splitmix = haskell.lib.dontCheck hprev.splitmix;
    syb = haskell.lib.dontCheck hprev.syb;
    tasty = haskell.lib.dontCheck hprev.tasty;
    tasty-expected-failure = haskell.lib.dontCheck hprev.tasty-expected-failure;
    test-framework = haskell.lib.dontCheck hprev.test-framework;
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
