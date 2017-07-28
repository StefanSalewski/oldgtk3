# Package

version       = "0.1.0"
author        = "Stefan Salewski"
description   = "Low level bindings for GTK3 related libraries"
license       = "MIT"
skipDirs = @["common", "nim-atk", "nim-cairo", "nim-gdk3", "nim-gdk_pixbuf", "nim-gio", "nim-gir", "nim-glib", "nim-gobject", "nim-gtk3", "nim-gtksourceview", "nim-pango", "nim-rsvg", "oldgtk3.bak"]

# Dependencies

requires "nim >= 0.17.0"

when defined(nimdistros):
  import distros
  if detectOs(Ubuntu) or detectOs(Debian):
    foreignDep "libgtk-3-dev"
  elif detectOs(Gentoo):
    foreignDep "gtk+" # can we specify gtk3?
  #else: we don't know the names for all the other distributions
  #  foreignDep ""


