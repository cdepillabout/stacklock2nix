
# This script gets the following arguments:
#
# $haskPkgName:  The name of the haskell package to look for.
#
# $haskPkgVer:  The version of the haskell package to look for.
#
# $haskPkgHash:  The hash of the specific revision of the .cabal file to look for.
#
# $all_cabal_hashes:  A path to the all-cabal-hashes derivation.

source $stdenv/setup

set -euo pipefail

# Try to extract the .cabal file for the given revision
#
# Arguments:
#   (none)
#
# Returns:
#   0:         If the given .cabal revision was found in the tarball.
#   non-zero:  If the given .cabal revision was not found in the tarball.
#
# Side effects:
#   Creates the file "./${haskPkgName}.cabal" if the given revision was found
#   in the tarball.
find_cabal_file_in_all_cabal_hashes () {
  if [ -d "${all_cabal_hashes}" ]; then
    # all-cabal-hashes is a directory.  Directly reference the .cabal file need.
    cp "${all_cabal_hashes}/${haskPkgName}/${haskPkgVer}/${haskPkgName}.cabal" ./
  else
    # all-cabal-hashes is a tarball.  Try to pull out the .cabal file we need.
    tar --wildcards --extract --file "${all_cabal_hashes}" \
        --gzip --strip-components=3 "*/${haskPkgName}/${haskPkgVer}/${haskPkgName}.cabal"
  fi
}

# Test the hash of the file "./${haskPkgName}.cabal" to see if it is equal to
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
  fileSha=$(sha256sum "${haskPkgName}.cabal" | cut -d' ' -f1)
  [[ "$fileSha" == "${haskPkgHash}" ]]
}

# Copies the "./${haskPkgName}.cabal" file to "$out" and exits.
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
  cp "${haskPkgName}.cabal" "$out"
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
if find_cabal_file_in_all_cabal_hashes; then
  # We successfully extracted the tar file, now we see if it has the
  # correct hash.
  if test_hash ; then
    # The file has the correct hash
    copy_cabal_file_to_out_and_exit
  fi

  # Remove the .cabal file because the hash doesn't match.
  rm "${haskPkgName}.cabal"
fi

echo "Couldn't find .cabal file revision for ${haskPkgName}-${haskPkgVer} in all-cabal-hashes.  Fetching from Hackage..."

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
  revisionUrl="https://hackage.haskell.org/package/${haskPkgName}-${haskPkgVer}/revision/${hackageRevisionId}.cabal"
  "${curl[@]}" -L "$revisionUrl" > "${haskPkgName}.cabal"
  if test_hash ; then
    copy_cabal_file_to_out_and_exit
  fi
  rm "${haskPkgName}.cabal"
done

echo "ERROR: Could not find cabal file revision for ${haskPkgName}-${haskPkgVer} with hash ${haskPkgHash} in Hackage"
exit 1
