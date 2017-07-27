#!/bin/bash
# S. Salewski, 25-JUL-2017
# Generate gtksourceview bindings for Nim
#
gtksv_dir="/home/stefan/Downloads/gtksourceview-3.24.3"
final="final.h" # the input file for c2nim
list="list.txt"
wdir="tmp"

targets='completion-providers/words'

all_t=". ${targets}"

rm -rf $wdir # start from scratch
mkdir $wdir
cd $wdir
cp -r $gtksv_dir/gtksourceview .
cd gtksourceview

# check already done for 3.20
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

# caution: header name without view suffix
cat gtksource.h > all.h

sed -i '/#include <gtksourceview\/gtksourceversion\.h>/d' all.h
touch gtksourceversion.h

for i in completion-providers/words/*.h; do
	echo "#include <gtksourceview/${i}>" >> all.h
done

cd ..

# cpp run with all headers to determine order
echo "cat \\" > $list

cpp -I. `pkg-config --cflags gtksourceview-3.0` gtksourceview/all.h $final

# extract file names and push names to list
grep ssalewski $final | sed 's/_ssalewski;/ \\/' >> $list

# maybe add remaining missing headers

i=`sort $list | uniq -d | wc -l`
if [ $i != 0 ]; then echo 'list contains duplicates!'; exit; fi;

# now we work again with original headers
rm -rf gtksourceview
cp -r $gtksv_dir/gtksourceview .

# insert for each header file its name as first line
for j in $all_t ; do
  for i in gtksourceview/${j}/*.h; do
    sed -i "1i/* file: $i */" $i
    sed -i "1i#define headerfilename \"$i\"" $i # marker for splitting
  done
done
cd gtksourceview
  bash ../$list > ../$final
cd ..

# delete strange macros (define these as empty ones for c2nim)
sed -i "1i#def G_BEGIN_DECLS" $final
sed -i "1i#def G_END_DECLS" $final
sed -i "1i#def G_GNUC_CONST" $final
sed -i "1i#def G_DEPRECATED" $final
sed -i "1i#def G_DEPRECATED_FOR(x)" $final
sed -i "1i#def G_GNUC_INTERNAL" $final
sed -i "1i#def GTK_SOURCE_INTERNAL" $final
sed -i "1i#def GTK_SOURCE_AVAILABLE_IN_ALL" $final
sed -i "1i#def GTK_SOURCE_AVAILABLE_IN_3_4" $final
sed -i "1i#def GTK_SOURCE_AVAILABLE_IN_3_10" $final
sed -i "1i#def GTK_SOURCE_AVAILABLE_IN_3_12" $final
sed -i "1i#def GTK_SOURCE_AVAILABLE_IN_3_14" $final
sed -i "1i#def GTK_SOURCE_AVAILABLE_IN_3_16" $final
sed -i "1i#def GTK_SOURCE_AVAILABLE_IN_3_18" $final
sed -i "1i#def GTK_SOURCE_AVAILABLE_IN_3_20" $final
sed -i "1i#def GTK_SOURCE_AVAILABLE_IN_3_22" $final
sed -i "1i#def GTK_SOURCE_AVAILABLE_IN_3_24" $final
sed -i "1i#def GTK_SOURCE_DEPRECATED_IN_3_10" $final
sed -i "1i#def GTK_SOURCE_DEPRECATED_IN_3_8_FOR(i)" $final
sed -i "1i#def GTK_SOURCE_DEPRECATED_IN_3_10_FOR(i)" $final
sed -i "1i#def GTK_SOURCE_DEPRECATED_IN_3_12_FOR(i)" $final
sed -i "1i#def GTK_SOURCE_DEPRECATED_IN_3_22_FOR(i)" $final
sed -i "1i#def GTK_SOURCE_DEPRECATED_IN_3_24_FOR(i)" $final
#sed -i "1i#def G_DEFINE_AUTOPTR_CLEANUP_FUNC(i, j)" $final

i='#if !defined (GTK_SOURCE_H_INSIDE) && !defined (GTK_SOURCE_COMPILATION)
#  if defined (__GNUC__)
#    warning "Only <gtksourceview/gtksource.h> can be included directly."
#  elif defined (G_OS_WIN32)
#    pragma message("Only <gtksourceview/gtksource.h> can be included directly.")
#  endif
#endif
'
perl -0777 -p -i -e "s%\Q$i\E%%sg" $final

i='#ifdef _MSC_VER
/* For Visual Studio, we need to export the symbols used by the unit tests */
#define GTK_SOURCE_INTERNAL __declspec(dllexport)
#else
#define GTK_SOURCE_INTERNAL G_GNUC_INTERNAL
#endif
'
perl -0777 -p -i -e "s%\Q$i\E%%s" $final

i='#ifndef __GI_SCANNER__

G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceBuffer, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceCompletion, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceCompletionContext, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceCompletionInfo, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceCompletionItem, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceFile, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceFileLoader, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceFileSaver, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceGutter, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceGutterRenderer, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceGutterRendererPixbuf, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceGutterRendererText, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceLanguage, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceLanguageManager, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceMark, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceMap, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourcePrintCompositor, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceSearchContext, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceSearchSettings, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceSpaceDrawer, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceStyleScheme, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceStyleSchemeChooserButton, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceStyleSchemeChooserWidget, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceStyleSchemeManager, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceUndoManager, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceView, g_object_unref)

#endif /* __GI_SCANNER__ */
'
perl -0777 -p -i -e "s%\Q$i\E%%s" $final

# for now we expand these macros manually with gcc -E
i='G_DECLARE_DERIVABLE_TYPE (GtkSourceTag, gtk_source_tag,
			  GTK_SOURCE, TAG,
			  GtkTextTag)
'
j='GType gtk_source_tag_get_type (void);

typedef struct _GtkSourceTag GtkSourceTag;

typedef struct _GtkSourceTagClass GtkSourceTagClass;

struct _GtkSourceTag { GtkTextTag parent_instance; };


static inline GtkSourceTagClass * GTK_SOURCE_TAG_CLASS (gpointer ptr) {
	return (G_TYPE_CHECK_CLASS_CAST(ptr, gtk_source_tag_get_type (), GtkSourceTagClass));
}

static inline gboolean GTK_SOURCE_IS_TAG (gpointer ptr) {
	return (G_TYPE_CHECK_INSTANCE_TYPE (ptr, gtk_source_tag_get_type ()));
}

static inline gboolean GTK_SOURCE_IS_TAG_CLASS (gpointer ptr) {
return (G_TYPE_CHECK_CLASS_TYPE(ptr, gtk_source_tag_get_type ()));
}

static inline GtkSourceTagClass * GTK_SOURCE_TAG_GET_CLASS (gpointer ptr) {
	return (G_TYPE_INSTANCE_GET_CLASS(ptr, gtk_source_tag_get_type (), GtkSourceTagClass));
}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" $final

# missing terminating ) in define in header file -- we should send a bug report upstream
sed -i 's/#define GTK_SOURCE_COMPLETION_INFO_CLASS(klass)     (G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_COMPLETION_INFO, GtkSourceCompletionInfoClass)/#define GTK_SOURCE_COMPLETION_INFO_CLASS(klass)     (G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_COMPLETION_INFO, GtkSourceCompletionInfoClass))/' $final

# add missing {} for struct
sed -i 's/typedef struct _GtkSourceSpaceDrawerPrivate  GtkSourceSpaceDrawerPrivate;/typedef struct _GtkSourceSpaceDrawerPrivate{} GtkSourceSpaceDrawerPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceBufferPrivate		GtkSourceBufferPrivate;/typedef struct _GtkSourceBufferPrivate{} GtkSourceBufferPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceLanguagePrivate	GtkSourceLanguagePrivate;/typedef struct _GtkSourceLanguagePrivate{} GtkSourceLanguagePrivate;/g' $final
sed -i 's/typedef struct _GtkSourceStyleSchemePrivate      GtkSourceStyleSchemePrivate;/typedef struct _GtkSourceStyleSchemePrivate{} GtkSourceStyleSchemePrivate;/g' $final
sed -i 's/typedef struct _GtkSourceMarkPrivate GtkSourceMarkPrivate;/typedef struct _GtkSourceMarkPrivate{} GtkSourceMarkPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceUndoManager		GtkSourceUndoManager;/typedef struct _GtkSourceUndoManager{} GtkSourceUndoManager;/g' $final
sed -i 's/typedef struct _GtkSourceCompletionContextPrivate	GtkSourceCompletionContextPrivate;/typedef struct _GtkSourceCompletionContextPrivate{} GtkSourceCompletionContextPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceCompletionProvider	GtkSourceCompletionProvider;/typedef struct _GtkSourceCompletionProvider{} GtkSourceCompletionProvider;/g' $final
sed -i 's/typedef struct _GtkSourceCompletionPrivate GtkSourceCompletionPrivate;/typedef struct _GtkSourceCompletionPrivate{} GtkSourceCompletionPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceCompletionProposal	GtkSourceCompletionProposal;/typedef struct _GtkSourceCompletionProposal{} GtkSourceCompletionProposal;/g' $final
sed -i 's/typedef struct _GtkSourceCompletionInfoPrivate GtkSourceCompletionInfoPrivate;/typedef struct _GtkSourceCompletionInfoPrivate{} GtkSourceCompletionInfoPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceViewPrivate GtkSourceViewPrivate;/typedef struct _GtkSourceViewPrivate{} GtkSourceViewPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceCompletionItemPrivate	GtkSourceCompletionItemPrivate;/typedef struct _GtkSourceCompletionItemPrivate{} GtkSourceCompletionItemPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceEncoding		GtkSourceEncoding;/typedef struct _GtkSourceEncoding{} GtkSourceEncoding;/g' $final
sed -i 's/typedef struct _GtkSourceFilePrivate  GtkSourceFilePrivate;/typedef struct _GtkSourceFilePrivate{} GtkSourceFilePrivate;/g' $final
sed -i 's/typedef struct _GtkSourceFileLoaderPrivate GtkSourceFileLoaderPrivate;/typedef struct _GtkSourceFileLoaderPrivate{} GtkSourceFileLoaderPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceFileSaverPrivate GtkSourceFileSaverPrivate;/typedef struct _GtkSourceFileSaverPrivate{} GtkSourceFileSaverPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceGutterPrivate	GtkSourceGutterPrivate;/typedef struct _GtkSourceGutterPrivate{} GtkSourceGutterPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceGutterRendererPrivate	GtkSourceGutterRendererPrivate;/typedef struct _GtkSourceGutterRendererPrivate{} GtkSourceGutterRendererPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceGutterRendererPixbufPrivate	GtkSourceGutterRendererPixbufPrivate;/typedef struct _GtkSourceGutterRendererPixbufPrivate{} GtkSourceGutterRendererPixbufPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceGutterRendererTextPrivate	GtkSourceGutterRendererTextPrivate;/typedef struct _GtkSourceGutterRendererTextPrivate{} GtkSourceGutterRendererTextPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceLanguageManagerPrivate GtkSourceLanguageManagerPrivate;/typedef struct _GtkSourceLanguageManagerPrivate{} GtkSourceLanguageManagerPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceMarkAttributesPrivate	GtkSourceMarkAttributesPrivate;/typedef struct _GtkSourceMarkAttributesPrivate{} GtkSourceMarkAttributesPrivate;/g' $final
sed -i 's/typedef struct _GtkSourcePrintCompositorPrivate  GtkSourcePrintCompositorPrivate;/typedef struct _GtkSourcePrintCompositorPrivate{} GtkSourcePrintCompositorPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceSearchContextPrivate  GtkSourceSearchContextPrivate;/typedef struct _GtkSourceSearchContextPrivate{} GtkSourceSearchContextPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceSearchSettingsPrivate  GtkSourceSearchSettingsPrivate;/typedef struct _GtkSourceSearchSettingsPrivate{} GtkSourceSearchSettingsPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceStyle			GtkSourceStyle;/typedef struct _GtkSourceStyle{} GtkSourceStyle;/g' $final
sed -i 's/typedef struct _GtkSourceStyleSchemeManagerPrivate	GtkSourceStyleSchemeManagerPrivate;/typedef struct _GtkSourceStyleSchemeManagerPrivate{} GtkSourceStyleSchemeManagerPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceStyleSchemeChooser	GtkSourceStyleSchemeChooser;/typedef struct _GtkSourceStyleSchemeChooser{} GtkSourceStyleSchemeChooser;/g' $final
sed -i 's/typedef struct _GtkSourceCompletionWordsProposalPrivate		GtkSourceCompletionWordsProposalPrivate;/typedef struct _GtkSourceCompletionWordsProposalPrivate{} GtkSourceCompletionWordsProposalPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceCompletionWordsLibraryPrivate		GtkSourceCompletionWordsLibraryPrivate;/typedef struct _GtkSourceCompletionWordsLibraryPrivate{} GtkSourceCompletionWordsLibraryPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceCompletionWordsBufferPrivate		GtkSourceCompletionWordsBufferPrivate;/typedef struct _GtkSourceCompletionWordsBufferPrivate{} GtkSourceCompletionWordsBufferPrivate;/g' $final
sed -i 's/typedef struct _GtkSourceCompletionWordsPrivate		GtkSourceCompletionWordsPrivate;/typedef struct _GtkSourceCompletionWordsPrivate{} GtkSourceCompletionWordsPrivate;/g' $final

i='GTK_SOURCE_AVAILABLE_IN_3_22
G_DECLARE_DERIVABLE_TYPE (GtkSourceRegion, gtk_source_region,
			  GTK_SOURCE, REGION,
			  GObject)
'
# for now we expand these macros manually with gcc -E
#'
j='GType gtk_source_region_get_type (void);

typedef struct _GtkSourceRegion GtkSourceRegion;

typedef struct _GtkSourceRegionClass GtkSourceRegionClass;

struct _GtkSourceRegion
{
	GObject parent_instance;
};

static inline GtkSourceRegionClass * GTK_SOURCE_REGION_CLASS (gpointer ptr) {
	return (G_TYPE_CHECK_CLASS_CAST(ptr, gtk_source_region_get_type (), GtkSourceRegionClass));
}

static inline gboolean GTK_SOURCE_IS_REGION (gpointer ptr) {
	return (G_TYPE_CHECK_INSTANCE_TYPE (ptr, gtk_source_region_get_type ()));
}

static inline gboolean GTK_SOURCE_IS_REGION_CLASS (gpointer ptr) {
return (G_TYPE_CHECK_CLASS_TYPE(ptr, gtk_source_region_get_type ()));
}

static inline GtkSourceRegionClass * GTK_SOURCE_REGION_GET_CLASS (gpointer ptr) {
	return (G_TYPE_INSTANCE_GET_CLASS(ptr, gtk_source_region_get_type (), GtkSourceRegionClass));
}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" $final

ruby ../fix_.rb $final

# header for Nim module
i='
#ifdef C2NIM
#  dynlib lib
#endif
'
perl -0777 -p -i -e "s/^/$i/" $final

sed -i '/#define GTK_SOURCE_.* const))/d' $final
sed -i 's/\(#define GTK_SOURCE_TYPE_\w\+\)\(\s\+(\?\w\+_get_g\?type\s*()\s*)\?\)/\1()\2/g' $final

#ruby ../struct_reorder.rb $final
ruby ~/ngtk3/common/struct_reorder.rb $final
sed -i 's/\bgchar\b/char/g' $final

sed -i 's/\(#define GTK_SOURCE_\w\+\)\(\s\+(\?\w\+_quark\s*()\s*)\?\)/\1()\2/g' $final

c2nim --nep1 --skipcomments --skipinclude $final
sed -i 's/ {\.bycopy\.}//g' final.nim
sed -i "s/^\s*$//g" final.nim
echo -e "\n\n\n\n"  >> final.nim

perl -0777 -p -i -e "s~([=:] proc \(.*?\)(?:: (?:ptr )?\w+)?)~\1 {.cdecl.}~sg" final.nim

# we use our own defined pragma
sed -i "s/\bdynlib: lib\b/libgsv/g" final.nim

ruby ../remdef.rb final.nim

i='const
  headerfilename* = '
perl -0777 -p -i -e "s~\Q$i\E~  ### ~sg" final.nim

i=' {.deadCodeElim: on.}'
j='{.deadCodeElim: on.}

when defined(windows):
  const LIB_GSV = "libgtksourceview-3.0-0.dll"
elif defined(macosx):
  const LIB_GSV = "libgtksourceview-3.0(|-0).dylib"
else:
  const LIB_GSV = "libgtksourceview-3.0.so(|.0)"

{.pragma: libgsv, cdecl, dynlib: LIB_GSV.}

IMPORTLIST

'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

#ruby ../fix_new.rb final.nim

sed -i 's/[(][(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/(\1/g' final.nim
sed -i 's/, [(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/, \1/g' final.nim
# fix c2nim --nep1 mess
perl -0777 -p -i -e 's/(  \(.*,)\n/\1/g' final.nim
sed -i 's/\(, \) \+/\1/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Cast\)(\(`\?\w\+`\?, \)\(gtk_Source_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Instance_Get_Interface\)(\(`\?\w\+`\?, \)\(gtk_Source_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Check_Class_Cast\)(\(`\?\w\+`\?, \)\(gtk_Source_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Instance_Get_Class\)(\(`\?\w\+`\?, \)\(gtk_Source_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Type\)(\(`\?\w\+`\?, \)\(gtk_Source_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Class_Type\)(\(`\?\w\+`\?, \)\(gtk_Source_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(gTypeIsA\)(\(`\?\w\+`\?, \)\(gtk_Source_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Value_Type\)(\(`\?\w\+`\?, \)\(gtk_Source_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Fundamental_Type\)(\(`\?\w\+`\?, \)\(gtk_Source_Type_\w\+\))/\1(\2\3)/g' final.nim

i='proc gtk_Source_Tag_Class*(`ptr`: Gpointer): ptr GtkSourceTagClass {.inline.} =
  return g_Type_Check_Class_Cast(`ptr`, gtkSourceTagGetType(), gtkSourceTagClass)

proc gtk_Source_Is_Tag*(`ptr`: Gpointer): Gboolean {.inline.} =
  return g_Type_Check_Instance_Type(`ptr`, gtkSourceTagGetType())

proc gtk_Source_Is_Tag_Class*(`ptr`: Gpointer): Gboolean {.inline.} =
  return g_Type_Check_Class_Type(`ptr`, gtkSourceTagGetType())

proc gtk_Source_Tag_Get_Class*(`ptr`: Gpointer): ptr GtkSourceTagClass {.inline.} =
  return g_Type_Instance_Get_Class(`ptr`, gtkSourceTagGetType(), gtkSourceTagClass)
'
j='proc gtk_Source_Tag_Class*(`ptr`: Gpointer): ptr GtkSourceTagClass {.inline.} =
  return g_Type_Check_Class_Cast(`ptr`, tagGetType(), GtkSourceTagClass)

proc gtk_Source_Is_Tag*(`ptr`: Gpointer): Gboolean {.inline.} =
  return g_Type_Check_Instance_Type(`ptr`, tagGetType())

proc gtk_Source_Is_Tag_Class*(`ptr`: Gpointer): Gboolean {.inline.} =
  return g_Type_Check_Class_Type(`ptr`, tagGetType())

proc gtk_Source_Tag_Get_Class*(`ptr`: Gpointer): ptr GtkSourceTagClass {.inline.} =
  return g_Type_Instance_Get_Class(`ptr`, tagGetType(), GtkSourceTagClass)
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc gtk_Source_Region_Class*(`ptr`: Gpointer): ptr GtkSourceRegionClass {.inline.} =
  return g_Type_Check_Class_Cast(`ptr`, gtkSourceRegionGetType(),
                                gtkSourceRegionClass)

proc gtk_Source_Is_Region*(`ptr`: Gpointer): Gboolean {.inline.} =
  return g_Type_Check_Instance_Type(`ptr`, gtkSourceRegionGetType())

proc gtk_Source_Is_Region_Class*(`ptr`: Gpointer): Gboolean {.inline.} =
  return g_Type_Check_Class_Type(`ptr`, gtkSourceRegionGetType())

proc gtk_Source_Region_Get_Class*(`ptr`: Gpointer): ptr GtkSourceRegionClass {.inline.} =
  return g_Type_Instance_Get_Class(`ptr`, gtkSourceRegionGetType(),
                                  gtkSourceRegionClass)
'
j='proc gtk_Source_Region_Class*(`ptr`: Gpointer): ptr GtkSourceRegionClass {.inline.} =
  return g_Type_Check_Class_Cast(`ptr`, gtkSourceRegionGetType(),
                                GtkSourceRegionClass)

proc gtk_Source_Is_Region*(`ptr`: Gpointer): Gboolean {.inline.} =
  return g_Type_Check_Instance_Type(`ptr`, gtkSourceRegionGetType())

proc gtk_Source_Is_Region_Class*(`ptr`: Gpointer): Gboolean {.inline.} =
  return g_Type_Check_Class_Type(`ptr`, gtkSourceRegionGetType())

proc gtk_Source_Region_Get_Class*(`ptr`: Gpointer): ptr GtkSourceRegionClass {.inline.} =
  return g_Type_Instance_Get_Class(`ptr`, gtkSourceRegionGetType(),
                                  GtkSourceRegionClass)
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim


ruby ../fix_new.rb final.nim
ruby ../glib_fix_T.rb final.nim gtksource GtkSource
ruby ../glib_fix_proc.rb final.nim gtkSource
ruby ../glib_fix_enum_prefix.rb final.nim gtksource GtkSource

sed -i -f ../glib_sedlist final.nim
sed -i -f ../gobject_sedlist final.nim
sed -i -f ../cairo_sedlist final.nim
sed -i -f ../pango_sedlist final.nim
sed -i -f ../gdk_pixbuf_sedlist final.nim
sed -i -f ../gdk3_sedlist final.nim
sed -i -f ../gtk3_sedlist final.nim
sed -i -f ../gio_sedlist final.nim

ruby ../fix_object_of.rb final.nim

i='  GtkSourceCompletionProviderIfaceObj* = object
    g_iface*: gobject.GTypeInterfaceObj
'
j='  GtkSourceCompletionProviderIfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkSourceFileSaverObj* = object
    object*: gobject.GObjectObj
'
j='  GtkSourceFileSaverObj*{.final.} = object of gobject.GObjectObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkSourceStyleSchemeObj* = object
    base*: gobject.GObjectObj
'
j='  GtkSourceStyleSchemeObj*{.final.} = object of gobject.GObjectObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkSourceStyleSchemeClassObj* = object
    base_class*: gobject.GObjectClassObj
'
j='  GtkSourceStyleSchemeClassObj*{.final.} = object of gobject.GObjectClassObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkSourceStyleSchemeChooserInterfaceObj* = object
    base_interface*: gobject.GTypeInterfaceObj
'
j='  GtkSourceStyleSchemeChooserInterfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkSourceStyleSchemeChooserInterfaceObj* = object
    baseInterface*: gobject.GTypeInterfaceObj
'
j='  GtkSourceStyleSchemeChooserInterfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkSourceGutterRendererState* {.size: sizeof(cint), pure.} = enum
    NORMAL = 0,
    CURSOR = 1 shl 0,
    PRELIT = 1 shl 1,
    SELECTED = 1 shl 2
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='  GtkSourceGutterRenderer* =  ptr GtkSourceGutterRendererObj
'
perl -0777 -p -i -e "s%\Q$j\E%$i$j%s" final.nim

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

i='  GtkSourceGutterRendererObj*{.final.} = object of gobject.GInitiallyUnownedObj
    priv: ptr GtkSourceGutterRendererPrivateObj
'
j='  GtkSourceGutterRendererObj* = object of gobject.GInitiallyUnownedObj
    priv: ptr GtkSourceGutterRendererPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkSourceGutterRendererTextObj*{.final.} = object of GtkSourceGutterRendererObj
    priv: ptr GtkSourceGutterRendererTextPrivateObj
'
j='  GtkSourceGutterRendererTextObj*{.final.} = object of GtkSourceGutterRendererObj
    priv0: ptr GtkSourceGutterRendererTextPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkSourceViewClassObj*{.final.} = object of gtk3.TextViewClassObj
'
j='  GtkSourceViewClassObj* = object of gtk3.TextViewClassObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkSourceGutterRendererPixbufObj*{.final.} = object of GtkSourceGutterRendererObj
    priv: ptr GtkSourceGutterRendererPixbufPrivateObj
'
j='  GtkSourceGutterRendererPixbufObj*{.final.} = object of GtkSourceGutterRendererObj
    priv00: ptr GtkSourceGutterRendererPixbufPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkSourceViewObj*{.final.} = object of gtk3.TextViewObj
    priv: ptr GtkSourceViewPrivateObj
'
j='  GtkSourceViewObj* = object of gtk3.TextViewObj
    priv: ptr GtkSourceViewPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkSourceBufferObj*{.final.} = object of gtk3.TextBufferObj
    priv: ptr GtkSourceBufferPrivateObj
'
j='  GtkSourceBufferObj* = object of gtk3.TextBufferObj
    priv: ptr GtkSourceBufferPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkSourceBufferClassObj*{.final.} = object of gtk3.TextBufferClassObj'
j='  GtkSourceBufferClassObj* = object of gtk3.TextBufferClassObj'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='when defined(G_OS_WIN32):
  const
    GTK_SOURCE_NEWLINE_TYPE_DEFAULT* = gtk_Source_Newline_Type_Cr_Lf
else:
  const
    GTK_SOURCE_NEWLINE_TYPE_DEFAULT* = gtk_Source_Newline_Type_Lf
'
j='when defined(windows):
  const
    GTK_SOURCE_NEWLINE_TYPE_DEFAULT* = GtkSourceNewlineType.CR_LF
else:
  const
    GTK_SOURCE_NEWLINE_TYPE_DEFAULT* = GtkSourceNewlineType.LF
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='from gtk3 import TextBufferObj, TextMarkObj, TextIter, TextBufferClassObj, TextViewObj, WindowObj, Widget, TextWindowType

from gdk3 import Rectangle

from glib import GList, GSList, GError, Goffset, Gpointer, Gboolean, GQuark, GDestroyNotify

from gobject import GInitiallyUnownedObj, GInitiallyUnownedClassObj, GObject, GObjectObj, GObjectClassObj, GType,
  gTypeCheckClassCast, gTypeCheckInstanceType, gTypeCheckClassType, gTypeInstanceGetClass

from gdk_pixbuf import GdkPixbuf

from cairo import Context

from gio import GFile, GMountOperation, GInputStream, GCancellable, GAsyncResult, GFileProgressCallback, GAsyncReadyCallback, GIcon, GSettingsBindFlags

'
perl -0777 -p -i -e "s%IMPORTLIST%$i%s" final.nim

i='type
  GtkSourceBracketMatchType* {.size: sizeof(cint), pure.} = enum
    NONE, OUT_OF_RANGE,
    NOT_FOUND, FOUND
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='type
  GtkSourceBufferPrivateObj = object
'
perl -0777 -p -i -e "s%\Q$j\E%$i$j%s" final.nim

sed -i 's/GtkScrollStep/gtk3.ScrollStep/g' final.nim
sed -i 's/\bGtkTextWindowType\b/gtk3.TextWindowType/g' final.nim
sed -i 's/\bGtkWrapMode\b/gtk3.WrapMode/g' final.nim
sed -i 's/\bGtkUnit\b/gtk3.Unit/g' final.nim

sed -i 's/  GtkSourceGutterRendererClassObj\*{\.final\.} = object of gobject\.GInitiallyUnownedClassObj/  GtkSourceGutterRendererClassObj* = object of gobject.GInitiallyUnownedClassObj/g' final.nim

# these are indeed GObjects 
for i in GtkSourceStyle GtkSourceUndoManager; do
	sed -i "s/  ${i}Obj\* = object/  ${i}Obj\*{\.final\.} = object of GObjectObj/" final.nim
done
sed -i "s/  GtkSourceCompletionProviderObj\* = object/  GtkSourceCompletionProviderObj\* = object of GObjectObj/" final.nim

sed -i "s/  GtkSourceCompletionWordsObj\*{\.final\.} = object of GObjectObj/  GtkSourceCompletionWordsObj*{.final.} = object of GtkSourceCompletionProviderObj/" final.nim

ruby ../mangler.rb final.nim GtkSource
ruby ../mangler.rb final.nim GTK_SOURCE_

sed -i '/### "gtksource/d' final.nim

sed -i 's/\(: ptr \)\w\+PrivateObj/: pointer/g' final.nim
sed -i '/  \w\+PrivateObj = object$/d' final.nim

perl -0777 -p -i -e "s%\ntype\n{2,}%\ntype\n%sg" final.nim
perl -0777 -p -i -e "s%\n(type\n){2,}%\ntype\n%sg" final.nim
perl -0777 -p -i -e "s%\ntype\ntemplate%\ntemplate%sg" final.nim

sed -i "s/ $//g" final.nim
sed -i 's/\* = gtkSource\([A-Z]\)/* = \L\1/g' final.nim

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

ruby ../fix_template.rb final.nim gtk_Source

sed -i 's/proc end\b/proc `end`/g' final.nim
sed -i 's/ $//g' final.nim

sed -i 's/= (1 shl \([0-9]\)),/= 1 shl \1,/g' final.nim
sed -i 's/= (1 shl \([0-9]\))$/= 1 shl \1/g' final.nim

sed -i 's/gtkSource\([A-Z]\)/\L\1/g' final.nim

# generate procs without get_ and set_ prefix
perl -0777 -p -i -e "s/(\n\s*)(proc set)([A-Z]\w+)(\*\([^}]*\) \{[^}]*})/\$&\1proc \`\l\3=\`\4/sg" final.nim
perl -0777 -p -i -e "s/(\n\s*)(proc get)([A-Z]\w+)(\*\([^}]*\): \w[^}]*})/\$&\1proc \l\3\4/sg" final.nim

sed -i 's/\(proc \w\+New\)[A-Z]\w\+/\1/g' final.nim
sed -i 's/proc \(\w\+\)New\*/proc new\u\1*/g' final.nim

i='proc newCompletionItem*(label: cstring; text: cstring; icon: gdk_pixbuf.GdkPixbuf;
                                info: cstring): CompletionItem {.
    importc: "gtk_source_completion_item_new", libgsv.}
proc newCompletionItem*(markup: cstring; text: cstring;
    icon: gdk_pixbuf.GdkPixbuf; info: cstring): CompletionItem {.
    importc: "gtk_source_completion_item_new_with_markup", libgsv.}
'
j='proc newCompletionItemWithLabel*(label: cstring; text: cstring; icon: gdk_pixbuf.GdkPixbuf;
                                info: cstring): CompletionItem {.
    importc: "gtk_source_completion_item_new", libgsv.}
proc newCompletionItemWithMarkup*(markup: cstring; text: cstring;
    icon: gdk_pixbuf.GdkPixbuf; info: cstring): CompletionItem {.
    importc: "gtk_source_completion_item_new_with_markup", libgsv.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='template typeStyle*(): expr =
  (styleGetType())
'
j='template typeStyle*(): expr = gtksource.styleGetType()
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

cat -s final.nim > gtksource.nim

#rm final.h list.txt final.nim
#rm -r gtksourceview

exit

