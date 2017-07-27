import oldgtk3/[gtk, glib, gobject]

proc destroy(widget: Widget, data: Gpointer) {.cdecl.} = mainQuit()

gtk.initWithArgv()

var window = newWindow()

discard gSignalConnect(window, "destroy", cast[GCallback](test.destroy), nil)

window.title = "Radio Buttons"
echo(window.title)
echo(window.getTitle) # get_ is available also

window.borderWidth = 10
window.setBorderWidth(10) # set_ is available also

var
  r1 = newRadioButton("RadioButton _1")
  r2 = newRadioButton(r1, "RadioButton _2")
  r3 = newRadioButton(r1, "RadioButton _3")
  box = newBox(Orientation.VERTICAL, 0)

box.packStart(r1, GFALSE, GTRUE, 0) # maybe we should add default values
box.packStart(r2, GFALSE, GTRUE, 0)
box.packStart(r3, GFALSE, GTRUE, 0)
window.add(box)
window.showAll
gtk.main()

