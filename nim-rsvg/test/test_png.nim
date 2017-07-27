import oldgtk3/[cairo, rsvg, glib, gobject]

const FileName = "/usr/share/gnome-chess/pieces/simple/whiteKing.svg" # you may try other files!

var
  s: Surface
  cr: Context
  error: GError
  handle: rsvg.Handle

s = imageSurfaceCreate(FORMAT.ARGB32, 1250, 1250) # that is the svg size displayed by eog!
cr = create(s)
handle = newHandle(FileName, error)
if error != nil:
  echo error.message
  free(error)
assert handle != nil
assert renderCairo(handle, cr)
objectUnref(handle)
discard writeToPng(s, "image.png")
destroy(cr)
destroy(s)


