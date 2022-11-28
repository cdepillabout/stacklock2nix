final: prev: {

  # First, call stacklock2nix and pass it the `stack.yaml` for your project.
  my-example-haskell-stacklock = final.stacklock2nix {
    stackYaml = ../stack.yaml;
  };

  # Then, apply the Haskell package overlays provided by stacklock2nix to the
  # Haskell package set you want to use.
  #
  # This gives you a normal Haskell package set with packages defined by your
  # stack.yaml and Stackage snapshot / resolver.
  my-example-haskell-pkg-set =
    final.haskell.packages.ghc924.override (oldAttrs: {
      overrides = final.lib.composeManyExtensions [
        # Make sure not to lose any old overrides, although in most cases there
        # won't be any.
        (oldAttrs.overrides or (_: _: {}))

        # An overlay with Haskell packages from the Stackage snapshot.
        final.my-example-haskell-stacklock.stackYamlResolverOverlay

        # An overlay with `extraDeps` from `stack.yaml`.
        final.my-example-haskell-stacklock.stackYamlExtraDepsOverlay

        # An overlay with your local packages from `stack.yaml`.
        final.my-example-haskell-stacklock.stackYamlLocalPkgsOverlay

        # Suggested overrides for common problems.
        final.my-example-haskell-stacklock.suggestedOverlay

        # Any additional overrides you may want to add.
        (hfinal: hprev: {
          # The servant-cassava.cabal file is malformed on GitHub:
          # https://github.com/haskell-servant/servant-cassava/pull/29
          servant-cassava =
            final.haskell.lib.compose.overrideCabal
              { editedCabalFile = null; revision = null; }
              hprev.servant-cassava;

          # The amazon libraries try to access the network in tests,
          # so we disable them here.
          amazonka = final.haskell.lib.dontCheck hprev.amazonka;
          amazonka-core = final.haskell.lib.dontCheck hprev.amazonka-core;
          amazonka-sso = final.haskell.lib.dontCheck hprev.amazonka-sso;
          amazonka-sts = final.haskell.lib.dontCheck hprev.amazonka-sts;
        })
      ];
      all-cabal-hashes = final.fetchurl {
        name = "all-cabal-hashes";
        url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/9ab160f48cb535719783bc43c0fbf33e6d52fa99.tar.gz";
        sha256 = "sha256-QC07T3MEm9LIMRpxIq3Pnqul60r7FpAdope6S62sEX8=";
      };
    });

  # Finally, you can pull out the Haskell package you're interested in and
  # build it with Nix.  This will normally be one of your local packages.
  my-example-haskell-app = final.my-example-haskell-pkg-set.my-example-haskell-app;

  # You can also easily create a development shell for hacking on your local
  # packages with `cabal`.
  my-example-haskell-dev-shell =
    final.my-example-haskell-pkg-set.shellFor {
      packages = haskPkgs: final.my-example-haskell-stacklock.localPkgsSelector haskPkgs;
      # Additional packages that should be available for development.
      nativeBuildInputs = [
        # Some Haskell tools (like cabal-install) can be taken from the
        # top-level of Nixpkgs.
        final.cabal-install
        final.ghcid
        final.hpack
        final.stack
        # Some Haskell tools need to have been compiled with the same compiler
        # you used to define your stacklock2nix Haskell package set.  Be
        # careful not to pull these packages from your stacklock2nix Haskell
        # package set, since transitive dependency versions may have been
        # carefully setup in Nixpkgs so that the tool will compile, and your
        # stacklock2nix Haskell package set will likely contain different
        # versions.
        final.haskell.packages.ghc924.haskell-language-server
        # Other Haskell tools may need to be taken from the stacklock2nix
        # Haskell package set, and compiled with the example same dependency
        # versions your project depends on.
      ];
    };
}
