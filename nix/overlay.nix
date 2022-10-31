final: prev: {

  stacklock2nix = final.callPackage ./build-support/stacklock2nix {};

  _stacklock2nix-example-haskell-package = final.stacklock2nix {
    stack-yaml = ../example-haskell-package/stack.yaml;
    stack-yaml-lock = ../example-haskell-package/stack.yaml.lock;
  };

  _stacklock2nix-example-haskell-package-set =
    final.haskell.packages.ghc924.override (oldAttrs: {
      overrides = final.lib.composeManyExtensions [
        (oldAttrs.overrides or (_: _: {}))
        final._stacklock2nix-example-haskell-package.stackYamlResolverOverlay
        final._stacklock2nix-example-haskell-package.stackYamlExtraDepsOverlay
        final._stacklock2nix-example-haskell-package.stackYamlLocalPkgsOverlay
        final._stacklock2nix-example-haskell-package.suggestedOverlay
      ];
      all-cabal-hashes = final.fetchurl {
        name = "all-cabal-hashes";
        url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/9ab160f48cb535719783bc43c0fbf33e6d52fa99.tar.gz";
        sha256 = "sha256-QC07T3MEm9LIMRpxIq3Pnqul60r7FpAdope6S62sEX8=";
      };
    });
}
