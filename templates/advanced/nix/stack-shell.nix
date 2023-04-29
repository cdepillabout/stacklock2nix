{
  # This is the ghc that stack passes in, but we just ignore it.
  ghc,
  ...
}:
with (import ./. {});
  haskell.lib.compose.buildStackProject {
    name = "stack-shell";
    # Make sure to use the GHC that is used to build our Haskell package set.
    ghc = some-app-pkg-set.ghc;
    # Example native build inputs that are for building with stack.
    nativeBuildInputs = [
      bzip2
      zlib
      zlib.dev
    ];
  }

