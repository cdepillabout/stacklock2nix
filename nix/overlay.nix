final: prev: {

  stacklock2nix = final.callPackage ./build-support/stacklock2nix {};

  _stacklock-example = final.stacklock2nix {
    stack-yaml = ../my-example-haskell-lib/stack.yaml;
    # stack-yaml-lock = ../my-example-haskell-lib/stack.yaml.lock;
  };

  _stacklock-example-pkg-set =
    final.haskell.packages.ghc924.override (oldAttrs: {
      overrides = final.lib.composeManyExtensions [
        (oldAttrs.overrides or (_: _: {}))
        final._stacklock-example.stackYamlResolverOverlay
        final._stacklock-example.stackYamlExtraDepsOverlay
        final._stacklock-example.stackYamlLocalPkgsOverlay
        final._stacklock-example.suggestedOverlay
        (hfinal: hprev: {
          servant-cassava =
            final.haskell.lib.compose.overrideCabal
              { editedCabalFile = null;
                revision = null;
              }
              hprev.servant-cassava;
        })
      ];
      all-cabal-hashes = final.fetchurl {
        name = "all-cabal-hashes";
        url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/9ab160f48cb535719783bc43c0fbf33e6d52fa99.tar.gz";
        sha256 = "sha256-QC07T3MEm9LIMRpxIq3Pnqul60r7FpAdope6S62sEX8=";
      };
    });

  _stacklock-my-example-haskell-lib =
    final._stacklock-example-pkg-set.my-example-haskell-lib;

  _stacklock-my-example-dev-shell =
    final._stacklock-example-pkg-set.shellFor {
      packages = haskPkgs: final._stacklock-example.localPkgsSelector haskPkgs;
      buildInputs = [ final.cabal-install ];
    };
}
