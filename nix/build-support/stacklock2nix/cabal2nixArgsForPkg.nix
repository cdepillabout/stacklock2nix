
{ pkgs
, # This is a function that an end-user can pass to add or change some of the
  # cabal2nix arguments.
  #
  # cabal2nixArgsOverrides :: AttrSet (VersionString -> AttrSet) -> AttrSet (VersionString -> AttrSet)
  #
  # `VersionString` will be a string like `"0.1.2.3"`, but may also be `null`
  # for local packages (since it is sometimes hard to figure out a version for
  # a local package without parsing the .cabal file).
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

cabal2nixArgsOverrides {
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
  "secp256k1-haskell" = ver: { secp256k1 = pkgs.secp256k1; };
  "splitmix" = ver: { testu01 = null; };
  "termonad" = ver: { vte_291 = pkgs.vte; gtk3 = pkgs.gtk3; pcre2 = pkgs.pcre2;};
  "zlib" = ver: { zlib = pkgs.zlib; };
}
