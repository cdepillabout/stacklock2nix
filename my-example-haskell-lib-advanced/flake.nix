{
  description = "Advanced example of using stacklock2nix to build a Haskell project";

  # This is a flake reference to the stacklock2nix repo.
  #
  # CHANGEME: Note that in a real repo, this will need to be changed to
  # something like the following:
  #
  # inputs.stacklock2nix.url = "github:cdepillabout/stacklock2nix/main";
  inputs.stacklock2nix.url = "path:../.";

  # This is a flake reference to Nixpkgs.
  #
  # CHANGEME: Note that in a real repo, this will need to be changed to
  # something like the following:
  #
  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nixpkgs.follows = "stacklock2nix/nixpkgs";

  outputs = { self, nixpkgs, stacklock2nix }:
    let
      # System types to support.
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor =
        forAllSystems (system: import nixpkgs { inherit system; overlays = [ stacklock2nix.overlay self.overlay ]; });
    in
    {
      # A Nixpkgs overlay.
      overlay = import nix/overlay.nix;

      packages = forAllSystems (system: {
        my-example-haskell-app = nixpkgsFor.${system}.my-example-haskell-app;
      });

      defaultPackage = forAllSystems (system: self.packages.${system}.my-example-haskell-app);

      devShells = forAllSystems (system: {
        my-example-haskell-dev-shell = nixpkgsFor.${system}.my-example-haskell-dev-shell;
      });

      devShell = forAllSystems (system: self.devShells.${system}.my-example-haskell-dev-shell);
    };
}
