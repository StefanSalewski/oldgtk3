import oldgtk3/[gtk, gdk, glib, gobject]
import strutils, re

const
  str0 = "label {background-color: $1;\n}\n" &
    "entry {background: #aaa;\n}\n" &
    "#$2 {color: $3 ;\n}\n" &
    "label {font-size: 130%;\n}\n"

proc genCss(i: int; text: cstring): cstring =
  var bg {.global.} = "#fff"
  if i == 0:
    bg = $text
    str0 % [$bg, $i, $"#888"]
  else:
    str0 % [$bg, $i, $text]

proc entryClicked(self: Widget; data: GPointer) {.cdecl.} =
  var error: GError
  let text = entry(self).text
  let pattern = re"#([0-9abcdefABCDEF]{3}){1,2}"
  if not match($text, pattern): return 
  var provider: CssProvider = newCssProvider()
  var display: Display = displayGetDefault()
  var screen: gdk.Screen = getDefaultScreen(display)
  styleContextAddProviderForScreen(screen, styleProvider(provider), STYLE_PROVIDER_PRIORITY_APPLICATION.cuint);
  discard loadFromData(provider, genCss(cast[int](data), text), GSize(-1), error)
  objectUnref(provider);

proc main =
  var error: GError
  var grid: Grid
  var label: Label
  var entry: Entry
  let window = newWindow()
  window.title = "Color test"
  grid = newGrid()
  discard gSignalConnect(window, "destroy", gCALLBACK(gtk.mainQuit), nil)
  for i in 0..16:
    if i == 0:
      label = newLabel("Background (colors like #00f or #A3b4C5)")
    else:
      label = newLabel("This is a text to test foreground color readability " & $i)
    entry = newEntry()
    label.name = $i
    discard gSignalConnect(entry, "activate", gCALLBACK(entryClicked), cast[GPointer](i))
    grid.attach(label, 0, i.cint, 1, 1)
    grid.attach(entry, 1, i.cint, 1, 1)
  add(window, grid)
  showAll(window)

gtk.initWithArgv()
main()
gtk.main()

