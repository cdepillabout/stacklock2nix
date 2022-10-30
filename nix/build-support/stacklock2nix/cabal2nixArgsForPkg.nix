
{ pkgs }:

{
  "gi-glib" = ver: { glib = pkgs.glib; };
  "gi-gmodule" = ver: { gmodule = null; };
  "gi-harfbuzz" = ver: { harfbuzz-gobject = null; };
  "gi-vte" = ver: { vte_291 = pkgs.vte; };
  "glib" = ver: { glib = pkgs.glib; };
  "haskell-gi" = ver: { glib = pkgs.glib; gobject-introspection = pkgs.gobject-introspection; };
  "haskell-gi-base" = ver: { glib = pkgs.glib; };
  "splitmix" = ver: { testu01 = null; };
  "termonad" = ver: { vte_291 = pkgs.vte; };
  "zlib" = ver: { zlib = pkgs.zlib; };
}
