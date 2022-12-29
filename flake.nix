{
  description = "Nix library for generating a Nixpkgs Haskell package set from a stack.yaml.lock file";

  outputs = { self, nixpkgs, }: {
    # A Nixpkgs overlay.  This contains the stacklock2nix function that
    # end-users will want to use.
    overlay = import ./nix/overlay.nix;

    # expose dream2nix modules for external use
    modules.dream2nix.stacklock2nix-translator = ./dream2nix/translator.nix;
    modules.dream2nix.stacklock2nix-builder = ./dream2nix/builder.nix;

    # This app is an integration test for dream2nix to be executed in CI
    apps.x86_64-linux.dream2nix-integration-test = import ./dream2nix/integration-test.nix {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      lib = nixpkgs.lib ;
    };
  };
}
