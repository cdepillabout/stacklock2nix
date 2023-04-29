{
  description = "Nix library for generating a Nixpkgs Haskell package set from a stack.yaml.lock file";

  outputs = { self }: {
    # A Nixpkgs overlay.  This contains the stacklock2nix function that
    # end-users will want to use.
    overlay = import ./nix/overlay.nix;

    # Templates to use with `flake init ...`
    templates = {
      advanced = {
        path = ./templates/advanced;
        description = "An advanced stacklock2nix template.";
        welcomeText = ''
          Welcome to the advanced Stacklock2nix template!

          This provides an empty Haskell project (the skeleton coming from the
          `simple-hpack` stack template) and the associated stacklock2nix
          files to allow for mixed cabal/stack building.

          To build:

          > nix build

          or

          > nix develop
          > cabal build

          or

          > nix develop
          > stack build --nix
          '';
      };
      default = advanced;
    };
  };
}
