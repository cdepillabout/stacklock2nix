
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
      stacklock2nix-tests = {
        # This tests that stacklock2nix correctly outputs `newPkgSet` and
        # `newPkgSetDevShell` attributes.
        #
        # This also tests that all-cabal-hashes works correctly as a tarball (not a directory).
        new-package-set = final.callPackage ./test-new-package-set.nix {};

        # This tests that all-cabal-hashes works correctly as a directory (not a tarball).
        #
        # This also tests that our stacklock2nix-specific passthru values are working.
        all-cabal-hashes-is-dir = final.callPackage ./test-all-cabal-hashes-is-dir.nix {};

        # This test that a stack.yaml with no local packages defined is still
        # able to be used by stacklock2nix, and produces a reasonable package set.
        no-local-packages = final.callPackage ./test-no-local-packages {};

        # This tests that leaving out the `packages` top-level key from `stack.yaml` will
        # default to just using a single package in the same directory as the `stack.yaml` file.
        default-local-package = final.callPackage ./test-default-local-package {};
      };

      # A list of all stacklock2nix tests.  This makes it easy to build all
      # tests with a single call to `nix-build`.
      all-stacklock2nix-tests =
        final.lib.flatten (builtins.attrValues final.stacklock2nix-tests);
    })
  ];

  pkgs = import nixpkgs-src { inherit overlays; };

in

pkgs
