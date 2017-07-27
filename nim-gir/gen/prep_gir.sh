#!/bin/bash
# S. Salewski, 27-JUL-2017
# generate gobject-introspection bindings for Nim
#
gir_dir="/home/stefan/Downloads/gobject-introspection-1.53.4"
final="final.h" # the input file for c2nim
list="list.txt"
wdir="tmp_gir"

targets=''
all_t=". ${targets}"

rm -rf $wdir # start from scratch
mkdir $wdir
cd $wdir
cp -r $gir_dir/girepository .
cd girepository

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

cat girepository.h > all.h

# cpp run with all headers to determine order
echo "cat \\" > $list

cpp -I. `pkg-config --cflags gtk+-3.0` all.h $final

# extract file names and push names to list
grep ssalewski $final | sed 's/_ssalewski;/ \\/' >> $list

i=`sort $list | uniq -d | wc -l`
if [ $i != 0 ]; then echo 'list contains duplicates!'; exit; fi;

mv $list ..
cd ..

# now we work again with original headers
rm -rf girepository
cp -r $gir_dir/girepository .

# insert for each header file its name as first line
for j in $all_t ; do
  for i in girepository/${j}/*.h; do
    sed -i "1i/* file: $i */" $i
    sed -i "1i#define headerfilename \"$i\"" $i # marker for splitting
  done
done
cd girepository
  bash ../$list > ../$final
cd ..

perl -0777 -p -i -e "s/#if !?defined.*?\n#error.*?\n#endif//g" $final

sed -i '/#define __GIREPOSITORY_H_INSIDE__/d' $final

i='#ifndef __GI_SCANNER__
#ifndef __GTK_DOC_IGNORE__
/* backwards compatibility */
typedef GIArgument GArgument;
typedef struct _GITypelib GTypelib;
#endif
#endif
'
j='typedef GIArgument GArgument;
typedef struct _GITypelib GTypelib;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~sg" $final

i='#ifndef __GTK_DOC_IGNORE__
typedef struct _GIBaseInfoStub GIBaseInfo;
#endif
'
j='
typedef struct _GIBaseInfoStub GIBaseInfo;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~sg" $final

i='#ifndef __GTK_DOC_IGNORE__
/* These were removed and no longer appear in the typelib;
 * instead, the machine-specific versions like INT32 are
 * always used.
 */
#define GI_TYPE_TAG_SHORT GI_TYPE_TAG_SHORT_WAS_REMOVED
#define GI_TYPE_TAG_INT   GI_TYPE_TAG_INT_WAS_REMOVED
#define GI_TYPE_TAG_LONG  GI_TYPE_TAG_LONG_WAS_REMOVED
#endif
'
j='#define GI_TYPE_TAG_SHORT GI_TYPE_TAG_SHORT_WAS_REMOVED
#define GI_TYPE_TAG_INT   GI_TYPE_TAG_INT_WAS_REMOVED
#define GI_TYPE_TAG_LONG  GI_TYPE_TAG_LONG_WAS_REMOVED
'
perl -0777 -p -i -e "s~\Q$i\E~$j~sg" $final

sed -i "1i#def G_BEGIN_DECLS" $final
sed -i "1i#def G_END_DECLS" $final
sed -i "1i#def GI_AVAILABLE_IN_ALL" $final
sed -i "1i#def G_GNUC_CONST" $final
sed -i "1i#def GI_AVAILABLE_IN_1_32" $final
sed -i "1i#def GI_AVAILABLE_IN_1_34" $final
sed -i "1i#def GI_AVAILABLE_IN_1_36" $final
sed -i "1i#def GI_AVAILABLE_IN_1_42" $final
sed -i "1i#def GI_AVAILABLE_IN_1_44" $final

# insert () after name, so it is a template, not a const
sed -i 's/#define G_TYPE_IREPOSITORY              (g_irepository_get_type ())/#define G_TYPE_IREPOSITORY()              (g_irepository_get_type ())/' $final
sed -i 's/#define GI_TYPE_BASE_INFO	(g_base_info_gtype_get_type ())/#define GI_TYPE_BASE_INFO()	(g_base_info_gtype_get_type ())/' $final
sed -i 's/#define G_INVOKE_ERROR (g_invoke_error_quark ())/#define G_INVOKE_ERROR() (g_invoke_error_quark ())/' $final
sed -i 's/#define G_TYPE_IREPOSITORY              (g_irepository_get_type ())/#define G_TYPE_IREPOSITORY()              (g_irepository_get_type ())/' $final
sed -i 's/#define G_IREPOSITORY_ERROR (g_irepository_error_quark ())/#define G_IREPOSITORY_ERROR() (g_irepository_error_quark ())/' $final

# add missing {} for struct
sed -i 's/typedef struct _GITypelib GTypelib;/typedef struct _GITypelib{} GITypelib;/g' $final

ruby ../fix_.rb $final

i='
#ifdef C2NIM
#  dynlib lib
#endif
'
perl -0777 -p -i -e "s/^/$i/" $final

#sed -i 's/\(#define RSVG_TYPE_\w\+\)\(\s\+(\?\w\+_get_g\?type\s*()\s*)\?\)/\1()\2/g' $final

#ruby ../func_alias_reorder.rb final.h RSVG
#ruby ~/ngtk3/common/struct_reorder.rb $final

sed -i 's/\bgchar\b/char/g' $final

c2nim --nep1 --skipcomments --skipinclude $final
sed -i 's/ {\.bycopy\.}//g' final.nim

sed -i "s/^\s*$//g" final.nim
echo -e "\n\n\n\n"  >> final.nim

i='const
  headerfilename* = '
perl -0777 -p -i -e "s~\Q$i\E~### ~sg" final.nim

# we use our own defined pragma
sed -i "s/\bdynlib: lib\b/libgir/g" final.nim

i=' {.deadCodeElim: on.}
'
j='{.deadCodeElim: on.}

import glib
import gobject

when defined(windows):
  const LIB_GIR = "libgirepository-1.0.dll"
elif defined(macosx):
  const LIB_GIR = "libgirepository-1.0.dylib"
else:
  const LIB_GIR = "libgirepository-1.0.so(|.1)"

{.pragma: libgir, cdecl, dynlib: LIB_GIR.}

'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

ruby ../glib_fix_enum_prefix.rb final.nim

sed -i 's/\(dummy[0-9]\?\)\*/\1/g' final.nim
sed -i 's/\(data[0-9]\?\)\*/\1/g' final.nim
sed -i 's/\(padding[0-9]\?\)\*/\1/g' final.nim
sed -i 's/\(reserved[0-9]\?\)\*/\1/g' final.nim
sed -i 's/\(priv[0-9]\?\)\*/\1/g' final.nim
sed -i 's/\(Padding[0-9]\?\)\*/\1/g' final.nim

# fix c2nim --nep1 mess. We need this before glib_fix_T.rb call!
sed -i 's/[(][(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/(\1/g' final.nim
sed -i 's/, [(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/, \1/g' final.nim
perl -0777 -p -i -e 's/(  \(.*,)\n/\1/g' final.nim

sed -i 's/\(, \) \+/\1/g' final.nim

# this give too many name conflicts!
#ruby ../glib_fix_proc.rb final.nim gArgInfo
#ruby ../glib_fix_proc.rb final.nim gBaseInfo
#ruby ../glib_fix_proc.rb final.nim gCallableInfo
#ruby ../glib_fix_proc.rb final.nim gConstantInfo
#ruby ../glib_fix_proc.rb final.nim gEnumInfo
#ruby ../glib_fix_proc.rb final.nim gFieldInfo
#ruby ../glib_fix_proc.rb final.nim gFunctionInfo
#ruby ../glib_fix_proc.rb final.nim gInterfaceInfo
#ruby ../glib_fix_proc.rb final.nim gObjectInfo
#ruby ../glib_fix_proc.rb final.nim gPropertyInfo
#ruby ../glib_fix_proc.rb final.nim gRegisteredTypeInfo
#ruby ../glib_fix_proc.rb final.nim gSignalInfo
#ruby ../glib_fix_proc.rb final.nim gStructInfo
#ruby ../glib_fix_proc.rb final.nim gTypeTag
#ruby ../glib_fix_proc.rb final.nim gInfoType
#ruby ../glib_fix_proc.rb final.nim gTypeInfo
#ruby ../glib_fix_proc.rb final.nim gUnionInfo
#ruby ../glib_fix_proc.rb final.nim gVfuncInfo
#ruby ../glib_fix_proc.rb final.nim gIrepository

sed -i -f ../glib_sedlist final.nim
sed -i -f ../gobject_sedlist final.nim

ruby ../glib_fix_T.rb final.nim gir Gir

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

i='import glib
import gobject
'
j='from glib import Gpointer, Gboolean, GQuark, Gsize, GSsize
from gobject import GObject, GType, GObjectObj, GObjectClassObj, GParamFlags, GSignalFlags
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( gsize)/\1\2\3\4var\6/sg' final.nim

sed -i '/### "girepository\/\./d' final.nim

#ruby ../mangler.rb final.nim RSVG_
#ruby ../mangler.rb final.nim Rsvg
ruby ../fix_template.rb final.nim gi
ruby ../fix_template.rb final.nim g
sed -i 's/\(: ptr \)\w\+PrivateObj/: pointer/g' final.nim
sed -i 's/: ptr GIRepositoryPrivate/: pointer/g' final.nim
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

sed -i 's/= (1 shl \([0-9]\)),/= 1 shl \1,/g' final.nim
sed -i 's/= (1 shl \([0-9]\))$/= 1 shl \1/g' final.nim

sed -i 's/\(proc \w\+New\)[A-Z]\w\+/\1/g' final.nim
sed -i 's/proc \(\w\+\)New\*/proc new\u\1*/g' final.nim

i='type
  GIBaseInfoStub* =  ptr GIBaseInfoStubObj
  GIBaseInfoStubPtr* = ptr GIBaseInfoStubObj
  GIBaseInfoStubObj* = object
    dummy1: int32
    dummy2: int32
    dummy3: Gpointer
    dummy4: Gpointer
    dummy5: Gpointer
    dummy6: uint32
    dummy7: uint32
    padding: array[4, Gpointer]



type
  GIAttributeIter* =  ptr GIAttributeIterObj
  GIAttributeIterPtr* = ptr GIAttributeIterObj
  GIAttributeIterObj* = object
    data: Gpointer
    data2: Gpointer
    data3: Gpointer
    data4: Gpointer
'
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim
j='type
  GIBaseInfo* = gIBaseInfoStub
'
perl -0777 -p -i -e "s/\Q$j\E/$i$j/s" final.nim

i='
type
  GIBaseInfo* = gIBaseInfoStub
'
j='

type
  GIBaseInfo* = GIBaseInfoStub
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='const
  GI_TYPE_TAG_N_TYPES* = (gi_Type_Tag_Unichar + 1)
  GI_TYPE_TAG_SHORT* = gi_Type_Tag_Short_Was_Removed
  GI_TYPE_TAG_INT* = gi_Type_Tag_Int_Was_Removed
  GI_TYPE_TAG_LONG* = gi_Type_Tag_Long_Was_Removed
'
j='
const
  GI_TYPE_TAG_N_TYPES* =  GITypeTag.UNICHAR.ord + 1
  # GI_TYPE_TAG_SHORT* = gi_Type_Tag_Short_Was_Removed
  # GI_TYPE_TAG_INT* = gi_Type_Tag_Int_Was_Removed
  # GI_TYPE_TAG_LONG* = gi_Type_Tag_Long_Was_Removed
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='proc newGTypelib*(memory: var uint8; len: Gsize; error: var glib.GError): GITypelib {.
    importc: "g_typelib_new_from_const_memory", libgir.}
'
j='proc newGTypelib*(memory: ptr uint8; len: Gsize; error: var glib.GError): GITypelib {.
    importc: "g_typelib_new_from_const_memory", libgir.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

sed -i "s/(cast\[ptr GIBaseInfo\](info)/(cast[GIBaseInfo](info)/g" final.nim
for i in GIBaseInfo GICallableInfo GIFunctionInfo GICallbackInfo GIRegisteredTypeInfo GIStructInfo GIUnionInfo GIEnumInfo GIObjectInfo GIInterfaceInfo GIConstantInfo GIValueInfo GISignalInfo GISignalInfo GIPropertyInfo GIFieldInfo GIArgInfo GITypeInfo GIVFuncInfo ; do

sed -i "s/: ptr ptr $i/: var $i/g" final.nim
sed -i "s/: ptr $i/: $i/g" final.nim

done

sed -i 's/G_IREPOSITORY_ERROR_//g' final.nim
sed -i 's/G_IREPOSITORY_LOAD_FLAG_//g' final.nim
sed -i 's/G_INVOKE_ERROR_//g' final.nim

sed -i 's/gi_Info_Type_\(\w\+\)/GIInfoType.\u\1/g' final.nim
sed -i 's/gi_Type_Tag_\(\w\+\)/GITypeTag.\u\1/g' final.nim

cat -s final.nim > gir.nim

#rm -r rsvg
#rm final.nim final.h list.txt

exit

