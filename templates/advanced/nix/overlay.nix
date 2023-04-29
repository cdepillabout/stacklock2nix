final: prev: rec {
  some-app-stacklock = final.stacklock2nix {
    stackYaml = ../stack.yaml;
  };

  some-app-pkg-set = final.haskell.packages.ghc925.override (oldAttrs: {
    overrides = final.lib.composeManyExtensions [
      (oldAttrs.overrides or (_: _: {}))

      final.some-app-stacklock.stackYamlResolverOverlay

      final.some-app-stacklock.stackYamlExtraDepsOverlay

      final.some-app-stacklock.stackYamlLocalPkgsOverlay

      final.some-app-stacklock.suggestedOverlay

      (hfinal: hprev: {
        # Some tests don't work
        hpack_0_35_0 = final.haskell.lib.dontCheck hprev.hpack_0_35_0;
      })
    ];

    all-cabal-hashes =
      # You will likely want to update this to the latest hash on github; i.e.
      # to the value of:
      #
      # > git ls-remote https://github.com/commercialhaskell/all-cabal-hashes refs/heads/hackage
      #
      let hash = "9ae983a3f0376e15a694dd6eaa21a28833c83d7f";
          sha  = "sha256-tIE6lDw0zuf9w304ZOLcTJSLkRLvwcP9Kif/k6FUsFs=";
      in final.fetchurl {
        name   = "all-cabal-hashes";
        url    = "https://github.com/commercialhaskell/all-cabal-hashes/archive/${hash}.tar.gz";
        sha256 = sha;
      };
  });

  some-app = final.some-app-pkg-set.some-app;

  some-app-dev-shell = final.some-app-pkg-set.shellFor rec {
    packages = haskPkgs: final.some-app-stacklock.localPkgsSelector haskPkgs;

    # Wrap cabal to always run `hpack` first.
    cabalWrapped = final.writers.writeDashBin "cabal" ''
      if [ -f package.yaml ]; then
        ${some-app-pkg-set.hpack_0_35_0}/bin/hpack
      fi
      ${final.cabal-install}/bin/cabal "$@"
    '';

    nativeBuildInputs = [
      # Use our overridden hpack so we skip the tests
      some-app-pkg-set.hpack_0_35_0

      final.stack

      cabalWrapped
    ];
  };
}
