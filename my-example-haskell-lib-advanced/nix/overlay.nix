final: prev: {

  # This is the `stacklock2nix` function.  This is the main function provided
  # by this repo.
  #
  # See the documentation in `./build-support/stacklock2nix/default.nix` for
  # the arguments and outputs of this function.
  stacklock2nix = final.callPackage ./build-support/stacklock2nix {};

  ##################
  ## Easy example ##
  ##################

  _stacklock-example-easy = final.stacklock2nix {
    stackYaml = ../my-example-haskell-lib/stack.yaml;

    baseHaskellPkgSet = final.haskell.packages.ghc924;

    # Any additional Haskell package overrides you may want to add.
    additionalHaskellPkgSetOverrides = hfinal: hprev: {
      # TODO: Explain why this is necessary and link to servant-cassava PR.
      servant-cassava =
        final.haskell.lib.compose.overrideCabal
          { editedCabalFile = null; revision = null; }
          hprev.servant-cassava;
    };

    # Additional packages that should be available for development.
    additionalDevShellNativeBuildInputs = stacklockHaskellPkgSet: [
      # Some Haskell tools (like cabal-install and ghcid) can be taken from the
      # top-level of Nixpkgs.
      final.cabal-install
      final.ghcid
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
      #stacklockHaskellPkgSet.some-haskell-lib
    ];

    # When creating your own Haskell package set from the stacklock2nix
    # output, you may need to specify a newer all-cabal-hashes.
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
    all-cabal-hashes = final.fetchurl {
      name = "all-cabal-hashes";
      url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/9ab160f48cb535719783bc43c0fbf33e6d52fa99.tar.gz";
      sha256 = "sha256-QC07T3MEm9LIMRpxIq3Pnqul60r7FpAdope6S62sEX8=";
    };
  };

  _stacklock-my-example-haskell-lib-easy =
    final._stacklock-example-easy.pkgSet.my-example-haskell-lib;

  # You can also easily create a development shell for hacking on your local
  # packages with `cabal`.
  _stacklock-my-example-dev-shell-easy = final._stacklock-example-easy.devShell;

  ######################
  ## Advanced Example ##
  ######################

  # First, call stacklock2nix and pass it the `stack.yaml` for your project.
  _stacklock-example-advanced = final.stacklock2nix {
    stackYaml = ../my-example-haskell-lib/stack.yaml;
  };

  # Then, apply the Haskell package overlays provided by stacklock2nix to the
  # Haskell package set you want to use.
  #
  # This gives you a normal Haskell package set with packages defined by your
  # stack.yaml and Stackage snapshot / resolver.
  _stacklock-example-pkg-set-advanced =
    final.haskell.packages.ghc924.override (oldAttrs: {
      overrides = final.lib.composeManyExtensions [
        # Make sure not to lose any old overrides, although in most cases there
        # won't be any.
        (oldAttrs.overrides or (_: _: {}))
        # An overlay with Haskell packages from the Stackage snapshot.
        final._stacklock-example-advanced.stackYamlResolverOverlay
        # An overlay with `extraDeps` from `stack.yaml`.
        final._stacklock-example-advanced.stackYamlExtraDepsOverlay
        # An overlay with your local packages from `stack.yaml`.
        final._stacklock-example-advanced.stackYamlLocalPkgsOverlay
        # Suggested overrides for common problems.
        final._stacklock-example-advanced.suggestedOverlay
        # Any additional overrides you may want to add.
        (hfinal: hprev: {
          servant-cassava =
            final.haskell.lib.compose.overrideCabal
              { editedCabalFile = null; revision = null; }
              hprev.servant-cassava;
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
  # This example corresponds to the ../my-example-haskell-lib package.
  _stacklock-my-example-haskell-lib-advanced =
    final._stacklock-example-pkg-set-advanced.my-example-haskell-lib;

  # You can also easily create a development shell for hacking on your local
  # packages with `cabal`.
  _stacklock-my-example-dev-shell-advanced =
    final._stacklock-example-pkg-set-advanced.shellFor {
      packages = haskPkgs: final._stacklock-example-advanced.localPkgsSelector haskPkgs;
      # Additional packages that should be available for development.
      nativeBuildInputs = [
        # Some Haskell tools (like cabal-install) can be taken from the
        # top-level of Nixpkgs.
        final.cabal-install
        final.ghcid
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
