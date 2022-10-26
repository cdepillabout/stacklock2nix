final: prev: {

  # This is the purescript2nix function.  This makes it easy to build a
  # PureScript package with Nix.  This is the main function provided by this
  # repo.
  stacklock2nix = final.callPackage ./build-support/stacklock2nix {};

  # This is an example PureScript package that has been built by the
  # stacklock2nix function.
  #
  # This is just a test that stacklock2nix actually works, as well an example
  # that end users can base their own code off of.
  example-haskell-package = final.stacklock2nix {
    pname = "example-haskell-package";
    version = "0.1.0.0";
    stack-yaml = ../example-haskell-package/stack.yaml;
    stack-yaml-lock = ../example-haskell-package/stack.yaml.lock;
  };

  # # This is a simple develpoment shell with purescript and spago.  This can be
  # # used for building the ../example-purescript-package repo using purs and
  # # spago.
  # purescript-dev-shell = final.mkShell {
  #   nativeBuildInputs = [
  #     final.dhall
  #     final.purescript
  #     final.spago
  #   ];
  # };
}
