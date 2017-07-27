import oldgtk3/pango

var
  i: cint
  x: cdouble
i = pango.unitsFromDouble(cdouble(1))
echo i
x = pango.unitsToDouble(cint(1024))
echo x
  
