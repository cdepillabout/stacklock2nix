
{ pkgs, cabal2nixArgsOverrides ? (args: args) }:

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
  "splitmix" = ver: { testu01 = null; };
  "termonad" = ver: { vte_291 = pkgs.vte; gtk3 = pkgs.gtk3; pcre2 = pkgs.pcre2;};
  "zlib" = ver: { zlib = pkgs.zlib; };
}
