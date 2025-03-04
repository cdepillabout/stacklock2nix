final: prev: {

  # First, call stacklock2nix and pass it the `stack.yaml` for your project.
  my-example-haskell-stacklock = final.stacklock2nix {
    stackYaml = ../stack.yaml;

    # When using `stacklock2nix`, you may need to specify a newer all-cabal-hashes.
    #
    # This is necessary when you are using a Stackage snapshot/resolver or
    # `extraDeps` in your `stack.yaml` file that is _newer_ than the
    # `all-cabal-hashes` derivation from the Nixpkgs you are using.
    #
    # If you are using the latest nixpkgs-unstable and an old Stackage
    # resolver, then it is usually not necessary to override
    # `all-cabal-hashes`.
    #
    # If you are using a very recent Stackage resolver and an old Nixpkgs,
    # it is almost always necessary to override `all-cabal-hashes`.
    #
    # WARNING: If you're on a case-insensitive filesystem (like some OSX
    # filesystems), you may get a hash mismatch when using fetchFromGitHub
    # to fetch all-cabal-hashes.  As a workaround in that case, you may
    # want to use fetchurl:
    #
    # ```
    # all-cabal-hashes = final.fetchurl {
    #   url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/578b09df5072f21768cfe13edfc3e4c3e41428fc.tar.gz";
    #   sha256 = "sha256-vYFfZ77fOcOQpAef6VGXlAZBzTe3rjBSS2dDWQQSPPw=";
    # };
    # ```
    #
    # You can find more information in:
    # https://github.com/NixOS/nixpkgs/issues/39308
    all-cabal-hashes = final.fetchFromGitHub {
      owner = "commercialhaskell";
      repo = "all-cabal-hashes";
      rev = "578b09df5072f21768cfe13edfc3e4c3e41428fc";
      sha256 = "sha256-fmf4LukOJ2c0bCmNfuN+n2R6bxGhJqag9CBvZQEl3kA=";
    };
  };

  # Then, apply the Haskell package overlays provided by stacklock2nix to the
  # Haskell package set you want to use.
  #
  # This gives you a normal Haskell package set with packages defined by your
  # stack.yaml and Stackage snapshot / resolver.
  my-example-haskell-pkg-set =
    final.haskell.packages.ghc984.override (oldAttrs: {

      # Make sure the package set is created with the same all-cabal-hashes you
      # passed to `stacklock2nix`.
      inherit (final.my-example-haskell-stacklock) all-cabal-hashes;

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
        final.haskell.packages.ghc984.haskell-language-server
        # Other Haskell tools may need to be taken from the stacklock2nix
        # Haskell package set, and compiled with the example same dependency
        # versions your project depends on.
      ];
    };
}
