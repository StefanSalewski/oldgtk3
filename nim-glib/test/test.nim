import oldgtk3/glib

var s: cstring

s = getCurrentDir()
echo s
free(s)
s = getUserName()
echo s
free(s)
echo getNumProcessors()
#echo asciiIslower('a') # g_ascii_table is missing for 2.48
#echo asciiIslower('B')
