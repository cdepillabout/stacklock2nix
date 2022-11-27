{
  description = "Nix library for generating a Nixpkgs Haskell package set from a stack.yaml.lock file";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      # # System types to support.
      # supportedSystems = [
      #   "aarch64-darwin"
      #   "aarch64-linux"
      #   "x86_64-darwin"
      #   "x86_64-linux"
      # ];

      # # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      # forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # # Nixpkgs instantiated for supported system types.
      # nixpkgsFor =
      #   forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
    in
    {
      # A Nixpkgs overlay.  This contains the stacklock2nix function that
      # end-users will want to use.
      overlay = import ./nix/overlay.nix;
    };
}
