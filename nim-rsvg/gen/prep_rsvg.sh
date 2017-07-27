#!/bin/bash
# S. Salewski, 26-JUL-2017
# generate rsvg bindings for Nim
#
rsvg_dir="/home/stefan/Downloads/librsvg-2.41.0"
final="final.h" # the input file for c2nim
list="list.txt"
wdir="tmp_rsvg"

targets=''
all_t=". ${targets}"

rm -rf $wdir # start from scratch
mkdir $wdir
cd $wdir
cp -r $rsvg_dir/ rsvg
cd rsvg

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

cat rsvg.h > all.h

cd ..

# cpp run with all headers to determine order
echo "cat \\" > $list

cpp -I. `pkg-config --cflags gtk+-3.0` rsvg/all.h $final

# extract file names and push names to list
grep ssalewski $final | sed 's/_ssalewski;/ \\/' >> $list

i=`sort $list | uniq -d | wc -l`
if [ $i != 0 ]; then echo 'list contains duplicates!'; exit; fi;

# now we work again with original headers
rm -rf rsvg
cp -r $rsvg_dir/ rsvg

# insert for each header file its name as first line
for j in $all_t ; do
  for i in rsvg/${j}/*.h; do
    sed -i "1i/* file: $i */" $i
    sed -i "1i#define headerfilename \"$i\"" $i # marker for splitting
  done
done
cd rsvg
  bash ../$list > ../$final
cd ..

sed -i "1i#def G_BEGIN_DECLS" $final
sed -i "1i#def G_END_DECLS" $final
sed -i "1i#def RSVG_DEPRECATED" $final
sed -i "1i#def G_GNUC_CONST" $final
sed -i "1i#def RSVG_DEPRECATED_FOR(i)" $final

sed -i 's/typedef struct RsvgHandlePrivate RsvgHandlePrivate;/typedef struct _RsvgHandlePrivate{} RsvgHandlePrivate;/g' $final

ruby ../fix_.rb $final

i='
#ifdef C2NIM
#  dynlib lib
#endif
'
perl -0777 -p -i -e "s/^/$i/" $final

sed -i 's/\(#define RSVG_TYPE_\w\+\)\(\s\+(\?\w\+_get_g\?type\s*()\s*)\?\)/\1()\2/g' $final

#ruby ../func_alias_reorder.rb final.h RSVG
#ruby ~/ngtk3/common/struct_reorder.rb $final

sed -i 's/\bgchar\b/char/g' $final

i='#if defined(RSVG_DISABLE_DEPRECATION_WARNINGS) || !GLIB_CHECK_VERSION (2, 31, 0)
#define RSVG_DEPRECATED
#define RSVG_DEPRECATED_FOR(f)
#else
#define RSVG_DEPRECATED G_DEPRECATED
#define RSVG_DEPRECATED_FOR(f) G_DEPRECATED_FOR(f)
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~sg" $final

i='#define __RSVG_RSVG_H_INSIDE__
'
perl -0777 -p -i -e "s~\Q$i\E~~sg" $final

i='#if !defined (__RSVG_RSVG_H_INSIDE__) && !defined (RSVG_COMPILATION)
'
perl -0777 -p -i -e "s~\Q$i\E~~sg" $final

i='#define RSVG_ERROR (rsvg_error_quark ())
GQuark rsvg_error_quark (void) G_GNUC_CONST;
'
j='#define RSVG_ERROR() (rsvg_error_quark ())
GQuark rsvg_error_quark (void) G_GNUC_CONST;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~sg" $final

c2nim --nep1 --skipcomments --skipinclude $final
sed -i 's/ {\.bycopy\.}//g' final.nim

sed -i "s/when not defined(__GI_SCANNER__):/when not USE_DEPRECATED: # Deprecated APIs. Do not use!/g" final.nim

sed -i "s/^\s*$//g" final.nim
echo -e "\n\n\n\n"  >> final.nim

i='const
  headerfilename* = '
perl -0777 -p -i -e "s~\Q$i\E~### ~sg" final.nim

# we use our own defined pragma
sed -i "s/\bdynlib: lib\b/librsvg/g" final.nim

i=' {.deadCodeElim: on.}
'
j='{.deadCodeElim: on.}

import glib
import gobject

when defined(windows):
  const LIB_RSVG = "librsvg-2.dll"
elif defined(macosx):
  const LIB_RSVG = "librsvg-2.dylib"
else:
  const LIB_RSVG = "librsvg-2.so(|.0)"

{.pragma: librsvg, cdecl, dynlib: LIB_RSVG.}

const Depri
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

sed -i 's/HANDLE_FLAG_UNLIMITED/HANDLE_FLAGS_UNLIMITED/g' final.nim
sed -i 's/HANDLE_FLAG_KEEP_IMAGE_DATA/HANDLE_FLAGS_KEEP_IMAGE_DATA/g' final.nim
ruby ../glib_fix_enum_prefix.rb final.nim

sed -i 's/^proc ref\*(/proc `ref`\*(/g' final.nim
sed -i 's/^  proc ref\*(/  proc `ref`\*(/g' final.nim

sed -i 's/\(dummy[0-9]\?\)\*/\1/g' final.nim
sed -i 's/\(reserved[0-9]\?\)\*/\1/g' final.nim
sed -i 's/\(priv[0-9]\?\)\*/\1/g' final.nim
sed -i 's/\(Padding[0-9]\?\)\*/\1/g' final.nim

# fix c2nim --nep1 mess. We need this before glib_fix_T.rb call!
sed -i 's/[(][(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/(\1/g' final.nim
sed -i 's/, [(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/, \1/g' final.nim
perl -0777 -p -i -e 's/(  \(.*,)\n/\1/g' final.nim

sed -i 's/\(, \) \+/\1/g' final.nim

sed -i 's/\(g_Type_Check_Instance_Cast\)(\(`\?\w\+`\?, \)\(rsvg_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Instance_Get_Interface\)(\(`\?\w\+`\?, \)\(rsvg_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Check_Class_Cast\)(\(`\?\w\+`\?, \)\(rsvg_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Instance_Get_Class\)(\(`\?\w\+`\?, \)\(rsvg_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Type\)(\(`\?\w\+`\?, \)\(rsvg_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Class_Type\)(\(`\?\w\+`\?, \)\(rsvg_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Value_Type\)(\(`\?\w\+`\?, \)\(rsvg_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Fundamental_Type\)(\(`\?\w\+`\?, \)\(rsvg_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(gTypeIsA\)(\(`\?\w\+`\?, \)\(rsvg_Type_\w\+\))/\1(\2\3)/g' final.nim

sed -i 's/\brsvg\([A-Z]\w\+GetType()\)/\l\1/g' final.nim

ruby ../glib_fix_proc.rb final.nim rsvg
sed -i -f ../glib_sedlist final.nim
sed -i -f ../gobject_sedlist final.nim
sed -i -f ../gio_sedlist final.nim
sed -i -f ../cairo_sedlist final.nim
sed -i -f ../gdk_pixbuf_sedlist final.nim

ruby ../glib_fix_T.rb final.nim rsvg Rsvg

ruby ../fix_object_of.rb final.nim

perl -0777 -p -i -e "s~([=:] proc \(.*?\)(?:: (?:ptr )?\w+)?)~\1 {.cdecl.}~sg" final.nim
sed -i 's/\([,=(<>] \{0,1\}\)[(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/\1\2/g' final.nim
sed -i '/^ \? \?#type $/d' final.nim
sed -i 's/\bgobject\.GObjectObj\b/GObjectObj/g' final.nim
sed -i 's/\bgobject\.GObject\b/GObject/g' final.nim
sed -i 's/\bgobject\.GObjectClassObj\b/GObjectClassObj/g' final.nim
sed -i 's/\bgdk_pixbuf\.GdkPixbuf\b/GdkPixbuf/g' final.nim

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

i='import glib
import gobject
'
j='from glib import Gpointer, Gboolean, GQuark, Gsize, GDestroyNotify
from gobject import GObject, GType, GObjectObj, GObjectClassObj
from gio import GInputStream, GCancellable
from gdk_pixbuf import GdkPixbuf
from cairo import Context
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( gsize)/\1\2\3\4var\6/sg' final.nim

sed -i '/### "rsvg\/\.\/rsvg/d' final.nim

#ruby ../mangler.rb final.nim RSVG_
ruby ../mangler.rb final.nim Rsvg
ruby ../fix_template.rb final.nim rsvg

sed -i 's/\(: ptr \)\w\+PrivateObj/: pointer/g' final.nim
sed -i '/  \w\+PrivateObj = object$/d' final.nim

perl -0777 -p -i -e "s%\ntype\n{2,}%\ntype\n%sg" final.nim
perl -0777 -p -i -e "s%\n(type\n){2,}%\ntype\n%sg" final.nim
perl -0777 -p -i -e "s%\ntype\ntemplate%\ntemplate%sg" final.nim
perl -0777 -p -i -e "s%\ntype\nproc%\nproc%sg" final.nim
sed -i '/#type$/d' final.nim

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

sed -i 's/\(proc \w\+New\)[A-Z]\w\+/\1/g' final.nim
sed -i 's/proc \(\w\+\)New\*/proc new\u\1*/g' final.nim

sed -i "s/const Depri/const USE_DEPRECATED = false/g" final.nim
sed -i "s/(rsvgErrorQuark())/errorQuark()/g" final.nim
sed -i "s/proc newHandle\*(data: var uint8;/proc newHandle*(data: ptr uint8;/g" final.nim
sed -i 's~### "rsvg/./librsvg-enum-types.h"~~g' final.nim

cat -s final.nim > rsvg.nim

#rm -r rsvg
rm final.nim final.h list.txt

exit

