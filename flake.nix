{
  description = "Nix library for generating a Nixpkgs Haskell package set from a stack.yaml.lock file";

  outputs = { self }: {
    # A Nixpkgs overlay.  This contains the stacklock2nix function that
    # end-users will want to use.
    overlay = import ./nix/overlay.nix;
  };
}
