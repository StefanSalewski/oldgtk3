import oldgtk3/[gdk_pixbuf, gobject]

var t: GType

t = gdk_pixbuf.pixbufGetType()

echo t.int

