
{ pkgs
, # This is a function that an end-user can pass to add or change some of the
  # cabal2nix arguments.
  #
  # cabal2nixArgsOverrides :: AttrSet (VersionString -> AttrSet) -> AttrSet (VersionString -> AttrSet)
  #
  # `VersionString` will be a string like `"0.1.2.3"`, but may also be `null`
  # for local packages (since it is sometimes hard to figure out a version for
  # a local package without parsing the .cabal file).
  #
  # Example:
  # ```
  # args: args // {
  #   "pango" = version: { pango = final.pango; };
  # }
  # ```
  #
  # The `args` argument is the default attribute set of arguments that are
  # specified in this file.  Most people will want to keep them (since they
  # are generally helpful), but you could throw them all away and define
  # your own set of arguments, like this:
  #
  # ```
  # _: {
  #   "cairo" = version: { pango = final.cairo; };
  #   "pango" = version: { pango = final.pango; };
  #   "test-framework" = version: { libxml = final.libxml; };
  # }
  # ```
  cabal2nixArgsOverrides ? (args: args)
}:

# This is necessary because stacklock2nix internally uses functions like
# callHackage and callCabal2nix, and these need to be passed correct
# argument attribute sets.
#
# Here are some examples of possible overrides, and why they are necessary:
#
# 1. `"gi-vte" = ver: { vte_291 = pkgs.vte; };`
#
#     The `gi-vte` Haskell package has a pkgconfig dependency on `vte_291`, but
#     in Nixpkgs this is the `vte` system package.
#     `haskellPackages.callPackage` can't figure this out for itself.
#
# 2. `"gi-gdk" = ver: { gtk3 = pkgs.gtk3; };`
#
#     The `gi-gdk` Haskell package depends on the `gtk3` system library, but
#     if you don't explicitly pull in the `gtk3` system package,
#     `haskellPackages.callPackage` assumes you want the `gtk3` Haskell
#     package, but this of course will fail to build.
#
# 3. `"splitmix" = ver: { testu01 = null; };`
#
#     The `splitmix` Haskell package as a dependency on a `testu01` library
#     for testing, but this is not necessary to build the Haskell library.
#
# Please feel free to send PRs adding necessary overrides here.
#
# Make sure to keep this list in alphabetical order.

cabal2nixArgsOverrides {
  "cairo" = ver: { cairo = pkgs.cairo; };

  "gi-cairo" = ver: { cairo = pkgs.cairo; };

  "gi-gdk" = ver: { gtk3 = pkgs.gtk3; };

  "gi-gio" = ver: { glib = pkgs.glib; };

  "gi-glib" = ver: { glib = pkgs.glib; };

  "gi-gtk" = ver: { gtk3 = pkgs.gtk3; };

  "gi-gmodule" = ver: { gmodule = null; };

  "gi-gobject" = ver: { glib = pkgs.glib; };

  "gi-harfbuzz" = ver: { harfbuzz-gobject = null; };

  "gi-pango" = ver: { cairo = pkgs.cairo; pango = pkgs.pango; };

  "gi-vte" = ver: { vte_291 = pkgs.vte; };

  "glib" = ver: { glib = pkgs.glib; };

  "haskell-gi" = ver: { glib = pkgs.glib; gobject-introspection = pkgs.gobject-introspection; };

  "haskell-gi-base" = ver: { glib = pkgs.glib; };

  "pango" = ver: { pango = pkgs.pango; };

  # The PSQueue and fingertree-psqueue packages are used in benchmarks, but they are not on Stackage.
  "psqueues" = ver: { fingertree-psqueue = null; PSQueue = null; };

  "saltine" = ver: { libsodium = pkgs.libsodium; };

  "secp256k1-haskell" = ver: { secp256k1 = pkgs.secp256k1; };

  "splitmix" = ver:
    # Starting in splitmix-0.1.0.4, a system library called testu01 is used in
    # tests, but it is not available in Nixpkgs.  We disable the tests for
    # splitmix in the suggestedOverlay.nix file, so it is fine to just pass
    # this argument as null.
    #
    # However, testu01 is only used on Linux, so we don't need to do anything
    # if this is not Linux.
    if pkgs.lib.versionAtLeast ver "0.1.0.4" then
      if pkgs.stdenv.isLinux then
        { testu01 = null; }
      else
        {}
    else
      {};

  "test-framework" = ver: { libxml = pkgs.libxml; };

  "termonad" = ver: { vte_291 = pkgs.vte; gtk3 = pkgs.gtk3; pcre2 = pkgs.pcre2;};

  "unordered-containers" = ver:
    # Starting in unordered-containers-0.2.18.0 (which is in LTS-20),
    # unordered-containers uses the Haskell package nothunks in its test-suite,
    # but nothunks is not in Stackage.  We disable the tests for
    # unordered-containers in the suggestedOverlay.nix file, but callCabal2Nix
    # is called on it before suggestedOverlay.nix is applied.  So here we need
    # to just pass in null for the nothunks dependency, since it won't end up
    # being used.
    if pkgs.lib.versionAtLeast ver "0.2.18" then
      { nothunks = null; }
    else
      {};

  "zlib" = ver: { zlib = pkgs.zlib; };
}
