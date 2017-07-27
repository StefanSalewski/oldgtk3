#!/bin/bash
# S. Salewski, 23-JUL-2017
# Generate ATK bindings for Nim
#
atk_dir="/home/stefan/Downloads/atk-2.25.2"
final="final.h" # the input file for c2nim
list="list.txt"
wdir="tmp"

targets=''
all_t=". ${targets}"

rm -rf $wdir # start from scratch
mkdir $wdir
cd $wdir
cp -r $atk_dir/atk .
cd atk

# check already done for atk 2.20...
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

cat atk.h > all.h

cd ..

# cpp run with all headers to determine order
echo "cat \\" > $list

cpp -I. `pkg-config --cflags gtk+-3.0` atk/all.h $final

# extract file names and push names to list
grep ssalewski $final | sed 's/_ssalewski;/ \\/' >> $list

# maybe add remaining missing headers

i=`sort $list | uniq -d | wc -l`
if [ $i != 0 ]; then echo 'list contains duplicates!'; exit; fi;

# now we work again with original headers
rm -rf atk
cp -r $atk_dir/atk .

# insert for each header file its name as first line
for j in $all_t ; do
  for i in atk/${j}/*.h; do
    sed -i "1i/* file: $i */" $i
    sed -i "1i#define headerfilename \"$i\"" $i # marker for splitting
  done
done
cd atk
  bash ../$list > ../$final
cd ..

# delete strange macros (define these as empty ones for c2nim)
sed -i "1i#def G_BEGIN_DECLS" $final
sed -i "1i#def G_END_DECLS" $final
sed -i "1i#def ATK_AVAILABLE_IN_2_2" $final
sed -i "1i#def ATK_AVAILABLE_IN_2_8" $final
sed -i "1i#def ATK_AVAILABLE_IN_2_10" $final
sed -i "1i#def ATK_AVAILABLE_IN_2_12" $final
sed -i "1i#def ATK_AVAILABLE_IN_ALL" $final
sed -i "1i#def ATK_DEPRECATED_FOR(x)" $final
sed -i "1i#def ATK_DEPRECATED_IN_2_10" $final
sed -i "1i#def ATK_DEPRECATED_IN_2_12" $final
sed -i "1i#def ATK_DEPRECATED_IN_2_8_FOR(x)" $final
sed -i "1i#def ATK_DEPRECATED_IN_2_10_FOR(x)" $final
sed -i "1i#def ATK_DEPRECATED_IN_2_12_FOR(x)" $final
sed -i "1i#def ATK_DEPRECATED" $final

# we should not need these macros
sed -i '/#define ATK_DEFINE_TYPE(TN, t_n, T_P)			       ATK_DEFINE_TYPE_EXTENDED (TN, t_n, T_P, 0, {})/d' $final
sed -i '/#define ATK_DEFINE_TYPE_WITH_CODE(TN, t_n, T_P, _C_)	      _ATK_DEFINE_TYPE_EXTENDED_BEGIN (TN, t_n, T_P, 0) {_C_;} _ATK_DEFINE_TYPE_EXTENDED_END()/d' $final
sed -i '/#define ATK_DEFINE_ABSTRACT_TYPE(TN, t_n, T_P)		       ATK_DEFINE_TYPE_EXTENDED (TN, t_n, T_P, G_TYPE_FLAG_ABSTRACT, {})/d' $final
sed -i '/#define ATK_DEFINE_ABSTRACT_TYPE_WITH_CODE(TN, t_n, T_P, _C_) _ATK_DEFINE_TYPE_EXTENDED_BEGIN (TN, t_n, T_P, G_TYPE_FLAG_ABSTRACT) {_C_;} _ATK_DEFINE_TYPE_EXTENDED_END()/d' $final
sed -i '/#define ATK_DEFINE_TYPE_EXTENDED(TN, t_n, T_P, _f_, _C_)      _ATK_DEFINE_TYPE_EXTENDED_BEGIN (TN, t_n, T_P, _f_) {_C_;} _ATK_DEFINE_TYPE_EXTENDED_END()/d' $final

i='#define _ATK_DEFINE_TYPE_EXTENDED_BEGIN(TypeName, type_name, TYPE, flags) \
\
static void     type_name##_init              (TypeName        *self); \
static void     type_name##_class_init        (TypeName##Class *klass); \
static gpointer type_name##_parent_class = NULL; \
static void     type_name##_class_intern_init (gpointer klass) \
{ \
  type_name##_parent_class = g_type_class_peek_parent (klass); \
  type_name##_class_init ((TypeName##Class*) klass); \
} \
\
ATK_AVAILABLE_IN_ALL \
GType \
type_name##_get_type (void) \
{ \
  static volatile gsize g_define_type_id__volatile = 0; \
  if (g_once_init_enter (&g_define_type_id__volatile))  \
    { \
      AtkObjectFactory *factory; \
      GType derived_type; \
      GTypeQuery query; \
      GType derived_atk_type; \
      GType g_define_type_id; \
\
      /* Figure out the size of the class and instance we are deriving from */ \
      derived_type = g_type_parent (TYPE); \
      factory = atk_registry_get_factory (atk_get_default_registry (), \
                                          derived_type); \
      derived_atk_type = atk_object_factory_get_accessible_type (factory); \
      g_type_query (derived_atk_type, &query); \
\
      g_define_type_id = \
        g_type_register_static_simple (derived_atk_type, \
                                       g_intern_static_string (#TypeName), \
                                       query.class_size, \
                                       (GClassInitFunc) type_name##_class_intern_init, \
                                       query.instance_size, \
                                       (GInstanceInitFunc) type_name##_init, \
                                       (GTypeFlags) flags); \
      { /* custom code follows */
#define _ATK_DEFINE_TYPE_EXTENDED_END()	\
        /* following custom code */	\
      }					\
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id); \
    }					\
  return g_define_type_id__volatile;	\
} /* closes type_name##_get_type() */
'
perl -0777 -p -i -e "s%\Q$i\E%%s" $final

i='#ifndef ATK_VAR
#  ifdef G_PLATFORM_WIN32
#    ifdef ATK_STATIC_COMPILATION
#      define ATK_VAR extern
#    else /* !ATK_STATIC_COMPILATION */
#      ifdef ATK_COMPILATION
#        ifdef DLL_EXPORT
#          define ATK_VAR _ATK_EXTERN
#        else /* !DLL_EXPORT */
#          define ATK_VAR extern
#        endif /* !DLL_EXPORT */
#      else /* !ATK_COMPILATION */
#        define ATK_VAR extern __declspec(dllimport)
#      endif /* !ATK_COMPILATION */
#    endif /* !ATK_STATIC_COMPILATION */
#  else /* !G_PLATFORM_WIN32 */
#    define ATK_VAR _ATK_EXTERN
#  endif /* !G_PLATFORM_WIN32 */
#endif /* ATK_VAR */
'
perl -0777 -p -i -e "s%\Q$i\E%%s" $final
sed -i '/ATK_VAR AtkMisc \*atk_misc_instance;/d' $final

i='#if defined(ATK_DISABLE_SINGLE_INCLUDES) && !defined (__ATK_H_INSIDE__) && !defined (ATK_COMPILATION)
#error "Only <atk/atk.h> can be included directly."
#endif
'
perl -0777 -p -i -e "s%\Q$i\E%%sg" $final

# this is generated by find_opaque_structs.rb
sed -i 's/typedef struct _AtkImplementor            AtkImplementor;/typedef struct _AtkImplementor{} AtkImplementor;/' final.h
sed -i 's/typedef struct _AtkAction AtkAction;/typedef struct _AtkAction{} AtkAction;/' final.h
sed -i 's/typedef struct _AtkComponent AtkComponent;/typedef struct _AtkComponent{} AtkComponent;/' final.h
sed -i 's/typedef struct _AtkDocument AtkDocument;/typedef struct _AtkDocument{} AtkDocument;/' final.h
sed -i 's/typedef struct _AtkText AtkText;/typedef struct _AtkText{} AtkText;/' final.h
sed -i 's/typedef struct _AtkEditableText AtkEditableText;/typedef struct _AtkEditableText{} AtkEditableText;/' final.h
sed -i 's/typedef struct _AtkHyperlinkImpl AtkHyperlinkImpl;/typedef struct _AtkHyperlinkImpl{} AtkHyperlinkImpl;/' final.h
sed -i 's/typedef struct _AtkHypertext AtkHypertext;/typedef struct _AtkHypertext{} AtkHypertext;/' final.h
sed -i 's/typedef struct _AtkImage AtkImage;/typedef struct _AtkImage{} AtkImage;/' final.h
sed -i 's/typedef struct _AtkRange AtkRange;/typedef struct _AtkRange{} AtkRange;/' final.h
sed -i 's/typedef struct _AtkSelection AtkSelection;/typedef struct _AtkSelection{} AtkSelection;/' final.h
sed -i 's/typedef struct _AtkStreamableContent AtkStreamableContent;/typedef struct _AtkStreamableContent{} AtkStreamableContent;/' final.h
sed -i 's/typedef struct _AtkTable AtkTable;/typedef struct _AtkTable{} AtkTable;/' final.h
sed -i 's/typedef struct _AtkTableCell AtkTableCell;/typedef struct _AtkTableCell{} AtkTableCell;/' final.h
sed -i 's/typedef struct _AtkValue AtkValue;/typedef struct _AtkValue{} AtkValue;/' final.h
sed -i 's/typedef struct _AtkWindow AtkWindow;/typedef struct _AtkWindow{} AtkWindow;/' final.h

ruby ../fix_.rb $final

# header for Nim module
i='
#ifdef C2NIM
#  dynlib lib
#endif
'
perl -0777 -p -i -e "s/^/$i/" $final

sed -i 's/#define ATK_IS_STREAMABLE_CONTENT(obj)        G_TYPE_CHECK_INSTANCE_TYPE ((obj), ATK_TYPE_STREAMABLE_CONTENT)/#define ATK_IS_STREAMABLE_CONTENT(obj)        (G_TYPE_CHECK_INSTANCE_TYPE ((obj), ATK_TYPE_STREAMABLE_CONTENT))/g' $final

sed -i 's/#define ATK_STREAMABLE_CONTENT(obj)           G_TYPE_CHECK_INSTANCE_CAST ((obj), ATK_TYPE_STREAMABLE_CONTENT, AtkStreamableContent)/#define ATK_STREAMABLE_CONTENT(obj)           (G_TYPE_CHECK_INSTANCE_CAST ((obj), ATK_TYPE_STREAMABLE_CONTENT, AtkStreamableContent))/g' $final

sed -i 's/\(#define ATK_TYPE_\w\+\)\(\s\+(\?\w\+_get_g\?type\s*()\s*)\?\)/\1()\2/g' $final
#ruby ../func_alias_reorder.rb final.h ATK
#ruby ../struct_reorder.rb $final
ruby ~/ngtk3/common/struct_reorder.rb $final

i='#ifndef _TYPEDEF_ATK_ACTION_
#define _TYPEDEF_ATK_ACTION_
typedef struct _AtkAction{} AtkAction;
#endif
'
j='typedef struct _AtkAction{} AtkAction;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

i='#ifndef _TYPEDEF_ATK_UTIL_
#define _TYPEDEF_ATK_UTIL_
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifndef _TYPEDEF_ATK_COMPONENT_
#define _TYPEDEF_ATK_COMPONENT_
typedef struct _AtkComponent{} AtkComponent;
#endif
'
j='typedef struct _AtkComponent{} AtkComponent;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

i='#ifndef _TYPEDEF_ATK_DOCUMENT_
#define _TYPEDEF_ATK_DOCUMENT_
typedef struct _AtkDocument{} AtkDocument;
#endif
'
j='typedef struct _AtkDocument{} AtkDocument;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

i='#ifndef _TYPEDEF_ATK_TEXT_
#define _TYPEDEF_ATK_TEXT_
typedef struct _AtkText{} AtkText;
#endif
'
j='typedef struct _AtkText{} AtkText;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

i='#ifndef _TYPEDEF_ATK_EDITABLE_TEXT_
#define _TYPEDEF_ATK_EDITABLE_TEXT_
typedef struct _AtkEditableText{} AtkEditableText;
#endif
'
j='typedef struct _AtkEditableText{} AtkEditableText;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

i='
#ifndef _TYPEDEF_ATK_HYPERLINK_IMPL_
#define _TYPEDEF_ATK_HYPERLINK_IMPL__

/**
 * AtkHyperlinkImpl:
 *
 * A queryable interface which allows AtkHyperlink instances
 * associated with an AtkObject to be obtained.  AtkHyperlinkImpl
 * corresponds to AT-SPI'\''s Hyperlink interface, and differs from
 * AtkHyperlink in that AtkHyperlink is an object type, rather than an
 * interface, and thus cannot be directly queried. FTW
 */
#endif

'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifndef _TYPEDEF_ATK_HYPERTEXT_
#define _TYPEDEF_ATK_HYPERTEXT_
typedef struct _AtkHypertext{} AtkHypertext;
#endif
'
j='typedef struct _AtkHypertext{} AtkHypertext;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

i='#ifndef _TYPEDEF_ATK_IMAGE_
#define _TYPEDEF_ATK_IMAGE_
typedef struct _AtkImage{} AtkImage;
#endif
'
j='typedef struct _AtkImage{} AtkImage;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

i='#ifndef _TYPEDEF_ATK_SELECTION_
#define _TYPEDEF_ATK_SELECTION_
typedef struct _AtkSelection{} AtkSelection;
#endif
'
j='typedef struct _AtkSelection{} AtkSelection;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

i='#ifndef _TYPEDEF_ATK_TABLE_CELL_
#define _TYPEDEF_ATK_TABLE_CELL_
typedef struct _AtkTableCell{} AtkTableCell;
#endif
'
j='typedef struct _AtkTableCell{} AtkTableCell;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

i='#ifndef _TYPEDEF_ATK_STREAMABLE_CONTENT
#define _TYPEDEF_ATK_STREAMABLE_CONTENT
typedef struct _AtkStreamableContent{} AtkStreamableContent;
#endif
'
j='typedef struct _AtkStreamableContent{} AtkStreamableContent;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

i='#ifndef _TYPEDEF_ATK_TABLE_
#define _TYPEDEF_ATK_TABLE_
typedef struct _AtkTable{} AtkTable;
#endif
'
j='typedef struct _AtkTable{} AtkTable;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

i='#ifndef _TYPEDEF_ATK_MISC_
#define _TYPEDEF_ATK_MISC_
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifndef _TYPEDEF_ATK_VALUE_
#define _TYPEDEF_ATK_VALUE__
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

sed -i 's/\bgchar\b/char/g' $final

c2nim --nep1 --skipcomments --skipinclude $final
sed -i 's/ {\.bycopy\.}//g' final.nim
sed -i "s/^\s*$//g" final.nim
echo -e "\n\n\n\n"  >> final.nim

i='type
  AtkPropertyChangeHandler* = proc (obj: ptr AtkObject; vals: ptr AtkPropertyValues)
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim
j='  AtkStateSet* = object
    parent*: GObject
'
perl -0777 -p -i -e "s~\Q$j\E~$j$i~s" final.nim

i='type
  AtkFunction* = proc (userData: Gpointer): Gboolean
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim
j='type
  AtkPropertyChangeHandler* = proc (obj: ptr AtkObject; vals: ptr AtkPropertyValues)
'
perl -0777 -p -i -e "s~\Q$j\E~$j$i~s" final.nim

i='  AtkImplementor* = object
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim
j='type
  AtkPropertyChangeHandler* = proc (obj: ptr AtkObject; vals: ptr AtkPropertyValues)
'
perl -0777 -p -i -e "s~\Q$j\E~$j$i~s" final.nim

i='type
  AtkKeySnoopFunc* = proc (event: ptr AtkKeyEventStruct; userData: Gpointer): Gint


type
  AtkKeyEventStruct* = object
    `type`*: Gint
    state*: Guint
    keyval*: Guint
    length*: Gint
    string*: cstring
    keycode*: Guint16
    timestamp*: Guint32
'
j='type
  AtkKeySnoopFunc* = proc (event: ptr AtkKeyEventStruct; userData: Gpointer): Gint

  AtkKeyEventStruct* = object
    `type`*: Gint
    state*: Guint
    keyval*: Guint
    length*: Gint
    string*: cstring
    keycode*: Guint16
    timestamp*: Guint32
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim
perl -0777 -p -i -e "s~([=:] proc \(.*?\)(?:: (?:ptr ){0,2}\w+)?)~\1 {.cdecl.}~sg" final.nim

i='type
  AtkKeySnoopFunc* = proc (event: ptr AtkKeyEventStruct; userData: Gpointer): Gint {.cdecl.}

  AtkKeyEventStruct* = object
    `type`*: Gint
    state*: Guint
    keyval*: Guint
    length*: Gint
    string*: cstring
    keycode*: Guint16
    timestamp*: Guint32
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim
j='type
  AtkUtil* = object
    parent*: GObject
'
perl -0777 -p -i -e "s~\Q$j\E~$j$i~s" final.nim

i='type
  AtkFocusHandler* = proc (`object`: ptr AtkObject; focusIn: Gboolean) {.cdecl.}
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim
j='  AtkComponent* = object
'
perl -0777 -p -i -e "s~\Q$j\E~$i$j~s" final.nim

i='type
  AtkTextBoundary* {.size: sizeof(cint).} = enum
    ATK_TEXT_BOUNDARY_CHAR, ATK_TEXT_BOUNDARY_WORD_START,
    ATK_TEXT_BOUNDARY_WORD_END, ATK_TEXT_BOUNDARY_SENTENCE_START,
    ATK_TEXT_BOUNDARY_SENTENCE_END, ATK_TEXT_BOUNDARY_LINE_START,
    ATK_TEXT_BOUNDARY_LINE_END



type
  AtkTextGranularity* {.size: sizeof(cint).} = enum
    ATK_TEXT_GRANULARITY_CHAR, ATK_TEXT_GRANULARITY_WORD,
    ATK_TEXT_GRANULARITY_SENTENCE, ATK_TEXT_GRANULARITY_LINE,
    ATK_TEXT_GRANULARITY_PARAGRAPH



type
  AtkTextRectangle* = object
    x*: Gint
    y*: Gint
    width*: Gint
    height*: Gint



type
  AtkTextRange* = object
    bounds*: AtkTextRectangle
    startOffset*: Gint
    endOffset*: Gint
    content*: cstring
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim
j='type
  AtkTextIface* = object
'
perl -0777 -p -i -e "s~\Q$j\E~$i$j~s" final.nim

i='type
  AtkTextClipType* {.size: sizeof(cint).} = enum
    ATK_TEXT_CLIP_NONE, ATK_TEXT_CLIP_MIN, ATK_TEXT_CLIP_MAX, ATK_TEXT_CLIP_BOTH
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim
j='type
  AtkTextIface* = object
'
perl -0777 -p -i -e "s~\Q$j\E~$i$j~s" final.nim

# we use our own defined pragma
sed -i "s/\bdynlib: lib\b/libatk/g" final.nim

i='const
  headerfilename* = '
perl -0777 -p -i -e "s~\Q$i\E~  ### ~sg" final.nim

i=' {.deadCodeElim: on.}'
j='{.deadCodeElim: on.}

when defined(windows):
  const LIB_ATK = "libatk-1.0-0.dll"
elif defined(macosx):
  const LIB_ATK = "libatk-1.0(|-0).dylib"
else:
  const LIB_ATK = "libatk-1.0.so(|.0)"

{.pragma: libatk, cdecl, dynlib: LIB_ATK.}

IMPORTLIST

'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

ruby ../fix_new.rb final.nim
sed -i 's/  AtkAttributeSet\* = GSList/  AtkAttributeSet* = object/' final.nim

# fix c2nim --nep1 mess. We need this before glib_fix_T.rb call!
sed -i 's/[(][(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/(\1/g' final.nim
sed -i 's/, [(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/, \1/g' final.nim
perl -0777 -p -i -e 's/(  \(.*,)\n/\1/g' final.nim

sed -i 's/\(, \) \+/\1/g' final.nim

sed -i 's/\(g_Type_Check_Instance_Cast\)(\(`\?\w\+`\?, \)\(atk_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Instance_Get_Interface\)(\(`\?\w\+`\?, \)\(atk_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Check_Class_Cast\)(\(`\?\w\+`\?, \)\(atk_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Instance_Get_Class\)(\(`\?\w\+`\?, \)\(atk_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Type\)(\(`\?\w\+`\?, \)\(atk_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Class_Type\)(\(`\?\w\+`\?, \)\(atk_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Value_Type\)(\(`\?\w\+`\?, \)\(atk_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Fundamental_Type\)(\(`\?\w\+`\?, \)\(atk_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(gTypeIsA\)(\(`\?\w\+`\?, \)\(atk_Type_\w\+\))/\1(\2\3)/g' final.nim

sed -i 's/\batk\([A-Z]\w\+GetType()\)/\l\1/g' final.nim

ruby ../glib_fix_T.rb final.nim atk Atk
sed -i 's/  AtkAttributeSetObj\* = object/  AtkAttributeSetObj* = GSListObj/' final.nim

sed -i 's/\*: var /*: ptr /g' final.nim
sed -i 's/): var /): ptr /g' final.nim

ruby ../glib_fix_proc.rb final.nim atk

sed -i 's/\bATK_TEXT_ATTR_/ATK_TEXT_ATTRIBUTE_/g' final.nim
ruby ../glib_fix_enum_prefix.rb final.nim

sed -i -f ../glib_sedlist final.nim
sed -i -f ../gobject_sedlist final.nim

ruby ../fix_object_of.rb final.nim

i='
from glib import GSListObj, Gboolean, Gpointer, Gunichar

from gobject import GValue, GValueObj, GSignalEmissionHook, GType, GObject, GObjectObj, GObjectClassObj, GTypeInterfaceObj
'
perl -0777 -p -i -e "s%IMPORTLIST%$i%s" final.nim

sed -i 's/  AtkObjectObj\*{\.final\.} = object of gobject\.GObjectObj/  AtkObjectObj* = object of gobject.GObjectObj/' final.nim
sed -i 's/  AtkObjectClassObj\*{\.final\.} = object of gobject\.GObjectClassObj/  AtkObjectClassObj* = object of gobject.GObjectClassObj/' final.nim
sed -i 's/  AtkObjectFactoryObj\*{\.final\.} = object of gobject\.GObjectObj/  AtkObjectFactoryObj* = object of gobject.GObjectObj/' final.nim
sed -i 's/  AtkObjectFactoryClassObj\*{\.final\.} = object of gobject\.GObjectClassObj/  AtkObjectFactoryClassObj* = object of gobject.GObjectClassObj/' final.nim

perl -0777 -p -i -e "s%\Q    pad1*: AtkFunction\E%    pad01*: AtkFunction%s" final.nim

# do not export priv and reserved
sed -i "s/\( priv[0-9]\?[0-9]\?[0-9]\?\)\*: /\1: /g" final.nim
sed -i "s/\(reserved[0-9]\?[0-9]\?[0-9]\?\)\*: /\1: /g" final.nim

sed -i 's/\(dummy[0-9]\{0,2\}\)\*/\1/g' final.nim
sed -i 's/\(reserved[0-9]\{0,2\}\)\*/\1/g' final.nim

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

perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( PangoStyle)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( PangoVariant)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( PangoWeight)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( PangoStretch)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( PangoDirection)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gdouble)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gdouble)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( cdouble)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( cdouble)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gfloat)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gfloat)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( cint)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( cint)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gboolean)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gsize)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Guchar)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gunichar)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gpointer)/\1\2\3\4var\6/sg' final.nim

sed -i 's/: ptr var /: var ptr /g' final.nim
sed -i 's/\(0x\)0*\([0123456789ABCDEF]\)/\1\2/g' final.nim

sed -i 's/\* = atk\([A-Z]\)/* = \L\1/g' final.nim

ruby ../fix_template.rb final.nim atk
sed -i 's/^template object\*(/template `object`\*(/g' final.nim

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

ruby ../mangler.rb final.nim Atk

sed -i '/### "atk/d' final.nim

sed -i 's/ $//g' final.nim
sed -i 's/\bgobject\.GValue\b/GValue/g' final.nim
sed -i 's/\bgobject\.GTypeInterfaceObj\b/GTypeInterfaceObj/g' final.nim

# some procs with get_ prefix do not return something but need var objects instead of pointers:
i='proc getRangeExtents*(text: Text; startOffset: cint; endOffset: cint;
                            coordType: CoordType; rect: TextRectangle) {.
    importc: "atk_text_get_range_extents", libatk.}
'
j='proc getRangeExtents*(text: Text; startOffset: cint; endOffset: cint;
                            coordType: CoordType; rect: var TextRectangleObj) {.
    importc: "atk_text_get_range_extents", libatk.}
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

i='proc getCurrentValue*(obj: Value; value: GValue) {.
    importc: "atk_value_get_current_value", libatk.}
proc getMaximumValue*(obj: Value; value: GValue) {.
    importc: "atk_value_get_maximum_value", libatk.}
proc getMinimumValue*(obj: Value; value: GValue) {.
    importc: "atk_value_get_minimum_value", libatk.}
proc setCurrentValue*(obj: Value; value: GValue): Gboolean {.
    importc: "atk_value_set_current_value", libatk.}
proc getMinimumIncrement*(obj: Value; value: GValue) {.
    importc: "atk_value_get_minimum_increment", libatk.}
'
j='proc getCurrentValue*(obj: Value; value: var GValueObj) {.
    importc: "atk_value_get_current_value", libatk.}
proc getMaximumValue*(obj: Value; value: var GValueObj) {.
    importc: "atk_value_get_maximum_value", libatk.}
proc getMinimumValue*(obj: Value; value: var GValueObj) {.
    importc: "atk_value_get_minimum_value", libatk.}
proc setCurrentValue*(obj: Value; value: var GValueObj): Gboolean {.
    importc: "atk_value_set_current_value", libatk.}
proc getMinimumIncrement*(obj: Value; value: var GValueObj) {.
    importc: "atk_value_get_minimum_increment", libatk.}
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

# generate procs without get_ and set_ prefix
perl -0777 -p -i -e "s/(\n\s*)(proc set)([A-Z]\w+)(\*\([^}]*\) \{[^}]*})/\$&\1proc \`\l\3=\`\4/sg" final.nim
perl -0777 -p -i -e "s/(\n\s*)(proc get)([A-Z]\w+)(\*\([^}]*\): \w[^}]*})/\$&\1proc \l\3\4/sg" final.nim
sed -i 's/proc object\*(/proc `object`\*(/g' final.nim

cat -s final.nim > atk.nim

rm final.h list.txt final.nim
rm -r atk

exit

