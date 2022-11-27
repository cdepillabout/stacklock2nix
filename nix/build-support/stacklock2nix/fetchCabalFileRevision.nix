
{ curl, coreutils, lib, stdenvNoCC, writeShellScript }:

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

  builder = writeShellScript "fetchCabalFileRevisionBuilder.sh" ''
    source $stdenv/setup

    set -euo pipefail

    curlVersion=$(curl -V | head -1 | cut -d' ' -f2)

    curl=(
        curl
        --location
        --max-redirs 20
        --retry 3
        --disable-epsv
        --cookie-jar cookies
        --user-agent "curl/$curlVersion Nixpkgs/$nixpkgsVersion"
        --insecure
    )

    # This is pretty dumb.
    #
    # The snapshot/resolver specified in a stack.yaml contains the hash of the
    # revised `.cabal` file that should be used for each package, but it
    # doesn't contain the _number_ of the revision the hash belongs to.
    # Unfortunately, Hackage only provides a way to download a `.cabal` file
    # based on a revision number (not a revised `.cabal` file given a hash).
    #
    # So the following code attempts to download each revised `.cabal` file for
    # a version of a package, one-by-one, hash it, and check whether the hash
    # matches the hash we are looking for.  If it does, we're good to go.
    #
    # In theory, this should always succeed, since the Stackage snapshots
    # will only reference `.cabal` file revisions from Hackage.  In practice,
    # I've never seen this fail to find a revision, but who knows what weird
    # things go on in the edge-cases of Hackage.

    found="no"

    for hackageRevisionId in $(seq 0 20) ; do
      echo "$hackageRevisionId"
      revisionUrl="https://hackage.haskell.org/package/${name}-${version}/revision/''${hackageRevisionId}.cabal"
      "''${curl[@]}" -L "$revisionUrl" > "${name}.cabal"
      fileSha=$(sha256sum "${name}.cabal" | cut -d' ' -f1)
      if [[ "$fileSha" == "${hash}" ]]; then
        found=yes
        cp "${name}.cabal" "$out"
        break
      fi
      rm "${name}.cabal"
    done

    if [[ "$found" == "no" ]]; then
      echo "ERROR: Could not find cabal file revision for ${name}-${version} with hash ${hash}."
      exit 1
    fi
  '';
}
