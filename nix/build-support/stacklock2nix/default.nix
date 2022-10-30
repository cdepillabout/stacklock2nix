
{ callPackage
, fetchurl
, haskell
, lib
, pkgs
, runCommand
, stdenv
}:

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
, cabal2nixArgsOverrides ? (args: args)
}:

let

  readYAML = callPackage ./read-yaml.nix {};

  stackYamlParsed = readYAML stack-yaml;

  stackYamlLockParsed = readYAML stack-yaml-lock;

  snapshotInfo =
    let
      fstSnapshot = builtins.elemAt stackYamlLockParsed.snapshots 0;
    in
    { inherit (fstSnapshot.completed) url sha256; };

  resolverRawYaml = fetchurl { inherit (snapshotInfo) url sha256; };

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

  cabal2nixArgsForPkg = callPackage ./cabal2nixArgsForPkg.nix {
    inherit cabal2nixArgsOverrides;
  };

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
            if builtins.hasAttr pkgName cabal2nixArgsForPkg then
              (builtins.getAttr pkgName cabal2nixArgsForPkg) pkgVersion
            else {};
        in
        {
          name = pkgName;
          value =
            overrideCabalFileRevision
              pkgName
              pkgVersion
              pkgCabalFileHash
              (hfinal.callHackage pkgName pkgVersion additionalArgs);
        };
    in
    builtins.listToAttrs (map resolverPkgToNixHaskPkg resolverPackages);

  mkLocalPkg = localPkgPathStr:
    let
      pkgPath =
        lib.cleanSourceWith {
          src =
            # TODO: I imagine it is not okay to just assume this package path is a
            # relative path.
            builtins.path { path = dirOf stack-yaml + ("/" + localPkgPathStr); };
          # TODO: Create a better filter, plus make it overrideable for end-users.
          filter = path: type: true;
        };
      justCabalFilePath = lib.cleanSourceWith {
        src = pkgPath;
        filter = path: type:
          lib.hasSuffix ".cabal" path ||
          baseNameOf path == "package.yaml";
      };
      cabalFileDir = builtins.readDir justCabalFilePath;
      allPkgFiles = builtins.attrNames cabalFileDir;
      cabalFileName =
        lib.findSingle
          (file: lib.hasSuffix ".cabal" file)
          (throw "could not find any .cabal files in package ${localPkgPathStr}.  all files: ${toString allPkgFiles}")
          (throw "found multiple .cabal files in package ${localPkgPathStr}, not sure how to proceed.  all files: ${toString allPkgFiles}")
          allPkgFiles;
      pkgName = lib.removeSuffix ".cabal" cabalFileName;
    in
    { inherit pkgPath pkgName; };

  localPkgs = map mkLocalPkg stackYamlParsed.packages;

  localPkgsOverlay = hfinal: hprev:
    let
      localPkgToOverlayAttr = { pkgName, pkgPath }: {
        name = pkgName;
        value = hfinal.callCabal2nix pkgName pkgPath {};
      };
    in
    builtins.listToAttrs (map localPkgToOverlayAttr localPkgs);

  additionalOverrides = hfinal: hprev: with haskell.lib.compose; {
    HUnit = dontCheck hprev.HUnit;
    ansi-terminal = dontCheck hprev.ansi-terminal;
    async = dontCheck hprev.async;
    base-orphans = dontCheck hprev.base-orphans;
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
    hspec = dontCheck hprev.hspec;
    hspec-core = dontCheck hprev.hspec-core;
    logging-facade = dontCheck hprev.logging-facade;
    logict = dontCheck hprev.logict;
    mockery = dontCheck hprev.mockery;
    nanospec = dontCheck hprev.nanospec;
    random = dontCheck hprev.random;
    # Disabling doctests.
    regex-tdfa = overrideCabal { testTarget = "regex-tdfa-unittest"; } hprev.regex-tdfa;
    smallcheck = dontCheck hprev.smallcheck;
    splitmix = dontCheck hprev.splitmix;
    syb = dontCheck hprev.syb;
    tasty = dontCheck hprev.tasty;
    tasty-expected-failure = dontCheck hprev.tasty-expected-failure;
    test-framework = dontCheck hprev.test-framework;
  };

  haskPkgs = haskell.packages.ghc924.override (oldAttrs: {
    overrides = lib.composeManyExtensions [
      (oldAttrs.overrides or (_: _: {}))
      (resolverPackagesToOverlay resolverParsed.packages)
      localPkgsOverlay
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
# mkLocalPkg
# localPkgs
