
{ all-cabal-hashes, curl, coreutils, lib, stdenvNoCC, writeShellScript }:

# Fetch the revision of a `.cabal` file for a given Haskell package from
# Hackage.

{ # Haskell package.
  #
  # name :: String
  #
  # Example: `"lens"`
  name
, # Version
  #
  # version :: String
  #
  # Example: `"5.0.1"`
  version
, # Hash of the revised `.cabal` file from Hackage.
  #
  # hash :: String
  #
  # Example: "63ed57e4d54c583ae2873d6892ef690942d90030864d0b772413a1458e98159f"
  hash
}:

stdenvNoCC.mkDerivation {

  name = "${name}-${version}-cabal-file";

  outputHashAlgo = "sha256";
  outputHash = hash;
  outputHashMode = "flat";

  nativeBuildInputs = [
    coreutils # TODO: needed for seq.  remove this dependency.
    curl
  ];

  nixpkgsVersion = lib.trivial.release;

  builder = ./fetchCabalFileRevisionBuilder.sh;

  # Arguments used in builder script.

  haskPkgName = name;
  haskPkgVer = version;
  haskPkgHash = hash;
  all_cabal_hashes = all-cabal-hashes;
}
