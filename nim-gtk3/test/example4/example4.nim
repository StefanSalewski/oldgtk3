# https://developer.gnome.org/gtk3/stable/ch01s03.html

import oldgtk3/[gtk, glib, gobject]

proc printHello*(widget: Widget; data: Gpointer) {.cdecl.} =
  print("Hello World\x0A")

proc demo() =
  var
    builder: Builder
    window: Window
    button: Button
    error: GError
  builder = newBuilder()
  discard addFromFile(builder, "builder.ui", error)
  window = Window(getObject(builder, "window"))
  discard gSignalConnect(window, "destroy", gCallback(mainQuit), nil)
  button = Button(getObject(builder, "button1"))
  discard gSignalConnect(button, "clicked", gCallback(printHello), nil)
  button = Button(getObject(builder, "button2"))
  discard gSignalConnect(button, "clicked", gCallback(printHello), nil)
  button = Button(getObject(builder, "quit"))
  discard gSignalConnect(button, "clicked", gCallback(mainQuit), nil)

gtk.initWithArgv()
demo()
gtk.main()

