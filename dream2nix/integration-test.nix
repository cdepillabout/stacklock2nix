{
  lib,
  pkgs,
  ...
}: let
  l = lib // builtins;

  testScript = pkgs.writeScript "test-dream2nix-integration" ''
    set -Eeuo pipefail
    PATH="${lib.makeBinPath [
      pkgs.coreutils
      pkgs.git
      pkgs.nix
    ]}"

    set -x

    example="${./example}"
    args="--update-input dream2nix --override-input stacklock2nix ${../.} --no-write-lock-file --allow-import-from-derivation"

    # test if nix can render the flake
    nix flake show $args $example

    # resolve default package to dream-lock.json
    # This will verify the dream-lock against the jsonschema
    nix run $args $example#default.resolve

    # build default package from dream-lock.json without IFD
    nix build $args --no-allow-import-from-derivation $example#default

    # build default package on-the-fly
    rm -rf ./dream2nix-packages
    nix build $args $example#default
  '';

  test-app.type = "app";
  test-app.program = toString testScript;
in
  test-app
