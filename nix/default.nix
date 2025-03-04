{...}:

# Nixpkgs with overlays for stacklock2nix.  This is convenient to use with
# `nix repl`:
#
# $ nix repl ./nix
# nix-repl>
#
# Within this nix-repl, you have access to everything defined in ./overlay.nix.

let
  flake-lock = builtins.fromJSON (builtins.readFile ../my-example-haskell-lib-easy/flake.lock);

  nixpkgs-src = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${flake-lock.nodes.nixpkgs.locked.rev}.tar.gz";
    sha256 = flake-lock.nodes.nixpkgs.locked.narHash;
  };

  overlays = [
    (import ./overlay.nix)
  ];

  pkgs = import nixpkgs-src { inherit overlays; };

in

pkgs
