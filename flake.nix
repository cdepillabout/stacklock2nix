{
  description = "Nix library for generating a Nixpkgs Haskell package set from a stack.yaml.lock file";

  outputs = { self }: {
    # A Nixpkgs overlay.  This contains the stacklock2nix function that
    # end-users will want to use.
    overlay = import ./nix/overlay.nix;

    # Templates to use with `flake init ...`
    templates = rec {
      advanced = {
        path = ./templates/advanced;
        description = "An advanced stacklock2nix template.";
        welcomeText = builtins.readFile ./templates/advanced/README.md;
      };
      default = advanced;
    };
  };
}
