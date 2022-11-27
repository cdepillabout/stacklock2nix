final: prev: {
  # This is the `stacklock2nix` function.  This is the main function provided
  # by this repo.
  #
  # See the documentation in `./build-support/stacklock2nix/default.nix` for
  # the arguments and outputs of this function.
  stacklock2nix = final.callPackage ./build-support/stacklock2nix {};
}
