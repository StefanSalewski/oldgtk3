#!/bin/bash
# S. Salewski, 26-MAY-2014 (initial release, GDK 3.12)
# S. Salewski, 24-JUL-2017
# Generate GTK3 bindings for Nim
# we try to process all headers, including win32, wayland, quartz, broadway and mir
# currently I can test only with x11
#
gtk3_dir="/home/stefan/Downloads/gtk+-3.22.16"
final="final.h" # the input file for c2nim
list="list.txt"
wdir="tmp_gdk"

# GdkColor is from deprecated...
targets='x11 deprecated win32 wayland quartz mir broadway' # I can test only x11 currently!
all_t=". ${targets}"

rm -rf $wdir # start from scratch
mkdir $wdir
cd $wdir
cp -r $gtk3_dir/gdk .
cd gdk

# I think for 3.20 we have all -- for newer headers we may investigate the generated list
#echo 'we may miss these headers -- please check:'
#for i in $all_t ; do
#  grep -c DECL ${i}/*.h | grep h:0
#done

# we insert in each header a marker with the filename
# may fail if G_BEGIN_DECLS macro is missing in a header
for j in $all_t ; do
  for i in ${j}/*.h; do
    sed -i "/^G_BEGIN_DECLS/a${i}_ssalewski;" $i
  done
done

# order matters.
cat gdk.h x11/gdkx.h win32/gdkwin32.h wayland/gdkwayland.h quartz/gdkquartz.h mir/gdkmir.h broadway/gdkbroadway.h  > all.h

cd ..

touch windows.h # empty dummy headers to make cpp happy
touch commctrl.h
#touch wayland-client.h
mkdir AppKit
touch AppKit/AppKit.h
mkdir mir_toolkit
touch mir_toolkit/mir_client_library.h

# cpp run with all headers to determine order
echo "cat \\" > $list
echo 'gdkkeysyms.h \' >> $list # we need this also
echo 'gdkintl.h \' >> $list

cpp -I. `pkg-config --cflags gtk+-3.0` gdk/all.h $final

rm windows.h  commctrl.h #wayland-client.h
rm -r AppKit
rm -r mir_toolkit

# extract file names and push names to list
grep ssalewski $final | sed 's/_ssalewski;/ \\/' >> $list

# add remaining missing headers
# for now we put all at the bottom and do manually ordering if necessary
echo 'broadway/broadway-buffer.h \' >> $list
echo 'broadway/broadway-protocol.h \' >> $list
echo 'broadway/broadway-output.h \' >> $list
echo 'broadway/broadway-server.h \' >> $list

# may we need these?
#gdkversionmacros.h
#keyname-table.h

sed -i '/gdkprivate\.h/d' $list # included by quartz backend

i=`sort $list | uniq -d | wc -l`
if [ $i != 0 ]; then echo 'list contains duplicates!'; exit; fi;

# now we work again with original headers
rm -rf gdk
cp -r $gtk3_dir/gdk .

sed -i "s/#define GDK_PRIORITY_EVENTS (G_PRIORITY_DEFAULT)//" gdk/gdkmain.h # redefinition

# insert for each header file its name as first line
for j in $all_t ; do
  for i in gdk/${j}/*.h; do
    sed -i "1i/* file: $i */" $i
    sed -i "1i#define headerfilename \"$i\"" $i # marker for splitting
  done
done

cd gdk
bash ../$list > ../$final
cd ..

# insert empty dummy #def statements for strange macros
# we restrict use of wildcards in sed/perl patterns to limit risc of damage something!
for i in 2 4 6 8 10 12 14 16 18 20 22 ; do
  sed -i "1i#def GDK_AVAILABLE_IN_3_$i\n#def GDK_DEPRECATED_IN_3_$i\n#def GDK_DEPRECATED_IN_3_${i}_FOR(x)" $final
done

sed -i "1i#def G_BEGIN_DECLS" $final
sed -i "1i#def G_END_DECLS" $final
sed -i "1i#def GDK_AVAILABLE_IN_ALL" $final
sed -i "1i#def GDK_DEPRECATED_IN_3_0" $final
sed -i "1i#def GDK_DEPRECATED_IN_3_0_FOR(x)" $final
sed -i "1i#def G_GNUC_CONST" $final
sed -i "1i#def GDK_THREADS_DEPRECATED" $final
sed -i "1i#def G_GNUC_WARN_UNUSED_RESULT" $final
sed -i "1i#def G_GNUC_NULL_TERMINATED" $final

# insert () after name, so it is a template, not a const
sed -i 's/#define GDK_NONE            _GDK_MAKE_ATOM (0)/#define GDK_NONE()            _GDK_MAKE_ATOM (0)/' $final
sed -i 's/#define GDK_SELECTION_PRIMARY 		_GDK_MAKE_ATOM (1)/#define GDK_SELECTION_PRIMARY() 		_GDK_MAKE_ATOM (1)/' $final
sed -i 's/#define GDK_SELECTION_SECONDARY 	_GDK_MAKE_ATOM (2)/#define GDK_SELECTION_SECONDARY() 	_GDK_MAKE_ATOM (2)/' $final
sed -i 's/#define GDK_SELECTION_CLIPBOARD 	_GDK_MAKE_ATOM (69)/#define GDK_SELECTION_CLIPBOARD() 	_GDK_MAKE_ATOM (69)/' $final
sed -i 's/#define GDK_TARGET_BITMAP 		_GDK_MAKE_ATOM (5)/#define GDK_TARGET_BITMAP() 		_GDK_MAKE_ATOM (5)/' $final
sed -i 's/#define GDK_TARGET_COLORMAP 		_GDK_MAKE_ATOM (7)/#define GDK_TARGET_COLORMAP() 		_GDK_MAKE_ATOM (7)/' $final
sed -i 's/#define GDK_TARGET_DRAWABLE 		_GDK_MAKE_ATOM (17)/#define GDK_TARGET_DRAWABLE() 		_GDK_MAKE_ATOM (17)/' $final
sed -i 's/#define GDK_TARGET_PIXMAP 		_GDK_MAKE_ATOM (20)/#define GDK_TARGET_PIXMAP() 		_GDK_MAKE_ATOM (20)/' $final
sed -i 's/#define GDK_TARGET_STRING 		_GDK_MAKE_ATOM (31)/#define GDK_TARGET_STRING() 		_GDK_MAKE_ATOM (31)/' $final
sed -i 's/#define GDK_SELECTION_TYPE_ATOM 	_GDK_MAKE_ATOM (4)/#define GDK_SELECTION_TYPE_ATOM() 	_GDK_MAKE_ATOM (4)/' $final
sed -i 's/#define GDK_SELECTION_TYPE_BITMAP 	_GDK_MAKE_ATOM (5)/#define GDK_SELECTION_TYPE_BITMAP() 	_GDK_MAKE_ATOM (5)/' $final
sed -i 's/#define GDK_SELECTION_TYPE_COLORMAP 	_GDK_MAKE_ATOM (7)/#define GDK_SELECTION_TYPE_COLORMAP() 	_GDK_MAKE_ATOM (7)/' $final
sed -i 's/#define GDK_SELECTION_TYPE_DRAWABLE 	_GDK_MAKE_ATOM (17)/#define GDK_SELECTION_TYPE_DRAWABLE() 	_GDK_MAKE_ATOM (17)/' $final
sed -i 's/#define GDK_SELECTION_TYPE_INTEGER 	_GDK_MAKE_ATOM (19)/#define GDK_SELECTION_TYPE_INTEGER() 	_GDK_MAKE_ATOM (19)/' $final
sed -i 's/#define GDK_SELECTION_TYPE_PIXMAP 	_GDK_MAKE_ATOM (20)/#define GDK_SELECTION_TYPE_PIXMAP() 	_GDK_MAKE_ATOM (20)/' $final
sed -i 's/#define GDK_SELECTION_TYPE_WINDOW 	_GDK_MAKE_ATOM (33)/#define GDK_SELECTION_TYPE_WINDOW() 	_GDK_MAKE_ATOM (33)/' $final
sed -i 's/#define GDK_SELECTION_TYPE_STRING 	_GDK_MAKE_ATOM (31)/#define GDK_SELECTION_TYPE_STRING() 	_GDK_MAKE_ATOM (31)/' $final

# we use perl for multiline text replacement -- generally $i is replaced by $j
# we use large blocks even for small fixes, so we can better verify substitution and prevent
# unwanted replacements

# caution, that may replace too large blocks!!!
#perl -0777 -p -i -e 's/#if !?defined.*?error.*?#endif//sg' $final
perl -0777 -p -i -e "s/#if !?defined.*?\n#error.*?\n#endif//g" $final

i='#if defined(GDK_COMPILATION) || defined(GTK_COMPILATION)
#define GDK_THREADS_DEPRECATED _GDK_EXTERN
#else
#define GDK_THREADS_DEPRECATED GDK_DEPRECATED_IN_3_6
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifdef __GI_SCANNER__
/* The introspection scanner is currently unable to lookup how
 * cairo_rectangle_int_t is actually defined. This prevents
 * introspection data for the GdkRectangle type to include fields
 * descriptions. To workaround this issue, we define it with the same
 * content as cairo_rectangle_int_t, but only under the introspection
 * define.
 */
struct _GdkRectangle
{
    int x, y;
    int width, height;
};
typedef struct _GdkRectangle          GdkRectangle;
#else
typedef cairo_rectangle_int_t         GdkRectangle;
#endif
'
j='typedef cairo_rectangle_int_t         GdkRectangle;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

# add missing {} for struct
sed -i 's/typedef struct _GdkDevicePad GdkDevicePad;/typedef struct _GdkDevicePad{} GdkDevicePad;/g' $final
sed -i 's/typedef struct _GdkMonitor      GdkMonitor;/typedef struct _GdkMonitor{} GdkMonitor;/g' $final
sed -i 's/typedef struct _GdkDrawingContext       GdkDrawingContext;/typedef struct _GdkDrawingContext{} GdkDrawingContext;/g' $final
sed -i 's/typedef struct _GdkDeviceTool GdkDeviceTool;/typedef struct _GdkDeviceTool{} GdkDeviceTool;/g' $final
sed -i 's/typedef struct _GdkGLContext          GdkGLContext;/typedef struct _GdkGLContext{} GdkGLContext;/g' $final
sed -i 's/typedef struct _GdkVisual             GdkVisual;/typedef struct _GdkVisual{} GdkVisual;/g' $final
sed -i 's/typedef struct _GdkDevice             GdkDevice;/typedef struct _GdkDevice {}GdkDevice;/g' $final
sed -i 's/typedef struct _GdkWindow             GdkWindow;/typedef struct _GdkWindow{} GdkWindow;/g' $final
sed -i 's/typedef struct _GdkScreen             GdkScreen;/typedef struct _GdkScreen{} GdkScreen;/g' $final
sed -i 's/typedef struct _GdkDisplay            GdkDisplay;/typedef struct _GdkDisplay{} GdkDisplay;/g' $final
sed -i 's/typedef struct _GdkCursor             GdkCursor;/typedef struct _GdkCursor{} GdkCursor;/g' $final
sed -i 's/typedef struct _GdkDragContext        GdkDragContext;/typedef struct _GdkDragContext{} GdkDragContext;/g' $final
sed -i 's/typedef struct _GdkAppLaunchContext   GdkAppLaunchContext;/typedef struct _GdkAppLaunchContext{} GdkAppLaunchContext;/g' $final
sed -i 's/typedef struct _GdkDeviceManager      GdkDeviceManager;/typedef struct _GdkDeviceManager{} GdkDeviceManager;/g' $final
sed -i 's/typedef struct _GdkDisplayManager     GdkDisplayManager;/typedef struct _GdkDisplayManager{} GdkDisplayManager;/g' $final
sed -i 's/typedef struct _GdkKeymap             GdkKeymap;/typedef struct _GdkKeymap{} GdkKeymap;/g' $final
sed -i 's/typedef struct _GdkEventSequence    GdkEventSequence;/typedef struct _GdkEventSequence{} GdkEventSequence;/g' $final
sed -i 's/typedef struct _GdkFrameTimings GdkFrameTimings;/typedef struct _GdkFrameTimings{} GdkFrameTimings;/g' $final
sed -i 's/typedef struct _GdkFrameClock              GdkFrameClock;/typedef struct _GdkFrameClock{} GdkFrameClock;/g' $final
sed -i 's/typedef struct _GdkX11DeviceManagerCore GdkX11DeviceManagerCore;/typedef struct _GdkX11DeviceManagerCore{} GdkX11DeviceManagerCore;/g' $final
sed -i 's/typedef struct _GdkX11DeviceManagerCoreClass GdkX11DeviceManagerCoreClass;/typedef struct _GdkX11DeviceManagerCoreClass{} GdkX11DeviceManagerCoreClass;/g' $final
sed -i 's/typedef struct _GdkX11DeviceManagerXI2 GdkX11DeviceManagerXI2;/typedef struct _GdkX11DeviceManagerXI2{} GdkX11DeviceManagerXI2;/g' $final
sed -i 's/typedef struct _GdkX11DeviceManagerXI2Class GdkX11DeviceManagerXI2Class;/typedef struct _GdkX11DeviceManagerXI2Class{} GdkX11DeviceManagerXI2Class;/g' $final

ruby ../fix_.rb $final

# header for Nim module
i='
#ifdef C2NIM
#  dynlib lib
#endif
'
perl -0777 -p -i -e "s/^/$i/" $final

perl -0777 -p -i -e 's/\n#ifdef GDK_COMPILATION\n#else\n(.*?;\n)#endif\n/\1/g' $final

sed -i 's/\(#define GDK_TYPE_\w\+\)\(\s\+(\?\w\+_get_g\?type\s*()\s*)\?\)/\1()\2/g' $final
sed -i 's/\(#define BROADWAY_TYPE_\w\+\)\(\s\+(\?\w\+_get_g\?type\s*()\s*)\?\)/\1()\2/g' $final

sed -i 's/#define GDK_GL_ERROR       (gdk_gl_error_quark ())/#define GDK_GL_ERROR() (gdk_gl_error_quark ())/g' $final
#ruby ../func_alias_reorder.rb final.h GDK
#ruby ../func_alias_reorder.rb final.h BROADWAY

sed -i 's/\bgchar\b/char/g' $final

sed -i '/#define GDK\_KEY\_.*/ { s/\_/\xFF/g; }' $final
c2nim --nep1 --skipcomments --skipinclude $final
sed -i 's/ {\.bycopy\.}//g' final.nim

sed -i '/  GDK\xFFKEY\xFF.*/ { s/\xFF/_/g; }' final.nim
sed -i "s/^\s*$//g" final.nim
echo -e "\n\n\n\n"  >> final.nim

for i in g_Priority_Default g_Priority_High_Idle ; do
  sed -i "s/\b${i}\b/\U&/g" final.nim
done

for i in MULTIDEVICE_SAFE DISABLE_DEPRECATED ; do
  sed -i "s/ defined\((${i})\)/ \U\1/g" final.nim
done

perl -0777 -p -i -e "s~([=:] proc \(.*?\)(?:: (?:ptr )?\w+)?)~\1 {.cdecl.}~sg" final.nim

# we use our own defined pragma
sed -i "s/\bdynlib: lib\b/libgdk/g" final.nim

i='const
  headerfilename* = '
perl -0777 -p -i -e "s~\Q$i\E~  ### ~sg" final.nim

i=' {.deadCodeElim: on.}'
j='{.deadCodeElim: on.}

when defined(windows):
  const LIB_GDK* = "libgdk-3-0.dll"
elif defined(gtk_quartz):
  const LIB_GDK* = "libgdk-3.0.dylib"
elif defined(macosx):
  const LIB_GDK* = "libgdk-x11-3.0.dylib"
else:
  const LIB_GDK* = "libgdk-3.so(|.0)"

{.pragma: libgdk, cdecl, dynlib: LIB_GDK.}

import IMPORTLIST

const
  GDK_MULTIDEVICE_SAFE = true
  GDK_DISABLE_DEPRECATED = false
  ENABLE_NLS = false
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

sed  -i 's/\bPixbuf\b/GdkPixbuf/g' final.nim
sed  -i 's/\bPangoDirection\b/pango.Direction/g' final.nim
sed  -i 's/  GdkRectangle\* = CairoRectangleIntT/  GdkRectangle* = object/' final.nim

# fix c2nim --nep1 mess. We need this before glib_fix_T.rb call!
sed -i 's/[(][(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/(\1/g' final.nim
sed -i 's/, [(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/, \1/g' final.nim
perl -0777 -p -i -e 's/(  \(.*,)\n/\1/g' final.nim
sed -i 's/\(, \) \+/\1/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Cast\)(\(`\?\w\+`\?, \)\(gdk_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Instance_Get_Interface\)(\(`\?\w\+`\?, \)\(gdk_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Check_Class_Cast\)(\(`\?\w\+`\?, \)\(gdk_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Instance_Get_Class\)(\(`\?\w\+`\?, \)\(gdk_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Type\)(\(`\?\w\+`\?, \)\(gdk_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Class_Type\)(\(`\?\w\+`\?, \)\(gdk_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Value_Type\)(\(`\?\w\+`\?, \)\(gdk_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Fundamental_Type\)(\(`\?\w\+`\?, \)\(gdk_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(gTypeIsA\)(\(`\?\w\+`\?, \)\(gdk_Type_\w\+\))/\1(\2\3)/g' final.nim

sed -i 's/\bgdk\([A-Z]\w\+GetType()\)/\l\1/g' final.nim

ruby ../glib_fix_proc.rb final.nim gdk
ruby ../glib_fix_T.rb final.nim gdk3 Gdk

sed  -i 's/GDK_OWNERSHIP_/GDK_GRAB_OWNERSHIP_/g' final.nim
ruby ../glib_fix_enum_prefix.rb final.nim

sed  -i 's/  GdkRectangleObj\* = object/  GdkRectangleObj* = cairo.RectangleIntObj/' final.nim

sed  -i "s/GDK_KEY_/KEY_/g" final.nim

# Fix this:
# KEY_a* =
# KEY_A* =
# But first fix triples
# KEY_ETH* =
# KEY_Eth* =
# KEY_eth* =
# KEY_THORN* =
# KEY_Thorn* =
# KEY_thorn* =
# KEY_CH* =
# KEY_C_H* =
# KEY_Ch* =
# KEY_C_h* =
# KEY_ch* =
# KEY_c_h* =

sed  -i "s/  KEY_Eth\* =/  KEY_CAP_Eth\* =/" final.nim
sed  -i "s/  KEY_ETH\* =/  KEY_CAPITAL_ETH\* =/" final.nim
sed  -i "s/  KEY_Thorn\* =/  KEY_CAP_Thorn\* =/" final.nim
sed  -i "s/  KEY_THORN\* =/  KEY_CAPITAL_THORN\* =/" final.nim
sed  -i "s/  KEY_CH\* =/  KEY_CAPITAL_C_CAPITAL_H\* =/" final.nim
sed  -i "s/  KEY_Ch\* =/  KEY_CAPITAL_C_h\* =/" final.nim
sed  -i "s/  KEY_C_H\* =/  KEY_CAPITAL_C_UNDERSCORE_CAPITAL_H\* =/" final.nim
sed  -i "s/  KEY_C_h\* =/  KEY_CAPITAL_C_UNDERSCORE_h\* =/" final.nim
sed  -i "s/  KEY_c_h\* =/  KEY_c_UNDERSCORE_h\* =/" final.nim

grep '^  KEY' final.nim | sed 's/\* =.*/\* =/g' | sort -r > temp0.txt

uniq -d -i temp0.txt > temp1.txt

sed -i 's/^/grep -i -o -m 1 "/' temp1.txt

sed -i 's/\* =$/\\* =" temp0.txt >> temp2.txt/' temp1.txt

bash temp1.txt

sed -i 's/  KEY_\(.*\)\* =/s%  KEY_\1\\\* =%  KEY_CAPITAL_\1\\\* =%/' temp2.txt

sed -i -f temp2.txt final.nim

rm temp?.txt

i='type
  GdkEventType* {.size: sizeof(cint), pure.} = enum
    NOTHING = - 1, DELETE = 0, DESTROY = 1, EXPOSE = 2,
    MOTION_NOTIFY = 3, BUTTON_PRESS = 4, 2BUTTON_PRESS = 5,
    DOUBLE_BUTTON_PRESS = gdk_2button_Press, 3BUTTON_PRESS = 6,
    TRIPLE_BUTTON_PRESS = gdk_3button_Press, BUTTON_RELEASE = 7,
    KEY_PRESS = 8, KEY_RELEASE = 9, ENTER_NOTIFY = 10, LEAVE_NOTIFY = 11,
    FOCUS_CHANGE = 12, CONFIGURE = 13, MAP = 14, UNMAP = 15,
    PROPERTY_NOTIFY = 16, SELECTION_CLEAR = 17, SELECTION_REQUEST = 18,
    SELECTION_NOTIFY = 19, PROXIMITY_IN = 20, PROXIMITY_OUT = 21,
    DRAG_ENTER = 22, DRAG_LEAVE = 23, DRAG_MOTION = 24, DRAG_STATUS = 25,
    DROP_START = 26, DROP_FINISHED = 27, CLIENT_EVENT = 28,
    VISIBILITY_NOTIFY = 29, SCROLL = 31, WINDOW_STATE = 32, SETTING = 33,
    OWNER_CHANGE = 34, GRAB_BROKEN = 35, DAMAGE = 36, TOUCH_BEGIN = 37,
    TOUCH_UPDATE = 38, TOUCH_END = 39, TOUCH_CANCEL = 40,
    TOUCHPAD_SWIPE = 41, TOUCHPAD_PINCH = 42, PAD_BUTTON_PRESS = 43,
    PAD_BUTTON_RELEASE = 44, PAD_RING = 45, PAD_STRIP = 46,
    PAD_GROUP_MODE = 47, EVENT_LAST
'
j='type
  GdkEventType* {.size: sizeof(cint), pure.} = enum
    NOTHING = - 1, DELETE = 0, DESTROY = 1, EXPOSE = 2,
    MOTION_NOTIFY = 3, BUTTON_PRESS = 4, BUTTON2_PRESS = 5,
    BUTTON3_PRESS = 6,
    BUTTON_RELEASE = 7,
    KEY_PRESS = 8, KEY_RELEASE = 9, ENTER_NOTIFY = 10, LEAVE_NOTIFY = 11,
    FOCUS_CHANGE = 12, CONFIGURE = 13, MAP = 14, UNMAP = 15,
    PROPERTY_NOTIFY = 16, SELECTION_CLEAR = 17, SELECTION_REQUEST = 18,
    SELECTION_NOTIFY = 19, PROXIMITY_IN = 20, PROXIMITY_OUT = 21,
    DRAG_ENTER = 22, DRAG_LEAVE = 23, DRAG_MOTION = 24, DRAG_STATUS = 25,
    DROP_START = 26, DROP_FINISHED = 27, CLIENT_EVENT = 28,
    VISIBILITY_NOTIFY = 29, SCROLL = 31, WINDOW_STATE = 32, SETTING = 33,
    OWNER_CHANGE = 34, GRAB_BROKEN = 35, DAMAGE = 36, TOUCH_BEGIN = 37,
    TOUCH_UPDATE = 38, TOUCH_END = 39, TOUCH_CANCEL = 40,
    TOUCHPAD_SWIPE = 41, TOUCHPAD_PINCH = 42, PAD_BUTTON_PRESS = 43,
    PAD_BUTTON_RELEASE = 44, PAD_RING = 45, PAD_STRIP = 46,
    PAD_GROUP_MODE = 47, EVENT_LAST

const
  DOUBLE_BUTTON_PRESS = GdkEventType.BUTTON2_PRESS
  TRIPLE_BUTTON_PRESS = GdkEventType.BUTTON3_PRESS
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GdkEventMask* {.size: sizeof(cint), pure.} = enum
    EXPOSURE_MASK = 1 shl 1, POINTER_MOTION_MASK = 1 shl 2,
    POINTER_MOTION_HINT_MASK = 1 shl 3, BUTTON_MOTION_MASK = 1 shl 4,
    BUTTON1_MOTION_MASK = 1 shl 5, BUTTON2_MOTION_MASK = 1 shl 6,
    BUTTON3_MOTION_MASK = 1 shl 7, BUTTON_PRESS_MASK = 1 shl 8,
    BUTTON_RELEASE_MASK = 1 shl 9, KEY_PRESS_MASK = 1 shl 10,
    KEY_RELEASE_MASK = 1 shl 11, ENTER_NOTIFY_MASK = 1 shl 12,
    LEAVE_NOTIFY_MASK = 1 shl 13, FOCUS_CHANGE_MASK = 1 shl 14,
    STRUCTURE_MASK = 1 shl 15, PROPERTY_CHANGE_MASK = 1 shl 16,
    VISIBILITY_NOTIFY_MASK = 1 shl 17, PROXIMITY_IN_MASK = 1 shl 18,
    PROXIMITY_OUT_MASK = 1 shl 19, SUBSTRUCTURE_MASK = 1 shl 20,
    SCROLL_MASK = 1 shl 21, TOUCH_MASK = 1 shl 22,
    SMOOTH_SCROLL_MASK = 1 shl 23, TOUCHPAD_GESTURE_MASK = 1 shl 24,
    TABLET_PAD_MASK = 1 shl 25, ALL_EVENTS_MASK = 0x00FFFFFE
'
j='type
  GdkEventMask* {.size: sizeof(cint), pure.} = enum
    EXPOSURE_MASK = 1 shl 1, POINTER_MOTION_MASK = 1 shl 2,
    POINTER_MOTION_HINT_MASK = 1 shl 3, BUTTON_MOTION_MASK = 1 shl 4,
    BUTTON1_MOTION_MASK = 1 shl 5, BUTTON2_MOTION_MASK = 1 shl 6,
    BUTTON3_MOTION_MASK = 1 shl 7, BUTTON_PRESS_MASK = 1 shl 8,
    BUTTON_RELEASE_MASK = 1 shl 9, KEY_PRESS_MASK = 1 shl 10,
    KEY_RELEASE_MASK = 1 shl 11, ENTER_NOTIFY_MASK = 1 shl 12,
    LEAVE_NOTIFY_MASK = 1 shl 13, FOCUS_CHANGE_MASK = 1 shl 14,
    STRUCTURE_MASK = 1 shl 15, PROPERTY_CHANGE_MASK = 1 shl 16,
    VISIBILITY_NOTIFY_MASK = 1 shl 17, PROXIMITY_IN_MASK = 1 shl 18,
    PROXIMITY_OUT_MASK = 1 shl 19, SUBSTRUCTURE_MASK = 1 shl 20,
    SCROLL_MASK = 1 shl 21, TOUCH_MASK = 1 shl 22,
    SMOOTH_SCROLL_MASK = 1 shl 23,
    ALL_EVENTS_MASK = 0x00FFFFFE,
    TOUCHPAD_GESTURE_MASK = 1 shl 24,
    TABLET_PAD_MASK = 1 shl 25
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GdkAxisFlags* {.size: sizeof(cint), pure.} = enum
    FLAG_X = 1 shl gdk_Axis_X, FLAG_Y = 1 shl gdk_Axis_Y,
    FLAG_PRESSURE = 1 shl gdk_Axis_Pressure,
    FLAG_XTILT = 1 shl gdk_Axis_Xtilt,
    FLAG_YTILT = 1 shl gdk_Axis_Ytilt,
    FLAG_WHEEL = 1 shl gdk_Axis_Wheel,
    FLAG_DISTANCE = 1 shl gdk_Axis_Distance,
    FLAG_ROTATION = 1 shl gdk_Axis_Rotation,
    FLAG_SLIDER = 1 shl gdk_Axis_Slider
'
j='type
  GdkAxisFlags* {.size: sizeof(cint), pure.} = enum
    FLAG_X = 1 shl GdkAxisUse.X.ord, FLAG_Y = 1 shl GdkAxisUse.Y.ord,
    FLAG_PRESSURE = 1 shl GdkAxisUse.PRESSURE.ord,
    FLAG_XTILT = 1 shl GdkAxisUse.XTILT.ord,
    FLAG_YTILT = 1 shl GdkAxisUse.YTILT.ord,
    FLAG_WHEEL = 1 shl GdkAxisUse.WHEEL.ord,
    FLAG_DISTANCE = 1 shl GdkAxisUse.DISTANCE.ord,
    FLAG_ROTATION = 1 shl GdkAxisUse.ROTATION.ord,
    FLAG_SLIDER = 1 shl GdkAxisUse.SLIDER.ord
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GdkAnchorHints* {.size: sizeof(cint), pure.} = enum
    FLIP_X = 1 shl 0, FLIP_Y = 1 shl 1,
    SLIDE_X = 1 shl 2, SLIDE_Y = 1 shl 3,
    RESIZE_X = 1 shl 4, RESIZE_Y = 1 shl 5,
    FLIP = gdk_Anchor_Flip_X or gdk_Anchor_Flip_Y,
    SLIDE = gdk_Anchor_Slide_X or gdk_Anchor_Slide_Y,
    RESIZE = gdk_Anchor_Resize_X or gdk_Anchor_Resize_Y
'
j='type
  GdkAnchorHints* {.size: sizeof(cint), pure.} = enum
    FLIP_X = 1 shl 0, FLIP_Y = 1 shl 1,
    FLIP = GdkAnchorHints.FLIP_X.ord or GdkAnchorHints.FLIP_Y.ord,
    SLIDE_X = 1 shl 2, SLIDE_Y = 1 shl 3,
    SLIDE = GdkAnchorHints.SLIDE_X.ord or GdkAnchorHints.SLIDE_Y.ord,
    RESIZE_X = 1 shl 4, RESIZE_Y = 1 shl 5,
    RESIZE = GdkAnchorHints.RESIZE_X.ord or GdkAnchorHints.RESIZE_Y.ord
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GdkSeatGrabPrepareFunc* = proc (seat: GdkSeat; window: GdkWindow;
                               userData: Gpointer) {.cdecl.}
  GdkSeat* =  ptr GdkSeatObj
  GdkSeatPtr* = ptr GdkSeatObj
  GdkSeatObj* = object
    parentInstance*: GObject
'
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim
j='type
  GdkDeviceType* {.size: sizeof(cint), pure.} = enum
    MASTER, SLAVE, FLOATING
'
perl -0777 -p -i -e "s/\Q$j\E/$j$i/s" final.nim

i='type
  GdkEventFunc* = proc (event: GdkEvent; data: Gpointer) {.cdecl.}


type
  GdkXEvent* = nil


type
  GdkFilterReturn* {.size: sizeof(cint), pure.} = enum
    `CONTINUE`, TRANSLATE, REMOVE



type
  GdkFilterFunc* = proc (xevent: ptr GdkXEvent; event: GdkEvent; data: Gpointer): GdkFilterReturn {.cdecl.}
'
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim

j='type
  GdkEvent* =  ptr GdkEventObj
  GdkEventPtr* = ptr GdkEventObj
  GdkEventObj* = object {.union.}
    `type`*: GdkEventType
    any*: GdkEventAnyObj
    expose*: GdkEventExposeObj
    visibility*: GdkEventVisibilityObj
    motion*: GdkEventMotionObj
    button*: GdkEventButtonObj
    touch*: GdkEventTouchObj
    scroll*: GdkEventScrollObj
    key*: GdkEventKeyObj
    crossing*: GdkEventCrossingObj
    focusChange*: GdkEventFocusObj
    configure*: GdkEventConfigureObj
    property*: GdkEventPropertyObj
    selection*: GdkEventSelectionObj
    ownerChange*: GdkEventOwnerChangeObj
    proximity*: GdkEventProximityObj
    dnd*: GdkEventDNDObj
    windowState*: GdkEventWindowStateObj
    setting*: GdkEventSettingObj
    grabBroken*: GdkEventGrabBrokenObj
    touchpadSwipe*: GdkEventTouchpadSwipeObj
    touchpadPinch*: GdkEventTouchpadPinchObj
    padButton*: GdkEventPadButtonObj
    padAxis*: GdkEventPadAxisObj
    padGroupMode*: GdkEventPadGroupModeObj
'
perl -0777 -p -i -e "s/\Q$j\E/$j$i/s" final.nim

i='type
  GdkColor* =  ptr GdkColorObj
  GdkColorPtr* = ptr GdkColorObj
  GdkColorObj* = object
    pixel*: Guint32
    red*: Guint16
    green*: Guint16
    blue*: Guint16
'
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim
k='type
  GdkRGBA* =  ptr GdkRGBAObj
  GdkRGBAPtr* = ptr GdkRGBAObj
  GdkRGBAObj* = object
    red*: Gdouble
    green*: Gdouble
    blue*: Gdouble
    alpha*: Gdouble
'
perl -0777 -p -i -e "s/\Q$k\E//s" final.nim
j='type
  GdkWindowInvalidateHandlerFunc* = proc (window: GdkWindow;
                                       region: ptr CairoRegionT) {.cdecl.}
'
perl -0777 -p -i -e "s/\Q$j\E/$j$i$k/s" final.nim

i='type
  GdkSeatCapabilities* {.size: sizeof(cint), pure.} = enum
    CAPABILITY_NONE = 0, CAPABILITY_POINTER = 1 shl 0,
    CAPABILITY_TOUCH = 1 shl 1, CAPABILITY_TABLET_STYLUS = 1 shl 2,
    CAPABILITY_KEYBOARD = 1 shl 3, CAPABILITY_ALL_POINTING = (gdk_Seat_Capability_Pointer or
        gdk_Seat_Capability_Touch or gdk_Seat_Capability_Tablet_Stylus), GDK_SEAT_CAPABILITY_ALL = (
        gdk_Seat_Capability_All_Pointing or gdk_Seat_Capability_Keyboard)
'
j='type
  GdkSeatCapabilities* {.size: sizeof(cint), pure.} = enum
    NONE = 0, POINTER = 1 shl 0,
    TOUCH = 1 shl 1, TABLET_STYLUS = 1 shl 2,
    ALL_POINTING = GdkSeatCapabilities.POINTER.ord or GdkSeatCapabilities.TOUCH.ord or GdkSeatCapabilities.TABLET_STYLUS.ord,
    KEYBOARD = 1 shl 3,
    ALL = GdkSeatCapabilities.ALL_POINTING.ord or GdkSeatCapabilities.KEYBOARD.ord
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

sed  -i "s/gdk_Max_Timecoord_Axes/GDK_MAX_TIMECOORD_AXES/g" final.nim
sed  -i "s/GdkAtom\* = ptr gdkAtom/GdkAtom\* = ptr object/g" final.nim

# do not export priv and reserved
sed -i "s/\( priv[0-9]\?[0-9]\?[0-9]\?\)\*: /\1: /g" final.nim
sed -i "s/\(reserved[0-9]\?[0-9]\?[0-9]\?\)\*: /\1: /g" final.nim

sed -i -f ../glib_sedlist final.nim
sed -i -f ../gobject_sedlist final.nim
sed -i -f ../cairo_sedlist final.nim
sed -i -f ../pango_sedlist final.nim
sed -i -f ../gdk_pixbuf_sedlist final.nim
sed -i -f ../gio_sedlist final.nim

i='type
  GdkGLProfile* {.size: sizeof(cint), pure.} = enum
    DEFAULT, 3_2_CORE
'
j='type
  GdkGLProfile* {.size: sizeof(cint), pure.} = enum
    DEFAULT, GL_3_2_CORE
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

sed -i "s/\bFALSE\b/G&/g" final.nim
sed -i "s/\bTRUE\b/G&/g" final.nim

sed -i "s/  GdkXEvent\* = nil/  GdkXEvent* = proc () {.cdecl.}/g" final.nim

sed -i 's/\bproc raise\b/proc `raise`/g' final.nim
sed -i 's/^proc ref\*(/proc `ref`\*(/g' final.nim

sed -i 's/\bXID\b/x.TXID/' final.nim
sed -i 's/\bVisualID\b/x.TVisualID/' final.nim
sed -i 's/\bVisual\b/xlib.TVisual/' final.nim
sed -i 's/\bScreen\b/xlib.TScreen/' final.nim
sed -i 's/\bWindow\b/x.TWindow/' final.nim
sed -i 's/\bCursor\b/x.TCursor/' final.nim
sed -i 's/\bDisplay\b/xlib.TDisplay/' final.nim
sed -i 's/\bAtom\b/x.TAtom/' final.nim

# we need this here -- before mangler GDK call!
sed -i 's/  GDK_OSX_TIGER = GDK_OSX_MIN/  GDK_OSX_TIGER = GdkOSXVersion.OSX_MIN/' final.nim
sed -i 's/  GDK_OSX_CURRENT = GDK_OSX_MOUNTAIN_LION/  GDK_OSX_CURRENT = GdkOSXVersion.OSX_MOUNTAIN_LION/' final.nim

i="  BroadwayEventType* {.size: sizeof(cint), pure.} = enum
    ENTER = 'e', LEAVE = 'l',
    POINTER_MOVE = 'm', BUTTON_PRESS = 'b',
    BUTTON_RELEASE = 'B', TOUCH = 't',
    SCROLL = 's', KEY_PRESS = 'k',
    KEY_RELEASE = 'K', GRAB_NOTIFY = 'g',
    UNGRAB_NOTIFY = 'u', CONFIGURE_NOTIFY = 'w',
    DELETE_NOTIFY = 'W', SCREEN_SIZE_CHANGED = 'd',
    FOCUS = 'f'
  BroadwayOpType* {.size: sizeof(cint), pure.} = enum
    GRAB_POINTER = 'g', UNGRAB_POINTER = 'u',
    NEW_SURFACE = 's', SHOW_SURFACE = 'S',
    HIDE_SURFACE = 'H', RAISE_SURFACE = 'r',
    LOWER_SURFACE = 'R', DESTROY_SURFACE = 'd',
    MOVE_RESIZE = 'm', SET_TRANSIENT_FOR = 'p',
    PUT_RGB = 'i', REQUEST_AUTH = 'l',
    AUTH_OK = 'L', DISCONNECTED = 'D',
    PUT_BUFFER = 'b', SET_SHOW_KEYBOARD = 'k'
"
j="
  BroadwayEventType* {.size: sizeof(cint), pure.} = enum
    BUTTON_RELEASE = 'B',
    KEY_RELEASE = 'K',
    DELETE_NOTIFY = 'W',
    BUTTON_PRESS = 'b',
    SCREEN_SIZE_CHANGED = 'd',
    ENTER = 'e',
    FOCUS = 'f'
    GRAB_NOTIFY = 'g',
    KEY_PRESS = 'k',
    LEAVE = 'l',
    POINTER_MOVE = 'm',
    SCROLL = 's',
    TOUCH = 't',
    UNGRAB_NOTIFY = 'u',
    CONFIGURE_NOTIFY = 'w',
  BroadwayOpType* {.size: sizeof(cint), pure.} = enum
    DISCONNECTED = 'D',
    HIDE_SURFACE = 'H',
    AUTH_OK = 'L',
    LOWER_SURFACE = 'R',
    SHOW_SURFACE = 'S',
    PUT_BUFFER = 'b',
    DESTROY_SURFACE = 'd',
    GRAB_POINTER = 'g',
    PUT_RGB = 'i',
    SET_SHOW_KEYBOARD = 'k'
    REQUEST_AUTH = 'l',
    MOVE_RESIZE = 'm',
    SET_TRANSIENT_FOR = 'p',
    RAISE_SURFACE = 'r',
    NEW_SURFACE = 's',
    UNGRAB_POINTER = 'u',
"
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

i='import IMPORTLIST
'
j='from glib import Gunichar, Gboolean, Gpointer, Gconstpointer, GFALSE, GTRUE, G_PRIORITY_DEFAULT, G_PRIORITY_HIGH_IDLE, GDestroyNotify, GQuark, GSourceFunc

from gobject import GObject, GObjectObj, GType, GValue, GCallback, GObjectClassObj

from gio import GIcon

from gdk_pixbuf import GdkPixbuf

from cairo import Context, FontOptions

from pango import LayoutLine, Layout, Context, Direction

type
  RectangleIntObj = cairo.Rectangle_intObj
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

i='when defined(INSIDE_GDK_WIN32) or defined(GDK_COMPILATION) or
    defined(GTK_COMPILATION):
'
j='when false: #when defined(INSIDE_GDK_WIN32) or defined(GDK_COMPILATION) or defined(GTK_COMPILATION):
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

sed -i 's/when defined(GTK_COMPILATION) or defined(GDK_COMPILATION):/when false: # &/g' final.nim

sed -i 's/when not(defined(GDK_MULTIDEVICE_SAFE)):/when not GDK_MULTIDEVICE_SAFE: # &/g' final.nim
sed -i 's/when not defined(GDK_MULTIDEVICE_SAFE):/when not GDK_MULTIDEVICE_SAFE: # &/g' final.nim
sed -i 's/when not defined(DISABLE_DEPRECATED):/when not GDK_DISABLE_DEPRECATED: # &/g' final.nim
sed -i 's/when defined(ENABLE_NLS):/when ENABLE_NLS: # &/g' final.nim
sed -i 's/when defined(INSIDE_GDK_WIN32):/when INSIDE_GDK_WIN32: # &/g' final.nim

sed -i 's/\(dummy[0-9]\?\)\*/\1/g' final.nim
sed -i 's/\(reserved[0-9]\?\)\*/\1/g' final.nim

sed -i 's/[(][(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/(\1/g' final.nim
sed -i 's/, [(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/, \1/g' final.nim

sed -i 's/\([,=(<>] \{0,1\}\)[(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/\1\2/g' final.nim
sed -i '/^ \? \?#type $/d' final.nim
sed -i 's/\bgobject\.GObjectObj\b/GObjectObj/g' final.nim
sed -i 's/\bgobject\.GObject\b/GObject/g' final.nim
sed -i 's/\bgobject\.GObjectClassObj\b/GObjectClassObj/g' final.nim

sed -i 's/ ptr var / var ptr /g' final.nim

# the gobject lower case templates
sed -i 's/\bg_Type_Check_Instance_Cast\b/gTypeCheckInstanceCast/g' final.nim
sed -i 's/\bg_Type_Check_Instance_Type\b/gTypeCheckInstanceType/g' final.nim
sed -i 's/\bg_Type_Instance_Get_Interface\b/gTypeInstanceGetInterface/g' final.nim
sed -i 's/\bg_Type_Check_Class_Cast\b/gTypeCheckClassCast/g' final.nim
sed -i 's/\bg_Type_Check_Class_Type\b/gTypeCheckClassType/g' final.nim
sed -i 's/\bg_Type_Instance_Get_Class\b/gTypeInstanceGetClass/g' final.nim
sed -i 's/\bgTypeIsA\b/isA/g' final.nim

perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gdouble)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gdouble)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( cint)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( cint)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( GdkModifierType)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gboolean)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( GdkDragProtocol)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( GdkScrollDirection)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( cstring)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Guchar)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gpointer)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( GdkAtom)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( GdkWMDecoration)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( GdkVisualType)/\1\2\3\4var\6/sg' final.nim

sed -i 's/: ptr var /: var ptr /g' final.nim
sed -i 's/\(0x\)0*\([0123456789ABCDEF]\)/\1\2/g' final.nim

ruby ../fix_object_of.rb final.nim

i='  BroadwayInputBaseMsgObj* = object
    `type`*: Guint32
'
j='  BroadwayInputBaseMsgObj{.inheritable, pure.} = object
    `type`*: Guint32
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

i='  BroadwayReplyBaseObj* = object
    size*: Guint32
'
j='  BroadwayReplyBaseObj{.inheritable, pure.} = object
    size*: Guint32
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

i='  BroadwayRequestBaseObj* = object
    size*: Guint32
'
j='  BroadwayRequestBaseObj{.inheritable, pure.} = object
    size*: Guint32
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

fix2objof="GdkScreen GdkWindow GdkDisplay GdkDisplayManager GdkVisual GdkCursor GdkDragContext GdkGLContext GdkDevice GdkDeviceManager GdkFrameClock GdkKeymap"
for i in $fix2objof ; do
  sed -i "s/  ${i}Obj\* = object/  ${i}Obj\*{.final.} = object of GObject/g" final.nim
done

ruby ../mangler.rb final.nim GDK_
ruby ../mangler.rb final.nim Gdk

i='type
  InputSource* {.size: sizeof(cint), pure.} = enum
    SOURCE_MOUSE, SOURCE_PEN, SOURCE_ERASER, SOURCE_CURSOR,
    SOURCE_KEYBOARD, SOURCE_TOUCHSCREEN, SOURCE_TOUCHPAD



type
  InputMode* {.size: sizeof(cint), pure.} = enum
    MODE_DISABLED, MODE_SCREEN, MODE_WINDOW
'
j='type
  InputSource* {.size: sizeof(cint), pure.} = enum
    MOUSE, PEN, ERASER, CURSOR,
    KEYBOARD, TOUCHSCREEN, TOUCHPAD
type
  InputMode* {.size: sizeof(cint), pure.} = enum
    DISABLED, SCREEN, WINDOW
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

i='type
  DragAction* {.size: sizeof(cint), pure.} = enum
    ACTION_DEFAULT = 1 shl 0, ACTION_COPY = 1 shl 1, ACTION_MOVE = 1 shl 2,
    ACTION_LINK = 1 shl 3, ACTION_PRIVATE = 1 shl 4, ACTION_ASK = 1 shl 5



type
  DragCancelReason* {.size: sizeof(cint), pure.} = enum
    NO_TARGET, USER_CANCELLED,
    ERROR



type
  DragProtocol* {.size: sizeof(cint), pure.} = enum
    PROTO_NONE = 0, PROTO_MOTIF, PROTO_XDND,
    PROTO_ROOTWIN, PROTO_WIN32_DROPFILES, PROTO_OLE2,
    PROTO_LOCAL, PROTO_WAYLAND
'
j='type
  DragAction* {.size: sizeof(cint), pure.} = enum
    DEFAULT = 1 shl 0, COPY = 1 shl 1, MOVE = 1 shl 2,
    LINK = 1 shl 3, PRIVATE = 1 shl 4, ASK = 1 shl 5

type
  DragCancelReason* {.size: sizeof(cint), pure.} = enum
    NO_TARGET, USER_CANCELLED,
    ERROR

type
  DragProtocol* {.size: sizeof(cint), pure.} = enum
    NONE = 0, MOTIF, XDND,
    ROOTWIN, WIN32_DROPFILES, OLE2,
    LOCAL, WAYLAND
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim


i='type
  WindowAttributesType* {.size: sizeof(cint), pure.} = enum
    WA_TITLE = 1 shl 1, WA_X = 1 shl 2, WA_Y = 1 shl 3, WA_CURSOR = 1 shl 4,
    WA_VISUAL = 1 shl 5, WA_WMCLASS = 1 shl 6, WA_NOREDIR = 1 shl 7,
    WA_TYPE_HINT = 1 shl 8



type
  WindowHints* {.size: sizeof(cint), pure.} = enum
    HINT_POS = 1 shl 0, HINT_MIN_SIZE = 1 shl 1, HINT_MAX_SIZE = 1 shl 2,
    HINT_BASE_SIZE = 1 shl 3, HINT_ASPECT = 1 shl 4,
    HINT_RESIZE_INC = 1 shl 5, HINT_WIN_GRAVITY = 1 shl 6,
    HINT_USER_POS = 1 shl 7, HINT_USER_SIZE = 1 shl 8



type
  WMDecoration* {.size: sizeof(cint), pure.} = enum
    DECOR_ALL = 1 shl 0, DECOR_BORDER = 1 shl 1, DECOR_RESIZEH = 1 shl 2,
    DECOR_TITLE = 1 shl 3, DECOR_MENU = 1 shl 4, DECOR_MINIMIZE = 1 shl 5,
    DECOR_MAXIMIZE = 1 shl 6



type
  WMFunction* {.size: sizeof(cint), pure.} = enum
    FUNC_ALL = 1 shl 0, FUNC_RESIZE = 1 shl 1, FUNC_MOVE = 1 shl 2,
    FUNC_MINIMIZE = 1 shl 3, FUNC_MAXIMIZE = 1 shl 4, FUNC_CLOSE = 1 shl 5
'
j='type
  WindowAttributesType* {.size: sizeof(cint), pure.} = enum
    TITLE = 1 shl 1, X = 1 shl 2, Y = 1 shl 3, CURSOR = 1 shl 4,
    VISUAL = 1 shl 5, WMCLASS = 1 shl 6, NOREDIR = 1 shl 7,
    TYPE_HINT = 1 shl 8

type
  WindowHints* {.size: sizeof(cint), pure.} = enum
    POS = 1 shl 0, MIN_SIZE = 1 shl 1, MAX_SIZE = 1 shl 2,
    BASE_SIZE = 1 shl 3, ASPECT = 1 shl 4,
    RESIZE_INC = 1 shl 5, WIN_GRAVITY = 1 shl 6,
    USER_POS = 1 shl 7, USER_SIZE = 1 shl 8

type
  WMDecoration* {.size: sizeof(cint), pure.} = enum
    ALL = 1 shl 0, BORDER = 1 shl 1, RESIZEH = 1 shl 2,
    TITLE = 1 shl 3, MENU = 1 shl 4, MINIMIZE = 1 shl 5,
    MAXIMIZE = 1 shl 6

type
  WMFunction* {.size: sizeof(cint), pure.} = enum
    ALL = 1 shl 0, RESIZE = 1 shl 1, MOVE = 1 shl 2,
    MINIMIZE = 1 shl 3, MAXIMIZE = 1 shl 4, CLOSE = 1 shl 5
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

i='type
  OSXVersion* {.size: sizeof(cint), pure.} = enum
    OSX_UNSUPPORTED = 0, OSX_MIN = 4, OSX_LEOPARD = 5,
    OSX_SNOW_LEOPARD = 6, OSX_LION = 7, OSX_MOUNTAIN_LION = 8,
    OSX_NEW = 99

const
  OSX_TIGER = OSXVersion.OSX_MIN
  OSX_CURRENT = OSXVersion.OSX_MOUNTAIN_LION
'
j='type
  OSXVersion* {.size: sizeof(cint), pure.} = enum
    UNSUPPORTED = 0, MIN = 4, LEOPARD = 5,
    SNOW_LEOPARD = 6, LION = 7, MOUNTAIN_LION = 8,
    NEW = 99

const
  OSX_TIGER = OSXVersion.MIN
  OSX_CURRENT = OSXVersion.MOUNTAIN_LION
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

sed  -i 's/\bPixbuf\b/GdkPixbuf/g' final.nim

# some procs with get_ prefix do not return something but need var objects instead of pointers:
# vim search term for candidates: proc get_.*\n\?.*\n\?.*) {

for i in uint8 uint16 uint32 uint64 int8 int16 int32 int64 ; do
  sed -i "s/\bG${i}\b/${i}/g" final.nim
done

sed -i "s/ $//g" final.nim
sed -i 's/\* = gdk\([A-Z]\)/* = \L\1/g' final.nim

ruby ../fix_template.rb final.nim gdk

sed -i "s/\bGint\b/cint/g" final.nim
sed -i "s/\bGuint\b/cuint/g" final.nim
sed -i "s/\bGfloat\b/cfloat/g" final.nim
sed -i "s/\bGdouble\b/cdouble/g" final.nim
sed -i "s/\bGshort\b/cshort/g" final.nim
sed -i "s/\bGushort\b/cushort/g" final.nim
sed -i "s/\bGlong\b/clong/g" final.nim
sed -i "s/\bGulong\b/culong/g" final.nim
sed -i "s/\bGuchar\b/cuchar/g" final.nim

sed -i "s/gdk_pixbuf\.//g" final.nim

i='when ENABLE_NLS: # when defined(ENABLE_NLS):
  template p*(string: expr): expr =
    dgettext(gettext_Package, "-properties", string)

else:
  template p*(string: expr): expr =
    (string)

const
  CURRENT_TIME* = 0

const
  PARENT_RELATIVE* = 1
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim

sed -i "s/\bgdkAtom\b/Atom/g" final.nim

i='template makeAtom*(val: expr): expr =
  (cast[Atom](guint_To_Pointer(val)))
'
j='template makeAtom*(val: expr): expr =
  Atom(val)
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

# generate procs without get_ and set_ prefix
perl -0777 -p -i -e "s/(\n\s*)(proc set)([A-Z]\w+)(\*\([^}]*\) \{[^}]*})/\$&\1proc \`\l\3=\`\4/sg" final.nim
perl -0777 -p -i -e "s/(\n\s*)(proc get)([A-Z]\w+)(\*\([^}]*\): \w[^}]*})/\$&\1proc \l\3\4/sg" final.nim

i='template threadsEnter*(): expr =
  gdkThreadsEnter()

template threadsLeave*(): expr =
  gdkThreadsLeave()
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim

sed -i 's/= (1 shl \([0-9]\)),/= 1 shl \1,/g' final.nim
sed -i 's/= (1 shl \([0-9]\))$/= 1 shl \1/g' final.nim

sed -i 's/\(proc \w\+New\)[A-Z]\w\+/\1/g' final.nim
sed -i 's/proc \(\w\+\)New\*/proc new\u\1*/g' final.nim

# now separate the x11, win32, wayland, broadway, quartz, mir sub-modules.
# cut broadway module
### "gdk/broadway/gdkbroadwaydisplay.h"
i='### ["]gdk[/]broadway.*'
csplit final.nim "/$i/"
mv xx00 final.nim
j='{.deadCodeElim: on.}

{.pragma: libgdk, cdecl, dynlib: LIB_GDK.}

import gdk3

from glib import Gboolean

from cairo import Surface, Region

from gobject import GType

from gio import GOutputStream

type # broadway dummy objects
  BroadwayBuffer* = object
  BroadwayServer* = object
  BroadwayOutput* = object
'
perl -0777 -p -i -e "s~$i~$j~" xx01
sed -i "\~$i~d" xx01
sed -i "\~  BroadwayOutput\* = broadwayOutput~d" xx01
i='const
  BROADWAY_TYPE_SERVER* = broadwayServerGetType
'
perl -0777 -p -i -e "s~\Q$i\E~~s" xx01

cat -s xx01 > gdk3_broadway.nim

# cut mir module
### "gdk/mir/gdkmir.h"
i='### ["]gdk[/]mir.*'
csplit final.nim "/$i/"
mv xx00 final.nim
j='{.deadCodeElim: on.}

{.pragma: libgdk, cdecl, dynlib: LIB_GDK.}

import gdk3

from gobject import GType

type # unity mir dummy objects
  MirConnection* = object
  MirSurface* = object
'
perl -0777 -p -i -e "s~$i~$j~" xx01
sed -i "\~$i~d" xx01
cat -s xx01 > gdk3_mir.nim

# cut quartz module
### "gdk/quartz/gdkquartz.h"
i='### ["]gdk[/]quartz.*'
csplit final.nim "/$i/"
mv xx00 final.nim
j='{.deadCodeElim: on.}

{.pragma: libgdk, cdecl, dynlib: LIB_GDK.}

import gdk3 except cursorGetType, displayGetType, displayManagerGetType, dragContextGetType, keymapGetType, screenGetType, visualGetType, windowGetType

from glib import Gunichar

from gobject import GType

from gdk_pixbuf import GdkPixbuf

type # macosx quartz dummy objects
  NSString* = object
  NSImage* = object
  NSEvent* = object
  NSWindow* = object
  NSView* = object
  Id* = culong
'
perl -0777 -p -i -e "s~$i~$j~" xx01
sed -i "\~$i~d" xx01
i='const
  __GDKQUARTZ_H_INSIDE__* = true
'
perl -0777 -p -i -e "s~\Q$i\E~~s" xx01

sed -i '/  QuartzDisplayManagerClass\* = displayManagerClass/d' xx01
sed  -i "s/\(proc quartz\)\([A-Z]\)\(\.*\)/proc \l\2\3/g" xx01
ruby ../glib_fix_proc.rb xx01 ''
sed -i 's/\* = quartz\([A-Z]\)/* = \L\1/g' xx01
cat -s xx01 > gdk3_quartz.nim

# cut wayland module
### "gdk/wayland/gdkwaylanddevice.h"
i='### ["]gdk[/]wayland.*'
csplit final.nim "/$i/"
mv xx00 final.nim
j='{.deadCodeElim: on.}

{.pragma: libgdk, cdecl, dynlib: LIB_GDK.}

import gdk3 except deviceGetType, displayGetType, windowGetType, glContextGetType

from gobject import GType

from glib import GPointer, GDestroyNotify, Gboolean

type # wayland dummy objects
  WlSeat* = object
  WlPointer* = object
  WlOutput* = object
  WlKeyboard* = object
  WlDisplay* = object
  WlCompositor* = object
  WlSurface* = object
  XdgShell* = object
'
perl -0777 -p -i -e "s~$i~$j~" xx01
sed -i "\~$i~d" xx01
sed  -i "s/\(proc wayland\)\([A-Z]\)\(\.*\)/proc \l\2\3/g" xx01
ruby ../glib_fix_proc.rb xx01 ''
sed -i 's/\* = wayland\([A-Z]\)/* = \L\1/g' xx01
cat -s xx01 > gdk3_wayland.nim

# cut win32 module
### "gdk/win32/gdkwin32cursor.h"
i='### ["]gdk[/]win32.*'
csplit final.nim "/$i/"
mv xx00 final.nim
j='{.deadCodeElim: on.}

{.pragma: libgdk, cdecl, dynlib: LIB_GDK.}

import gdk3

from windows import HWND, HGDIOBJ

from glib import Gpointer, Gboolean

from gobject import GType
'
perl -0777 -0777 -p -i -e "s~$i~$j~" xx01
sed -i "\~$i~d" xx01
sed  -i "s/\(proc win32\)\([A-Z]\)\(\.*\)/proc \l\2\3/g" xx01
ruby ../glib_fix_proc.rb xx01 ''
sed -i 's/\* = win32\([A-Z]\)/* = \L\1/g' xx01
cat -s xx01 > gdk3_win32.nim

# cut x11 module
### "gdk/x11/gdkx11applaunchcontext.h"
i='### ["]gdk[/]x11.*'
csplit final.nim "/$i/"
mv xx00 final.nim
j='{.deadCodeElim: on.}

{.pragma: libgdk, cdecl, dynlib: LIB_GDK.}

import gdk3 except appLaunchContextGetType, cursorGetType, displayGetType, displayManagerGetType, dragContextGetType, glContextGetType, keymapGetType,
  screenGetType, visualGetType, windowGetType

from glib import Gboolean

from gobject import GType

from x import TCursor

from xlib import TDisplay, TScreen, TVisual
'
perl -0777 -p -i -e "s~$i~$j~" xx01
sed -i "\~$i~d" xx01
sed -i 's/): Xid /): x.TXID /g' xx01
sed  -i "s/\(proc x11\)\([A-Z]\)\(\.*\)/proc \l\2\3/g" xx01
ruby ../glib_fix_proc.rb xx01 ''
sed -i 's/\* = x11\([A-Z]\)/* = \L\1/g' xx01
cat -s xx01 > gdk3_x11.nim

sed -i '/### "gdk/d' final.nim

cat ../gdk3_extensions.nim >> final.nim

cat -s final.nim > gdk3.nim

exit

