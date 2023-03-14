
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

  builder = writeShellScript "fetchCabalFileRevisionBuilder.sh" ''
    source $stdenv/setup

    set -euo pipefail


    # Try to extract the .cabal file for the given revision
    #
    # Arguments:
    #   $1: The revision ID to use.  Ex. "2"
    #
    # Returns:
    #   0:         If the given .cabal revision was found in the tarball.
    #   non-zero:  If the given .cabal revision was not found in the tarball.
    #
    # Side effects:
    #   Creates the file "./${name}.cabal" if the given revision was found
    #   in the tarball.
    find_cabal_file_in_tar () {
      revId=$1
      tar --wildcards --extract --occurrence=$revId \
        --file '${all-cabal-hashes}' --gzip --strip-components=3 \
        '*/${name}/${version}/${name}.cabal'
    }

    # Test the hash of the file "./${name}.cabal" to see if it is equal to
    # the passed-in hash.
    #
    # Arguments:
    #   (none)
    #
    # Returns:
    #   0:         If the hashes are equal.
    #   non-zero:  If the hashes are not equal
    #
    # Side effects:
    #   (none)
    test_hash () {
      fileSha=$(sha256sum "${name}.cabal" | cut -d' ' -f1)
      [[ "$fileSha" == "${hash}" ]]
    }

    # Copies the "./${name}.cabal" file to "$out" and exits.
    #
    # Arguments:
    #   (none)
    #
    # Returns:
    #   (none)
    #
    # Side effects:
    #   Exits
    copy_cabal_file_to_out_and_exit () {
      cp "${name}.cabal" "$out"
      exit 0
    }

    # TODO: check if all-cabal-hashes is a directory, and don't do this in that case


    # This will look for the given revision of the cabal file in
    # all-cabal-hashes. This will loop while incrementing the revision ID to
    # look for.
    #
    # If a .cabal file is found with the correct hash, it is used.  Otherwise,
    # this loop ends when there are no more revision IDs available for the
    # package/version.
    #
    # TODO: It turns out that all-cabal-hashes only has a SINGLE cabal file,
    # it doesn't have cabal files for each revision, unfortunately.  This
    # loop should really be simplified (or we should setup a repository
    # like all-cabal-hashes that does actually contain all cabal files for
    # all revisions, and just use that).
    hackagePkgRevId=0
    while find_cabal_file_in_tar $hackagePkgRevId; do
      # We successfully extracted the tar file, now we see if it has the
      # correct hash.
      if test_hash ; then
        # The file has the correct hash
        copy_cabal_file_to_out_and_exit
      fi

      # increment the hackage package revision ID
      ((hackagePkgRevId+=1))

      # Remove the .cabal file because the hash doesn't match.
      rm "${name}.cabal"
    done

    echo "Couldn't find .cabal file revision for ${name}-${version} in all-cabal-hashes.  Fetching from Hackage..."

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

    for hackageRevisionId in $(seq 0 20) ; do
      echo "$hackageRevisionId"
      revisionUrl="https://hackage.haskell.org/package/${name}-${version}/revision/''${hackageRevisionId}.cabal"
      "''${curl[@]}" -L "$revisionUrl" > "${name}.cabal"
      if test_hash ; then
        copy_cabal_file_to_out_and_exit
      fi
      rm "${name}.cabal"
    done

    echo "ERROR: Could not find cabal file revision for ${name}-${version} with hash ${hash} in Hackage"
    exit 1
  '';
}
