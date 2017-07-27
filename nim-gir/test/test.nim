import oldgtk3/gir

echo "gir test"

if gIrepositoryGetDefault() != nil:
  echo "successfully loaded gir lib"
else:
  echo "can not load gir library"


