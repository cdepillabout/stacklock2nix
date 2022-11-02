
{ callPackage
, fetchurl
, haskell
, lib
, pkgs
, runCommand
, stdenv
}:

{ # The path to your stack.yaml file.
  #
  # Example: `./some/path/to/stack.yaml`
  #
  # If `null`, guess the path of the `stack.yaml` file from the
  # `stack-yaml-lock` value.
  stack-yaml ? null
, # The path to your stack.yaml.lock file.
  #
  # Example: `./some/path/to/stack.yaml.lock`
  #
  # If `null`, guess the path of the `stack.yaml.lock` file from the
  # `stack-yaml` value.
  stack-yaml-lock ? null
, # A function that can be used to override the values passed to
  # `callHackage` and `callCabal2nix` in the generated overlays.
  # See the comment in `./cabal2nixArgsForPkg.nix` for an explanation
  # of what this is.
  cabal2nixArgsOverrides ? (args: args)
}:

# The stack.yaml path can be computed from the stack.yaml.lock path, or
# vice-versa.  But both can't be null.
assert stack-yaml != null || stack-yaml-lock != null;

let
  stack-yaml-real =
    if stack-yaml == null then
      builtins.throw
        "ERROR: logic for inferring the stack.yaml path from stack.yaml.lock path has not yet been implemented.  Please send a PR!"
    else
      stack-yaml;

  stack-yaml-lock-real =
    if stack-yaml-lock == null then
      stack-yaml + ".lock"
    else
      stack-yaml-lock;

  readYAML = callPackage ./read-yaml.nix {};

  # The `stack.yaml` file read in as a Nix value.
  stackYamlParsed = readYAML stack-yaml-real;

  # The `stack.yaml.lock` file read in as a Nix value.
  stackYamlLockParsed = readYAML stack-yaml-lock-real;

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

  # example: "cassava-0.5.3.0@sha256:06e6dbc0f3467f3d9823321171adc08d6edc639491cadb0ad33b2dca1e530d29,6083"
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

  getAdditionalCabal2nixArgs = pkgName: pkgVersion:
    if builtins.hasAttr pkgName cabal2nixArgsForPkg then
      (builtins.getAttr pkgName cabal2nixArgsForPkg) pkgVersion
    else
      {};

  pkgHackageInfoToNixHaskPkg = pkgHackageInfo: hfinal:
    let
      additionalArgs = getAdditionalCabal2nixArgs pkgHackageInfo.name pkgHackageInfo.version;
    in
    overrideCabalFileRevision
      pkgHackageInfo.name
      pkgHackageInfo.version
      pkgHackageInfo.cabalFileHash
      (hfinal.callHackage pkgHackageInfo.name pkgHackageInfo.version additionalArgs);

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
    in
    if haskPkgLock ? "hackage" then
      extraHackageDep
    else if haskPkgLock ? "git" then
      extraGitDep
    else
      builtins.throw "ERROR: unknown haskPkgLock type: ${builtins.toString haskPkgLock}";

  haskPkgLocksToOverlay = haskPkgLocks: hfinal: hprev:
    builtins.listToAttrs (map (extraDepCreateNixHaskPkg hfinal) haskPkgLocks);

  extraDepsToOverlay = extraDepsPkgs: hfinal: hprev:
    haskPkgLocksToOverlay (map (pkg: pkg.completed) extraDepsPkgs) hfinal hprev;

  mkLocalPkg = localPkgPathStr:
    let
      pkgPath =
        lib.cleanSourceWith {
          src =
            # TODO: I imagine it is not okay to just assume this package path is a
            # relative path.
            builtins.path { path = dirOf stack-yaml-real + ("/" + localPkgPathStr); };
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

  suggestedOverlay = callPackage ./suggestedOverlay.nix {};

  stackYamlResolverOverlay = haskPkgLocksToOverlay resolverParsed.packages;

  stackYamlExtraDepsOverlay = extraDepsToOverlay stackYamlLockParsed.packages;

  stackYamlLocalPkgsOverlay = hfinal: hprev:
    let
      localPkgToOverlayAttr = { pkgName, pkgPath }: {
        name = pkgName;
        value = hfinal.callCabal2nix pkgName pkgPath {};
      };
    in
    builtins.listToAttrs (map localPkgToOverlayAttr localPkgs);

  localPkgsSelector = haskPkgs:
    map (localPkg: haskPkgs.${localPkg.pkgName}) localPkgs;
in

{ inherit
    stackYamlResolverOverlay
    stackYamlExtraDepsOverlay
    stackYamlLocalPkgsOverlay
    suggestedOverlay
    localPkgsSelector
    ;

  # This is a bunch of internal attributes, used for testing.
  # End-users should not rely on these.  Treat these similar to
  # `.Internal` modules in Haskell.
  _internal = {
    inherit
      snapshotInfo
      ;
  };
}
