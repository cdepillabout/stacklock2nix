
{ callPackage
, fetchurl
, haskell
, lib
, runCommand
, stdenv
}@topargs:

{ # The path to your stack.yaml file.
  #
  # Example: `./some/path/to/stack.yaml`
  #
  # If `null`, guess the path of the `stack.yaml` file from the
  # `stackYamlLock` value.  Note that either the `stackYaml` or
  # `stackYamlLock` argument must not be `null`.
  stackYaml ? null
, # The path to your stack.yaml.lock file.
  #
  # Example: `./some/path/to/stack.yaml.lock`
  #
  # If `null`, guess the path of the `stack.yaml.lock` file from the
  # `stackYaml` value.  Note that either the `stackYaml` or
  # `stackYamlLock` argument must not be `null`.
  stackYamlLock ? null
, # A function that can be used to override the values passed to
  # `callHackage` and `callCabal2nix` in the generated overlays.
  # See the comment in `./cabal2nixArgsForPkg.nix` for an explanation
  # of how this can be used.
  cabal2nixArgsOverrides ? (args: args)
, # A base Haskell package set to apply all the stacklock overlays
  # on top of.
  #
  # baseHaskellPkgSet :: HaskellPkgSet
  #
  # If `baseHaskellPkgSet is null, then the output attributes `pkgSet` and `devShell` will
  # also be null.
  baseHaskellPkgSet ? null
, # A Haskell package set overlay to apply last on top of
  # `baseHaskellPkgSet`.
  #
  # additionalHaskellPkgSetOverrides :: HaskellPkgSet -> HaskellPkgSet -> HaskellPkgSet
  #
  # `additionalHaskellPkgSetOverrides` is unused if `baseHaskellPkgSet` is null.
  additionalHaskellPkgSetOverrides ? hfinal: hprev: {}
, # Additional nativeBuildInputs to provide in the devShell.
  #
  # additionalDevShellNativeBuildInputs :: [ Drv ]
  #
  # `additionalDevShellNativeBuildInputs` is unused if `baseHaskellPkgSet` is null.
  additionalDevShellNativeBuildInputs ? (stacklockHaskellPkgSet: [])
, # When creating your own Haskell package set from the stacklock2nix
  # output, you may need to specify a newer all-cabal-hashes.
  #
  # This is necessary when you are using a Stackage snapshot/resolver or
  # `extraDeps` in your `stack.yaml` file that is _newer_ than the
  # `all-cabal-hashes` derivation from the Nixpkgs you are using.
  #
  # If you are using the latest nixpkgs-unstable and an old Stackage
  # resolver, then it is usually not necessary to override
  # `all-cabal-hashes`.
  #
  # If you are using a very recent Stackage resolver and an old Nixpkgs,
  # it is almost always necessary to override `all-cabal-hashes`.
  #
  # all-cabal-hashes :: Drv
  #
  # Example:
  # ```
  # final.fetchurl {
  #   name = "all-cabal-hashes";
  #   url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/9ab160f48cb535719783bc43c0fbf33e6d52fa99.tar.gz";
  #   sha256 = "sha256-QC07T3MEm9LIMRpxIq3Pnqul60r7FpAdope6S62sEX8=";
  # };
  # ```
  #
  # This is not used if `baseHaskellPkgSet` is `null`.
  all-cabal-hashes ? null
, callPackage ? topargs.callPackage
}:

# The stack.yaml path can be computed from the stack.yaml.lock path, or
# vice-versa.  But both can't be null.
assert stackYaml != null || stackYamlLock != null;

let
  stackYamlReal =
    if stackYaml == null then
      builtins.throw
        "ERROR: logic for inferring the stack.yaml path from stack.yaml.lock path has not yet been implemented.  Please send a PR!"
    else
      stackYaml;

  stackYamlLockReal =
    if stackYamlLock == null then
      stackYaml + ".lock"
    else
      stackYamlLock;

  readYAML = callPackage ./read-yaml.nix {};

  # The `stack.yaml` file read in as a Nix value.
  stackYamlParsed = readYAML stackYamlReal;

  # The `stack.yaml.lock` file read in as a Nix value.
  stackYamlLockParsed = readYAML stackYamlLockReal;

  # The URL and sha256 for the snapshot from the `stack.yaml.lock` file.
  #
  # Example:
  # ```
  # { sha256 = "895204e9116cba1f32047525ec5bad7423216587706e5df044c4a7c191a5d8cb";
  #   url = "https://raw.githubusercontent.com/commercialhaskell/stackage-snapshots/master/nightly/2022/10/18.yaml";
  # }
  # ```
  #
  # TODO: This function assumes there is only one resolver snapshot in the
  # stack.yaml.lock file.  Can there be multiple??  How should this be handled?
  snapshotInfo =
    let
      fstSnapshot = builtins.elemAt stackYamlLockParsed.snapshots 0;
    in
    { inherit (fstSnapshot.completed) url sha256; };

  resolverRawYaml = fetchurl { inherit (snapshotInfo) url sha256; };

  # The Nix value for the Stackage snapshot specified in the `stack.yaml.lock`
  # file.
  resolverParsed = readYAML resolverRawYaml;

  fetchCabalFileRevision = callPackage ./fetchCabalFileRevision.nix {};

  # Replace the `.cabal` file in a given Haskell package with the revision
  # specified by the given hash.
  #
  # overrideCabalFileRevision :: String -> String -> String -> HaskellPkgDrv -> HaskellPkgDrv
  #
  # Example:
  # ```
  # overrideCabalFileRevision
  #   "lens"
  #   "5.0.1"
  #   "63ed57e4d54c583ae2873d6892ef690942d90030864d0b772413a1458e98159f"
  #   (callHackage "lens" "5.0.1" {})
  # ```
  #
  # This is helpful because the reivison that `callHackage` picks may be an
  # older revision than specified by the revision hash.  For instance, in the
  # above example, `callHackage` may pick revision 5, while the stackage
  # snapshot uses revision 3.
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

  # Parse a Haskell package Hackage lock into the name, version, and hash info.
  #
  # parseHackageStr :: String -> { name :: String, version :: String, cabalFileHash :: String, cabalFileLen :: String }
  #
  # Example:
  # ```
  # > parseHackageStr "cassava-0.5.3.0@sha256:06e6dbc0f3467f3d9823321171adc08d6edc639491cadb0ad33b2dca1e530d29,6083"
  # { name = "cassava";
  #   version = "0.5.3.0";
  #   cabalFileHash = "06e6dbc0f3467f3d9823321171adc08d6edc639491cadb0ad33b2dca1e530d29";
  #   cabalFileLen = "6083";
  # }
  # ```
  #
  # These hackage lock strings can be found both in the Stackage snapshot, and
  # in the `stack.yaml.lock` file.
  parseHackageStr = hackageStr:
    let
      splitHackageStr = builtins.split "(.*)@sha256:(.*),(.*)" hackageStr;
      hackageStrMatches = builtins.elemAt splitHackageStr 1;
      pkgNameAndVersion = builtins.elemAt hackageStrMatches 0;
    in
    { name = lib.getName pkgNameAndVersion;
      version = lib.getVersion pkgNameAndVersion;
      cabalFileHash = builtins.elemAt hackageStrMatches 1;
      cabalFileLen = builtins.elemAt hackageStrMatches 2;
    };

  # Get additional Cabal2nix arguments for a given package and version
  # from `cabal2nixArgsForPkg`.
  #
  # See `./cabal2nixArgsForPkg.nix` for why this is necessary.
  #
  # getAdditionalCabal2nixArgs :: String -> Maybe String -> AttrSet
  #
  # The `pkgVersion` argument may be `null`.  In this case, we don't
  # know what the version of the package is.  This is mostly only
  # used for local packages.
  #
  # Example:
  # ```
  # > getAdditionalCabal2nixArgs "gi-vte" "3.0.27"
  # { vte_291 = pkgs.vte; }
  # ```
  getAdditionalCabal2nixArgs = pkgName: pkgVersion:
    if builtins.hasAttr pkgName cabal2nixArgsForPkg then
      (builtins.getAttr pkgName cabal2nixArgsForPkg) pkgVersion
    else
      {};

  # Take the Hackage lock info for a given package, and turn it into an actual
  # Haskell package derivation.
  #
  # pkgHackageInfoToNixHaskPkg
  #   :: { name :: String, version :: String, cabalFileHash :: String, cabalFileLen :: String }
  #   -> HaskellPkgSet
  #   -> HaskellPkgDrv
  #
  # Example:
  # ```
  # pkgHackageInfoToNixHaskPkg
  #   { name = "cassava";
  #     version = "0.5.3.0";
  #     cabalFileHash = "06e6dbc0f3467f3d9823321171adc08d6edc639491cadb0ad33b2dca1e530d29";
  #     cabalFileLen = "6083";
  #   }
  #   hfinal
  # ```
  #
  # This takes care of replaces the `.cabal` file from Hackage with the correct revision
  # specified in the Hackage lock info.
  pkgHackageInfoToNixHaskPkg = pkgHackageInfo: hfinal:
    let
      additionalArgs = getAdditionalCabal2nixArgs pkgHackageInfo.name pkgHackageInfo.version;
    in
    overrideCabalFileRevision
      pkgHackageInfo.name
      pkgHackageInfo.version
      pkgHackageInfo.cabalFileHash
      (hfinal.callHackage pkgHackageInfo.name pkgHackageInfo.version additionalArgs);

  # Return a derivation for a Haskell package for the given Haskell package
  # lock info.
  #
  # extraDepCreateNixHaskPkg :: HaskellPkgSet -> HaskellPkgLock -> HaskellPkgDrv
  #
  # where
  #
  # data HaskellPkgLock
  #   = HackageDep { hackage :: String }
  #   | GitDep { name :: String, git :: String, commit :: String, subdir :: String }
  #
  # In `GitDep`, `subdir` can be left out.
  #
  # Example:
  # ```
  # extraDepCreateNixHaskPkg
  #   hfinal
  #   { hackage = "cassava-0.5.3.0@sha256:06e6dbc0f3467f3d9823321171adc08d6edc639491cadb0ad33b2dca1e530d29,6083"; }
  # ```
  #
  # Another Example:
  # ```
  # extraDepCreateNixHaskPkg
  #   hfinal
  #   { name = "servant-client";
  #     git = "https://github.com/haskell-servant/servant";
  #     commit = "1fba9dc6048cea6184964032b861b052cd54878c";
  #     subdir = "servant-client";
  #   }
  # ```
  extraDepCreateNixHaskPkg = hfinal: haskPkgLock:
    let
      extraHackageDep =
        let
          hackageStr = haskPkgLock.hackage;
          pkgHackageInfo = parseHackageStr hackageStr;
        in {
          name = pkgHackageInfo.name;
          value = pkgHackageInfoToNixHaskPkg pkgHackageInfo hfinal;
        };

      extraGitDep =
        let
          srcName = haskPkgLock.name + "-git-repo";
          rawSrc = builtins.fetchGit {
            url = haskPkgLock.git;
            name = srcName;
            rev = haskPkgLock.commit;
          };
          src =
            if haskPkgLock ? "subdir" then
              runCommand (srcName + "-get-subdir-" + haskPkgLock.subdir) {} ''
                cp -r "${rawSrc}/${haskPkgLock.subdir}" "$out"
              ''
            else
              rawSrc;
        in {
          name = haskPkgLock.name;
          value =
            hfinal.callCabal2nix
              haskPkgLock.name
              src
              (getAdditionalCabal2nixArgs haskPkgLock.name haskPkgLock.version);
        };

      extraUrlDep =
        let
          srcName = haskPkgLock.name + "-url";
          rawSrc = builtins.fetchurl {
            name = srcName;
            url = haskPkgLock.url;
            sha256 = haskPkgLock.sha256;
          };
          src =
            runCommand (srcName + "-unpacked" + lib.optionalString (haskPkgLock ? "subdir") ("-get-subdir-" + haskPkgLock.subdir)) {} ''
              # We are assuming the input file is a tarball.
              # TODO: Is it okay to always assume this??
              mkdir ./raw-input-source
              tar -xf "${rawSrc}" -C ./raw-input-source --strip-components=1
              cp -r "./raw-input-source/${haskPkgLock.subdir or ""}" "$out"
            '';
        in {
          name = haskPkgLock.name;
          value =
            hfinal.callCabal2nix
              haskPkgLock.name
              src
              (getAdditionalCabal2nixArgs haskPkgLock.name haskPkgLock.version);
        };
    in
    if haskPkgLock ? "hackage" then
      extraHackageDep
    else if haskPkgLock ? "git" then
      extraGitDep
    else if haskPkgLock ? "url" then
      extraUrlDep
    else
      # Nix can't call builtins.toString on haskPkgLock because it is an attrset
      # (even though it knows how to print it in the repl...) :-\
      builtins.throw "ERROR: unknown haskPkgLock type: ${builtins.toJSON haskPkgLock}";

  # Turn a list of Haskell package locks into an overlay for a Haskell package
  # set.
  #
  # haskPkgLocksToOverlay
  #  :: [ { hackage :: String } ] -> HaskellPkgSet -> HaskellPkgSet -> HaskellPkgSet
  #
  # Example:
  # ```
  # haskPkgLocksToOverlay
  #   [ { hackage = "lens-5.0.1@sha256:63ed57e4d54c583ae2873d6892ef690942d90030864d0b772413a1458e98159f,15544"; }
  #     { hackage = "conduit-1.3.4.3@sha256:c32a5f3ee2daff364de2807afeec45996e5633f9a5010c8504472a930ac7153e,5129"; }
  #   ]
  #   hfinal
  #   hprev
  # ```
  #
  # This roughly returns an overlay that looks like the following:
  # ```
  # { lens = callHackage "lens" "5.0.1" {};
  #   conduit = callHackage "conduit" "5.0.1" {};
  # }
  # ```
  haskPkgLocksToOverlay = haskPkgLocks: hfinal: hprev:
    builtins.listToAttrs (map (extraDepCreateNixHaskPkg hfinal) haskPkgLocks);

  # Similar to `haskPkgLocksToOverlay`, but takes in both Hackage locks and Git
  # locks (so the `HaskellPkgLock` type) from above.
  #
  # extraDepsToOverlay ::
  #   [ HaskellPkgLock ] -> HaskellPkgSet -> HaskellPkgSet -> HaskellPkgSet
  #
  # Example:
  # ```
  # haskPkgLocksToOverlay
  #   [ { hackage = "lens-5.0.1@sha256:63ed57e4d54c583ae2873d6892ef690942d90030864d0b772413a1458e98159f,15544"; }
  #     { name = "servant-client";
  #       git = "https://github.com/haskell-servant/servant";
  #       commit = "1fba9dc6048cea6184964032b861b052cd54878c";
  #       subdir = "servant-client";
  #     }
  #   ]
  #   hfinal
  #   hprev
  # ```
  extraDepsToOverlay = extraDepsPkgs: hfinal: hprev:
    haskPkgLocksToOverlay (map (pkg: pkg.completed) extraDepsPkgs) hfinal hprev;

  # Figure out the name of a local package from the stack.yaml file and its path.
  #
  # mkLocalPkg :: String -> { pkgPath :: Path, pkgName :: String }
  #
  # Example:
  # ```
  # > mkLocalPkg "."
  # { pkgPath = /some/path/to/my-hask-pkg;
  #   pkgName = "hask-pkg"
  # }
  # ```
  #
  # Example:
  # ```
  # > mkLocalPkg "./foobar/my-local-hask-pkg"
  # { pkgPath = /some/path/foobar/my-local-hask-pkg;
  #   pkgName = "my-cool-pkg"
  # }
  # ```
  #
  # Note that the basename of the `pkgPath` may be different than the actual
  # Haskell package name, which is why this function is needed.
  mkLocalPkg = localPkgPathStr:
    let
      # Path to the Haskell package.
      #
      # pkgPath :: Path
      pkgPath =
        lib.cleanSourceWith {
          src =
            # TODO: I imagine it is not okay to just assume this package path is a
            # relative path.
            builtins.path { path = dirOf stackYamlReal + ("/" + localPkgPathStr); };
          # TODO: Create a better filter, plus make it overrideable for end-users.
          filter = path: type: true;
        };

      # This is `pkgPath`, but with everything removed except `.cabal` files
      # and a `package.yaml` file.
      #
      # justCabalFilePath :: Path
      justCabalFilePath = lib.cleanSourceWith {
        src = pkgPath;
        filter = path: type:
          lib.hasSuffix ".cabal" path ||
          baseNameOf path == "package.yaml";
      };

      cabalFileDir = builtins.readDir justCabalFilePath;

      allPkgFiles = builtins.attrNames cabalFileDir;

      # This returns the filename of the ".cabal" file in `allPkgFiles`.
      #
      # cabalFileName :: String
      #
      # Example: `"my-cool-pkg.cabal"`
      cabalFileName =
        lib.findSingle
          (file: lib.hasSuffix ".cabal" file)
          (throw
            ("could not find any .cabal files in package ${localPkgPathStr}.  " +
             "This is unexpected, since we know we should already have at least " +
             "one .cabal file.  all files: ${toString allPkgFiles}"))
          (throw
            ("found multiple .cabal files in package ${localPkgPathStr}, not sure " +
             "how to proceed.  all files: ${toString allPkgFiles}"))
          allPkgFiles;

      # Package name from the package.yaml file.
      #
      # pkgNameFromPackageYaml :: String
      #
      # Example: `"my-cool-pkg"`
      pkgNameFromPackageYaml =
        let
          packageYaml = readYAML (justCabalFilePath + "/package.yaml");
        in
        if packageYaml ? name then
          packageYaml.name
        else
          throw
            ("Could not find read a .name field from the package.yaml file in package ${localPkgPathStr}.  " +
             "This is unexpected.  All package.yaml files should have a top-level .name field. " +
             "package.yaml file: ${builtins.toJSON packageYaml}");

      # Whether or not this package has at least one .cabal file.
      #
      # hasSingleCabalFile :: Bool
      hasSingleCabalFile = lib.any (file: lib.hasSuffix ".cabal" file) allPkgFiles;

      # Whether or not this package has a package.yaml file.
      #
      # hasSingleCabalFile :: Bool
      hasSinglePackageYamlFile = lib.any (file: file == "package.yaml") allPkgFiles;

      # pkgName = lib.removeSuffix ".cabal" cabalFileName;
      pkgName =
        if hasSingleCabalFile then
          lib.removeSuffix ".cabal" cabalFileName
        else if hasSinglePackageYamlFile then
          pkgNameFromPackageYaml
        else
          throw
            ("Could not find any .cabal files or a package.yaml file in package ${localPkgPathStr}.  " +
             "all files: ${toString allPkgFiles}");
    in
    { inherit pkgPath pkgName; };

  # Call `mkLocalPkg` for each local package from the `stack.yaml` file.
  #
  # localPkgs :: [ { pkgPath :: Path, pkgName :: String } ]
  localPkgs = map mkLocalPkg stackYamlParsed.packages;

  suggestedOverlay = callPackage ./suggestedOverlay.nix {};

  # A Haskell package set overlay that adds all the packages from your Stackage
  # snapshot / resolver.
  #
  # stackYamlResolverOverlay :: HaskellPkgSet -> HaskellPkgSet -> HaskellPkgSet
  stackYamlResolverOverlay = haskPkgLocksToOverlay resolverParsed.packages;

  # A Haskell package set overlay that adds all the packages from the `extraDeps`
  # in your `stack.yaml`.
  #
  # stackYamlExtraDepsOverlay :: HaskellPkgSet -> HaskellPkgSet -> HaskellPkgSet
  #
  # If you have `extraDeps` in your `stack.yaml` that look like the following:
  #
  # ```
  # extra-deps:
  #   - unagi-streams-0.2.7
  #   - git: https://github.com/haskell-servant/servant-cassava
  #     commit: f76308b42b9f93a6641c70847cec8ecafbad3abc
  # ```
  #
  # then `stackYamlExtraDepsOverlay` ends up looking roughly like the following:
  #
  # ```
  # hfinal: hprev: {
  #   unagi-streams = hfinal.callHackage "unagi-streams" "0.2.7" {}
  #   servant-cassava = hfinal.callCabal2nix "servant-cassava" (builtins.fetchGit ...) {}
  # }
  # ```
  #
  # In practice it is more complicated, but this is a good first-order approximation.
  stackYamlExtraDepsOverlay = extraDepsToOverlay stackYamlLockParsed.packages;

  # A Haskell package set overlay that adds all the packages from the `extraDeps`
  # in your `stack.yaml`.
  #
  # stackYamlLocalPkgsOverlay :: HaskellPkgSet -> HaskellPkgSet -> HaskellPkgSet
  stackYamlLocalPkgsOverlay = hfinal: hprev:
    let
      localPkgToOverlayAttr = { pkgName, pkgPath }: {
        name = pkgName;
        value =
          let
            additionalArgs = getAdditionalCabal2nixArgs pkgName null;
          in
          hfinal.callCabal2nix pkgName pkgPath additionalArgs;
      };
    in
    builtins.listToAttrs (map localPkgToOverlayAttr localPkgs);

  # A selector for picking only local packages defined in a `stack.yaml` from a Haskell package set.
  #
  # localPkgs :: HaskellPkgSet -> [ HaskellPkgDrv ]
  #
  # Example: `my-stacklock-pkg-set.ghcWithPackages my-stacklock.localPkgsSelector`
  #
  # Another Example:
  # ```
  # my-stacklock-pkg-set.shellFor {
  #   packages = p: my-stacklock-pkg-set.localPkgsSelector p;
  #   withHoogle = true;
  #   buildInputs = [ pkgs.python pkgs.cabal-install ];
  # }
  # ```
  localPkgsSelector = haskPkgs:
    map (localPkg: haskPkgs.${localPkg.pkgName}) localPkgs;

  # A single overlay that combines the following overlays:
  # - the packages from the stack.yaml resolver
  # - the `extraDeps` from your stack.yaml file
  # - the local `packages` from your stack.yaml file
  # - a set of suggested overrides from stacklock2nix
  #
  # combinedOverlay :: HaskellPkgSet -> HaskellPkgSet -> HaskellPkgSet
  combinedOverlay =
    lib.composeManyExtensions [
      stackYamlResolverOverlay
      stackYamlExtraDepsOverlay
      stackYamlLocalPkgsOverlay
      suggestedOverlay
    ];

  # `pkgSet` is the Nixpkgs Haskell package set passed-in as
  # `baseHaskellPkgSet`, but overridden with `combinedOverlay` and
  # `additionalHaskellPkgSetOverrides`.
  #
  # pkgSet :: HaskellPkgSet
  #
  # `pkgSet` will contain local packages.  For instance, if you have a local
  # package called `my-haskell-pkg`:
  #
  # Example: `pkgSet.my-haskell-pkg`
  #
  # `pkgSet` will also contain packages in your stack.yaml resolver. For
  # instance:
  #
  # Example: `pkgSet.lens`
  #
  # `pkgSet` will also contain packages from the underlying Haskell package
  # set.  For instance, `termonad` is not available in Stackage, but you can
  # access it like the following because it is available in the main Nixpkgs
  # Haskell package set.
  #
  # Example: `pkgSet.termonad`
  pkgSet =
    if baseHaskellPkgSet == null then
      null
    else
      baseHaskellPkgSet.override (oldAttrs: {
        overrides = lib.composeManyExtensions [
          # Make sure not to lose any old overrides.
          (oldAttrs.overrides or (_: _: {}))
          combinedOverlay
          additionalHaskellPkgSetOverrides
        ];
      } //
      lib.optionalAttrs (all-cabal-hashes != null) {
        inherit all-cabal-hashes;
      });

  # A development shell created by passing all your local packages (from
  # `localPkgsSelector`) to `pkgSet.shellFor`.
  #
  # devShell :: Drv
  #
  # Note that this derivation is specifically meant to be passed to `nix
  # develop` or `nix-shell`.
  devShell =
    if pkgSet == null then
      null
    else
      pkgSet.shellFor {
        packages = localPkgsSelector;
        nativeBuildInputs = additionalDevShellNativeBuildInputs pkgSet;
      };

in

{ inherit
    stackYamlResolverOverlay
    stackYamlExtraDepsOverlay
    stackYamlLocalPkgsOverlay
    suggestedOverlay
    combinedOverlay
    localPkgsSelector
    pkgSet
    devShell
    ;

  # These are a bunch of internal attributes, used for testing.
  # End-users should not rely on these.  Treat these similar to
  # `.Internal` modules in Haskell.
  _internal = {
    inherit
      snapshotInfo
      resolverParsed
      ;
  };
}
