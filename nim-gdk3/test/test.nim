# very ugly test to see if lib is found and loaded 
import oldgtk3/[gdk, glib]

var
  s: Screen
  #s1: PScreen # deprecated warnings
  #s2: GdkScreen# deprecated warnings
  #s3: PGdkScreen # deprecated warnings
  r: cdouble
  str: cstring = ""
  #p: ptr cstring = addr(str)
  i: cint = 0
  p: cstringArray = cast[cstringArray](nil)

init(i, p)

s = screenGetDefault()

r = s.getResolution()
echo r
echo s.resolution # -1.0 == unset

echo s.width # 1600, correct
echo getWidth(s) # also available

#echo screen_get_width(s) # deprecated warnings

