#!/bin/bash
# S. Salewski, 23-JUL-2017
# generate gdk-pixbuf bindings for Nim
#
gdkpb_dir="/home/stefan/Downloads/gdk-pixbuf-2.36.7"
final="final.h" # the input file for c2nim
list="list.txt"
wdir="tmp_gdkpb"

targets=''
all_t=". ${targets}"

rm -rf $wdir # start from scratch
mkdir $wdir
cd $wdir
cp -r $gdkpb_dir/gdk-pixbuf .
cd gdk-pixbuf

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

cat gdk-pixbuf.h > all.h

cd ..

# cpp run with all headers to determine order
echo "cat \\" > $list

cpp -I. `pkg-config --cflags gtk+-3.0` gdk-pixbuf/all.h $final

# extract file names and push names to list
grep ssalewski $final | sed 's/_ssalewski;/ \\/' >> $list

i=`sort $list | uniq -d | wc -l`
if [ $i != 0 ]; then echo 'list contains duplicates!'; exit; fi;

# now we work again with original headers
rm -rf gdk-pixbuf
cp -r $gdkpb_dir/gdk-pixbuf .

# insert for each header file its name as first line
for j in $all_t ; do
  for i in gdk-pixbuf/${j}/*.h; do
    sed -i "1i/* file: $i */" $i
    sed -i "1i#define headerfilename \"$i\"" $i # marker for splitting
  done
done
cd gdk-pixbuf
  bash ../$list > ../$final
cd ..

sed -i "1i#def G_BEGIN_DECLS" $final
sed -i "1i#def G_END_DECLS" $final
sed -i "1i#def G_DEPRECATED" $final
sed -i "1i#def G_GNUC_CONST" $final
sed -i "1i#def GDK_PIXBUF_AVAILABLE_IN_ALL" $final
sed -i "1i#def GDK_PIXBUF_AVAILABLE_IN_2_26" $final
sed -i "1i#def GDK_PIXBUF_AVAILABLE_IN_2_32" $final
sed -i "1i#def GDK_PIXBUF_AVAILABLE_IN_2_4" $final
sed -i "1i#def GDK_PIXBUF_AVAILABLE_IN_2_6" $final
sed -i "1i#def GDK_PIXBUF_AVAILABLE_IN_2_8" $final
sed -i "1i#def GDK_PIXBUF_AVAILABLE_IN_2_12" $final
sed -i "1i#def GDK_PIXBUF_AVAILABLE_IN_2_14" $final
sed -i "1i#def GDK_PIXBUF_AVAILABLE_IN_2_2" $final
sed -i "1i#def GDK_PIXBUF_AVAILABLE_IN_2_28" $final
sed -i "1i#def GDK_PIXBUF_AVAILABLE_IN_2_30" $final
sed -i "1i#def GDK_PIXBUF_AVAILABLE_IN_2_36" $final
sed -i "1i#def GDK_PIXBUF_DEPRECATED_IN_2_32" $final
sed -i "1i#def G_DEPRECATED_FOR(i)" $final
sed -i "1i#def GDK_PIXBUF_DEPRECATED_IN_2_0_FOR(i)" $final
sed -i "1i#def G_GNUC_NULL_TERMINATED" $final
sed -i "s/\o14//g" $final

# add missing {} for struct
sed -i 's/typedef struct _GdkPixbuf GdkPixbuf;/typedef struct _GdkPixbuf{} GdkPixbuf;/g' $final
sed -i 's/typedef struct _GdkPixbufSimpleAnim GdkPixbufSimpleAnim;/typedef struct _GdkPixbufSimpleAnim{} GdkPixbufSimpleAnim;/g' $final

ruby ../fix_.rb $final

i='
#ifdef C2NIM
#  dynlib lib
#endif
'
perl -0777 -p -i -e "s/^/$i/" $final

sed -i 's/#define GDK_PIXBUF_ERROR gdk_pixbuf_error_quark ()/#define GDK_PIXBUF_ERROR() pixbuf_error_quark ()/g' $final

sed -i 's/\(#define GDK_TYPE_\w\+\)\(\s\+(\?\w\+_get_g\?type\s*()\s*)\?\)/\1()\2/g' $final

#ruby ../func_alias_reorder.rb final.h GDK
ruby ~/ngtk3/common/struct_reorder.rb $final

sed -i 's/\bgchar\b/char/g' $final

c2nim --nep1 --skipcomments --skipinclude $final
sed -i 's/ {\.bycopy\.}//g' final.nim

sed -i "s/^\s*$//g" final.nim
echo -e "\n\n\n\n"  >> final.nim

i='const
  headerfilename* = '
perl -0777 -p -i -e "s~\Q$i\E~  ### ~sg" final.nim

# we use our own defined pragma
sed -i "s/\bdynlib: lib\b/libpixbuf/g" final.nim

i=' {.deadCodeElim: on.}
'
j='{.deadCodeElim: on.}

import glib
import gobject

when defined(windows):
  const LIB_PIXBUF = "libgdk_pixbuf-2.0-0.dll"
elif defined(macosx):
  const LIB_PIXBUF = "libgdk_pixbuf-2.0.0.dylib"
else:
  const LIB_PIXBUF = "libgdk_pixbuf-2.0.so"

{.pragma: libpixbuf, cdecl, dynlib: LIB_PIXBUF.}

const
  GDK_PIXBUF_DISABLE_DEPRECATED* = false
  GDK_PIXBUF_ENABLE_BACKEND* = true
  GTK_DOC_IGNORE = false

type
  GModule = object # dummy object -- GModule is still missing...
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='when defined(gdk_Pixbuf_Disable_Single_Includes) and
    not defined(gdk_Pixbuf_H_Inside) and not defined(gdk_Pixbuf_Compilation):
'
perl -0777 -p -i -e "s~\Q$i\E~~sg" final.nim

i='when defined(GDK_PIXBUF_ENABLE_BACKEND):
  template gdk_Pixbuf_Animation_Class*(klass: untyped): untyped =
    (g_Type_Check_Class_Cast((klass), gdk_Type_Pixbuf_Animation,
                             gdkPixbufAnimationClass))

  template gdk_Is_Pixbuf_Animation_Class*(klass: untyped): untyped =
    (g_Type_Check_Class_Type((klass), gdk_Type_Pixbuf_Animation))

  template gdk_Pixbuf_Animation_Get_Class*(obj: untyped): untyped =
    (g_Type_Instance_Get_Class((obj), gdk_Type_Pixbuf_Animation,
                               gdkPixbufAnimationClass))

  type
    GdkPixbufAnimation* = object
      parentInstance*: GObject

  type
    GdkPixbufAnimationClass* = object
      parentClass*: GObjectClass
      isStaticImage*: proc (anim: ptr GdkPixbufAnimation): Gboolean
      getStaticImage*: proc (anim: ptr GdkPixbufAnimation): ptr GdkPixbuf
      getSize*: proc (anim: ptr GdkPixbufAnimation; width: ptr cint; height: ptr cint)
      getIter*: proc (anim: ptr GdkPixbufAnimation; startTime: ptr GTimeVal): ptr GdkPixbufAnimationIter

  template gdk_Pixbuf_Animation_Iter_Class*(klass: untyped): untyped =
    (g_Type_Check_Class_Cast((klass), gdk_Type_Pixbuf_Animation_Iter,
                             gdkPixbufAnimationIterClass))

  template gdk_Is_Pixbuf_Animation_Iter_Class*(klass: untyped): untyped =
    (g_Type_Check_Class_Type((klass), gdk_Type_Pixbuf_Animation_Iter))

  template gdk_Pixbuf_Animation_Iter_Get_Class*(obj: untyped): untyped =
    (g_Type_Instance_Get_Class((obj), gdk_Type_Pixbuf_Animation_Iter,
                               gdkPixbufAnimationIterClass))

  type
    GdkPixbufAnimationIter* = object
      parentInstance*: GObject

  type
    GdkPixbufAnimationIterClass* = object
      parentClass*: GObjectClass
      getDelayTime*: proc (iter: ptr GdkPixbufAnimationIter): cint
      getPixbuf*: proc (iter: ptr GdkPixbufAnimationIter): ptr GdkPixbuf
      onCurrentlyLoadingFrame*: proc (iter: ptr GdkPixbufAnimationIter): Gboolean
      advance*: proc (iter: ptr GdkPixbufAnimationIter; currentTime: ptr GTimeVal): Gboolean

  proc gdkPixbufNonAnimGetType*(): GType {.importc: "gdk_pixbuf_non_anim_get_type",
                                        libpixbuf.}
  proc gdkPixbufNonAnimNew*(pixbuf: ptr GdkPixbuf): ptr GdkPixbufAnimation {.
      importc: "gdk_pixbuf_non_anim_new", libpixbuf.}
  ### "gdk-pixbuf/./gdk-pixbuf-simple-anim.h"
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim

i='when defined(GDK_PIXBUF_ENABLE_BACKEND):
  template gdk_Pixbuf_Animation_Class*(klass: untyped): untyped =
    (g_Type_Check_Class_Cast((klass), gdk_Type_Pixbuf_Animation,
                             gdkPixbufAnimationClass))

  template gdk_Is_Pixbuf_Animation_Class*(klass: untyped): untyped =
    (g_Type_Check_Class_Type((klass), gdk_Type_Pixbuf_Animation))

  template gdk_Pixbuf_Animation_Get_Class*(obj: untyped): untyped =
    (g_Type_Instance_Get_Class((obj), gdk_Type_Pixbuf_Animation,
                               gdkPixbufAnimationClass))

  type
    GdkPixbufAnimation* = object
      parentInstance*: GObject

  type
    GdkPixbufAnimationIter* = object
      parentInstance*: GObject

  type
    GdkPixbufAnimationClass* = object
      parentClass*: GObjectClass
      isStaticImage*: proc (anim: ptr GdkPixbufAnimation): Gboolean
      getStaticImage*: proc (anim: ptr GdkPixbufAnimation): ptr GdkPixbuf
      getSize*: proc (anim: ptr GdkPixbufAnimation; width: ptr cint; height: ptr cint)
      getIter*: proc (anim: ptr GdkPixbufAnimation; startTime: ptr GTimeVal): ptr GdkPixbufAnimationIter

  type
    GdkPixbufAnimationIterClass* = object
      parentClass*: GObjectClass
      getDelayTime*: proc (iter: ptr GdkPixbufAnimationIter): cint
      getPixbuf*: proc (iter: ptr GdkPixbufAnimationIter): ptr GdkPixbuf
      onCurrentlyLoadingFrame*: proc (iter: ptr GdkPixbufAnimationIter): Gboolean
      advance*: proc (iter: ptr GdkPixbufAnimationIter; currentTime: ptr GTimeVal): Gboolean

  template gdk_Pixbuf_Animation_Iter_Class*(klass: untyped): untyped =
    (g_Type_Check_Class_Cast((klass), gdk_Type_Pixbuf_Animation_Iter,
                             gdkPixbufAnimationIterClass))

  template gdk_Is_Pixbuf_Animation_Iter_Class*(klass: untyped): untyped =
    (g_Type_Check_Class_Type((klass), gdk_Type_Pixbuf_Animation_Iter))

  template gdk_Pixbuf_Animation_Iter_Get_Class*(obj: untyped): untyped =
    (g_Type_Instance_Get_Class((obj), gdk_Type_Pixbuf_Animation_Iter,
                               gdkPixbufAnimationIterClass))

  proc gdkPixbufNonAnimGetType*(): GType {.importc: "gdk_pixbuf_non_anim_get_type",
                                        libpixbuf.}
  proc gdkPixbufNonAnimNew*(pixbuf: ptr GdkPixbuf): ptr GdkPixbufAnimation {.
      importc: "gdk_pixbuf_non_anim_new", libpixbuf.}
  ### "gdk-pixbuf/./gdk-pixbuf-simple-anim.h"
'
j='  ### "gdk-pixbuf/./gdk-pixbuf-animation.h"
'
perl -0777 -p -i -e "s~\Q$j\E~$j$i~s" final.nim

i='proc gdkPixbufFormatGetType*(): GType {.importc: "gdk_pixbuf_format_get_type",
                                     libpixbuf.}
proc gdkPixbufGetFormats*(): ptr GSList {.importc: "gdk_pixbuf_get_formats",
                                      libpixbuf.}
proc gdkPixbufFormatGetName*(format: ptr GdkPixbufFormat): cstring {.
    importc: "gdk_pixbuf_format_get_name", libpixbuf.}
proc gdkPixbufFormatGetDescription*(format: ptr GdkPixbufFormat): cstring {.
    importc: "gdk_pixbuf_format_get_description", libpixbuf.}
proc gdkPixbufFormatGetMimeTypes*(format: ptr GdkPixbufFormat): cstringArray {.
    importc: "gdk_pixbuf_format_get_mime_types", libpixbuf.}
proc gdkPixbufFormatGetExtensions*(format: ptr GdkPixbufFormat): cstringArray {.
    importc: "gdk_pixbuf_format_get_extensions", libpixbuf.}
proc gdkPixbufFormatIsSaveOptionSupported*(format: ptr GdkPixbufFormat;
    optionKey: cstring): Gboolean {.importc: "gdk_pixbuf_format_is_save_option_supported",
                                 libpixbuf.}
proc gdkPixbufFormatIsWritable*(format: ptr GdkPixbufFormat): Gboolean {.
    importc: "gdk_pixbuf_format_is_writable", libpixbuf.}
proc gdkPixbufFormatIsScalable*(format: ptr GdkPixbufFormat): Gboolean {.
    importc: "gdk_pixbuf_format_is_scalable", libpixbuf.}
proc gdkPixbufFormatIsDisabled*(format: ptr GdkPixbufFormat): Gboolean {.
    importc: "gdk_pixbuf_format_is_disabled", libpixbuf.}
proc gdkPixbufFormatSetDisabled*(format: ptr GdkPixbufFormat; disabled: Gboolean) {.
    importc: "gdk_pixbuf_format_set_disabled", libpixbuf.}
proc gdkPixbufFormatGetLicense*(format: ptr GdkPixbufFormat): cstring {.
    importc: "gdk_pixbuf_format_get_license", libpixbuf.}
proc gdkPixbufGetFileInfo*(filename: cstring; width: ptr Gint; height: ptr Gint): ptr GdkPixbufFormat {.
    importc: "gdk_pixbuf_get_file_info", libpixbuf.}
proc gdkPixbufGetFileInfoAsync*(filename: cstring; cancellable: ptr GCancellable;
                               callback: GAsyncReadyCallback; userData: Gpointer) {.
    importc: "gdk_pixbuf_get_file_info_async", libpixbuf.}
proc gdkPixbufGetFileInfoFinish*(asyncResult: ptr GAsyncResult; width: ptr Gint;
                                height: ptr Gint; error: ptr ptr GError): ptr GdkPixbufFormat {.
    importc: "gdk_pixbuf_get_file_info_finish", libpixbuf.}
proc gdkPixbufFormatCopy*(format: ptr GdkPixbufFormat): ptr GdkPixbufFormat {.
    importc: "gdk_pixbuf_format_copy", libpixbuf.}
proc gdkPixbufFormatFree*(format: ptr GdkPixbufFormat) {.
    importc: "gdk_pixbuf_format_free", libpixbuf.}
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim
j='proc gdkPixbufLoaderGetType*(): GType {.importc: "gdk_pixbuf_loader_get_type",
                                     libpixbuf.}
'
perl -0777 -p -i -e "s~\Q$j\E~$i$j~s" final.nim

i='  type
    GdkPixbufModuleFillVtableFunc* = proc (module: ptr GdkPixbufModule)
  type
    GdkPixbufModuleFillInfoFunc* = proc (info: ptr GdkPixbufFormat)
  type
    GdkPixbufFormatFlags* {.size: sizeof(cint).} = enum
      GDK_PIXBUF_FORMAT_WRITABLE = 1 shl 0, GDK_PIXBUF_FORMAT_SCALABLE = 1 shl 1,
      GDK_PIXBUF_FORMAT_THREADSAFE = 1 shl 2
  type
    GdkPixbufFormat* = object
'
j='  #type
    GdkPixbufModuleFillVtableFunc* = proc (module: ptr GdkPixbufModule)
  #type
    GdkPixbufModuleFillInfoFunc* = proc (info: ptr GdkPixbufFormat)
  #type
    GdkPixbufFormatFlags* {.size: sizeof(cint).} = enum
      GDK_PIXBUF_FORMAT_WRITABLE = 1 shl 0, GDK_PIXBUF_FORMAT_SCALABLE = 1 shl 1,
      GDK_PIXBUF_FORMAT_THREADSAFE = 1 shl 2
  #type
    GdkPixbufFormat* = object
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

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

sed -i 's/\bgdkPixbuf\([A-Z]\w\+GetType()\)/\l\1/g' final.nim

ruby ../glib_fix_proc.rb final.nim gdkPixbuf
sed -i -f ../glib_sedlist final.nim
sed -i -f ../gobject_sedlist final.nim
sed -i -f ../gio_sedlist final.nim

ruby ../glib_fix_T.rb final.nim gdk_pixbuf GdkPixbuf
i='s/\bptr ptr GdkPixbuf\b/gdk_pixbufvaaaaar/g
s/\bptr GdkPixbuf\b/gdk_pixbufptttttr/g
s/\bGdkPixbuf\b/gdk_pixbuf.Obj/g
'
j='s/\\bptr ptr GdkPixbuf\\b/gdk_pixbufvaaaaarGdkPixbuf/g
s/\\bptr GdkPixbuf\\b/gdk_pixbufptttttrGdkPixbuf/g
s/\\bGdkPixbuf\\b/gdk_pixbuf.GdkPixbufObj/g
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" gdk_pixbuf_sedlist

sed -i 's/GDK_PIXBUF_ROTATE_/GDK_PIXBUF_ROTATION_/g' final.nim
ruby ../glib_fix_enum_prefix.rb final.nim

sed -i 's/^proc ref\*(/proc `ref`\*(/g' final.nim
sed -i 's/^  proc ref\*(/  proc `ref`\*(/g' final.nim

sed -i 's/\(dummy[0-9]\?\)\*/\1/g' final.nim
sed -i 's/\(reserved[0-9]\?\)\*/\1/g' final.nim

sed -i 's/[(][(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/(\1/g' final.nim
sed -i 's/, [(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/, \1/g' final.nim

ruby ../fix_object_of.rb final.nim

perl -0777 -p -i -e "s~([=:] proc \(.*?\)(?:: (?:ptr )?\w+)?)~\1 {.cdecl.}~sg" final.nim
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

perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gsize)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gdouble)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gdouble)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( cint)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( cint)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gboolean)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( cstring)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Guchar)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gpointer)/\1\2\3\4var\6/sg' final.nim

sed -i 's/when not defined(GDK_PIXBUF_DISABLE_DEPRECATED)/when not GDK_PIXBUF_DISABLE_DEPRECATED/g' final.nim
sed -i 's/when defined(GDK_PIXBUF_ENABLE_BACKEND)/when GDK_PIXBUF_ENABLE_BACKEND/g' final.nim
sed -i 's/when not defined(__GTK_DOC_IGNORE__)/when not GTK_DOC_IGNORE/g' final.nim

i='import glib
import gobject
'
j='from glib import Gpointer, Gboolean, GQuark, Gsize
from gobject import GObject, GType, GObjectObj, GObjectClassObj
from gio import GInputStream, GOutputStream, GCancellable, GAsyncResult, GAsyncReadyCallback
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( gsize)/\1\2\3\4var\6/sg' final.nim

sed -i '/### "gdk-pixbuf\/\.\/gdk-pixbuf/d' final.nim
sed -i 's/when defined(G_OS_WIN32):/when defined(windows):/g' final.nim

ruby ../mangler.rb final.nim GDK_PIXBUF_
sed -i 's/\bGdkPixbufObj\b/GdkXXXPixbufObj/g' final.nim
sed -i 's/\bGdkPixbufPtr\b/GdkXXXPixbufPtr/g' final.nim
sed -i 's/\bGdkPixbuf\b/GdkXXXPixbuf/g' final.nim
ruby ../mangler.rb final.nim GdkPixbuf
sed -i 's/  GdkXXXPixbufObj\* = object/  GdkPixbufObj* = object of GObjectObj/g' final.nim
sed -i 's/\bGdkXXXPixbufObj\b/GdkPixbufObj/g' final.nim
sed -i 's/\bGdkXXXPixbufPtr\b/GdkPixbufPtr/g' final.nim
sed -i 's/\bGdkXXXPixbuf\b/GdkPixbuf/g' final.nim

sed -i 's/\* = gdkPixbuf\([A-Z]\)/* = \L\1/g' final.nim

ruby ../fix_template.rb final.nim gdk

for i in uint8 uint16 uint32 uint64 int8 int16 int32 int64 ; do
  sed -i "s/\bG${i}\b/${i}/g" final.nim
done
sed -i "s/\bGint\b/cint/g" final.nim
sed -i "s/\bGuint\b/cuint/g" final.nim
sed -i "s/\bGfloat\b/cfloat/g" final.nim
sed -i "s/\bGdouble\b/cdouble/g" final.nim
sed -i "s/\bGshort\b/cshort/g" final.nim
sed -i "s/\bGushort\b/cushort/g" final.nim
sed -i "s/\bGlong\b/clong/g" final.nim
sed -i "s/\bGulong\b/culong/g" final.nim
sed -i "s/\bGuchar\b/cuchar/g" final.nim

sed -i "s/^\s*#type\s*$//g" final.nim
sed -i "s/\s*$//g" final.nim

# generate procs without get_ and set_ prefix
perl -0777 -p -i -e "s/(\n\s*)(proc set)([A-Z]\w+)(\*\([^}]*\) \{[^}]*})/\$&\1proc \`\l\3=\`\4/sg" final.nim
perl -0777 -p -i -e "s/(\n\s*)(proc get)([A-Z]\w+)(\*\([^}]*\): \w[^}]*})/\$&\1proc \l\3\4/sg" final.nim

sed -i 's/= (1 shl \([0-9]\)),/= 1 shl \1,/g' final.nim
sed -i 's/= (1 shl \([0-9]\))$/= 1 shl \1/g' final.nim

i='when not GTK_DOC_IGNORE:
  when defined(windows):
    const
      gdkPixbufNewFromFile* = newFromFileUtf8
      gdkPixbufNewFromFileAtSize* = newFromFileAtSizeUtf8
      gdkPixbufNewFromFileAtScale* = newFromFileAtScaleUtf8
proc newFromFile*(filename: cstring; error: var glib.GError): GdkPixbuf {.
    importc: "gdk_pixbuf_new_from_file", libpixbuf.}
proc newFromFileAtSize*(filename: cstring; width: cint; height: cint;
                                error: var glib.GError): GdkPixbuf {.
    importc: "gdk_pixbuf_new_from_file_at_size", libpixbuf.}
proc newFromFileAtScale*(filename: cstring; width: cint; height: cint;
                                 preserveAspectRatio: Gboolean;
                                 error: var glib.GError): GdkPixbuf {.
    importc: "gdk_pixbuf_new_from_file_at_scale", libpixbuf.}
'
j='when defined(windows):
  proc newFromFileUtf8*(filename: cstring; error: var glib.GError): GdkPixbuf {.
      importc: "gdk_pixbuf_new_from_file_utf8", libpixbuf.}
  proc newFromFileAtSizeUtf8*(filename: cstring; width: cint; height: cint;
                                  error: var glib.GError): GdkPixbuf {.
      importc: "gdk_pixbuf_new_from_file_at_size_utf8", libpixbuf.}
  proc newFromFileAtScaleUtf8*(filename: cstring; width: cint; height: cint;
                                   preserveAspectRatio: Gboolean;
                                   error: var glib.GError): GdkPixbuf {.
      importc: "gdk_pixbuf_new_from_file_at_scale_utf8", libpixbuf.}
  proc newFromFile*(filename: cstring; error: var glib.GError): GdkPixbuf {.
      importc: "gdk_pixbuf_new_from_file_utf8", libpixbuf.}
  proc newFromFileAtSize*(filename: cstring; width: cint; height: cint;
                                  error: var glib.GError): GdkPixbuf {.
      importc: "gdk_pixbuf_new_from_file_at_size_utf8", libpixbuf.}
  proc newFromFileAtScale*(filename: cstring; width: cint; height: cint;
                                   preserveAspectRatio: Gboolean;
                                   error: var glib.GError): GdkPixbuf {.
      importc: "gdk_pixbuf_new_from_file_at_scale_utf8", libpixbuf.}
else:
  proc newFromFile*(filename: cstring; error: var glib.GError): GdkPixbuf {.
      importc: "gdk_pixbuf_new_from_file", libpixbuf.}
  proc newFromFileAtSize*(filename: cstring; width: cint; height: cint;
                                  error: var glib.GError): GdkPixbuf {.
      importc: "gdk_pixbuf_new_from_file_at_size", libpixbuf.}
  proc newFromFileAtScale*(filename: cstring; width: cint; height: cint;
                                   preserveAspectRatio: Gboolean;
                                   error: var glib.GError): GdkPixbuf {.
      importc: "gdk_pixbuf_new_from_file_at_scale", libpixbuf.}
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

i='when not GTK_DOC_IGNORE:
  when defined(windows):
    const
      gdkPixbufSave* = saveUtf8
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim

i='when defined(windows):
  proc animationNewFromFileUtf8*(filename: cstring; error: var glib.GError): Animation {.
      importc: "gdk_pixbuf_animation_new_from_file_utf8", libpixbuf.}
'
j='when defined(windows):
  proc newAnimationUtf8*(filename: cstring; error: var glib.GError): Animation {.
      importc: "gdk_pixbuf_animation_new_from_file_utf8", libpixbuf.}
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

sed -i 's/\(proc \w\+New\)[A-Z]\w\+/\1/g' final.nim
sed -i 's/proc \(\w\+\)New\*/proc new\u\1*/g' final.nim

i='proc getType*(): GType {.importc: "gdk_pixbuf_get_type", libpixbuf.}
proc type*(): GType {.importc: "gdk_pixbuf_get_type", libpixbuf.}
'
j='proc pixbufGetType*(): GType {.importc: "gdk_pixbuf_get_type", libpixbuf.}
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

sed -i 's/proc newFrom/proc newPixbufFrom/g' final.nim
sed -i 's/proc new\*/proc newPixbuf*/g' final.nim

cat -s final.nim > gdk_pixbuf.nim

rm -r gdk-pixbuf
rm final.nim final.h list.txt

exit

