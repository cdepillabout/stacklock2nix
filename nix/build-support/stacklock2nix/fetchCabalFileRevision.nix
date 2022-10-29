
{ curl, coreutils, lib, stdenvNoCC, writeShellScript }:

{ name
, version
, hash
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
