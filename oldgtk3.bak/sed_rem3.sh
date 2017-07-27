# our scripts generate gtk3 and gdk3 module names, so we need to fix that.
#sed -i "s/\bgtk3\./gtk./g" *.nim
#sed -i "s/\bgdk3\./gdk./g" *.nim
sed -i "s/\bgtk3\b/gtk/g" *.nim
sed -i "s/\bgdk3\b/gdk/g" *.nim
