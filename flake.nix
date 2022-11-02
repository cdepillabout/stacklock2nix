{
  description = "Nix library for generating a Nixpkgs Haskell package set from a stack.yaml.lock file";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      # System types to support.
      #
      # TODO: Add more systems to this list.
      supportedSystems = [
        "x86_64-linux"
        # "x86_64-darwin"
      ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor =
        forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {
      # A Nixpkgs overlay.  This contains the stacklock2nix function that
      # end-users will want to use.
      overlay = import ./nix/overlay.nix;

      packages = forAllSystems (system: {
        my-example-haskell-lib-easy =
          nixpkgsFor.${system}._stacklock-my-example-haskell-lib-easy;
        my-example-haskell-lib-advanced =
          nixpkgsFor.${system}._stacklock-my-example-haskell-lib-advanced;
      });

      # defaultPackage = forAllSystems (system: self.packages.${system}.hello);

      devShells = forAllSystems (system: {
        my-example-haskell-lib-devShell-easy =
          nixpkgsFor.${system}._stacklock-my-example-dev-shell-easy;

        my-example-haskell-lib-devShell-advanced =
          nixpkgsFor.${system}._stacklock-my-example-dev-shell-advanced;
      });

      devShell =
        forAllSystems (system: self.devShells.${system}.my-example-haskell-lib-dev-shell-advanced);
    };
}
