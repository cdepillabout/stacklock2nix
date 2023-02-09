
{...}:

let
  flake-lock = builtins.fromJSON (builtins.readFile ../my-example-haskell-lib-advanced/flake.lock);

  # Use the Nixpkgs that the my-example-haskell-lib-advanced is pinned to.
  nixpkgs-src = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${flake-lock.nodes.nixpkgs.locked.rev}.tar.gz";
    sha256 = flake-lock.nodes.nixpkgs.locked.narHash;
  };

  overlays = [
    # stacklock2nix overlay
    (import ../nix/overlay.nix)

    # tests
    (final: prev: {
      stacklock2nix-tests =
        (final.callPackage ./test-new-package-set.nix {}) ++ [
          # new tests go here
        ];
    })
  ];

  pkgs = import nixpkgs-src { inherit overlays; };

in

pkgs
