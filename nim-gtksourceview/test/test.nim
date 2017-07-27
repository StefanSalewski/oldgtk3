import oldgtk3/[gtk, glib, gobject, gtksource]

proc destroy(widget: Widget, data: Gpointer) {.cdecl.} = main_quit()

gtk.initWithArgv()

var window = newWindow()
window.setDefaultSize(600, 200)

discard gSignalConnect(window, "destroy", cast[GCallback](test.destroy), nil)

window.title = "GTK-Source-View"

var
  sv: gtksource.View

sv = newView()
window.add(sv)
window.showAll
gtk.main()

