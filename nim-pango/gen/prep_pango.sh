#!/bin/bash
# S. Salewski, 22-JUL-2017
# generate pango bindings for Nim
#
pango_dir="/home/stefan/Downloads/pango-1.40.7"
final="final.h" # the input file for c2nim
list="list.txt"
wdir="tmp_pango"

targets=''
all_t=". ${targets}"

rm -rf $wdir # start from scratch
mkdir $wdir
cd $wdir
cp -r $pango_dir/pango .
cd pango

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

cat pango.h > all.h

# add optional headers
echo '#include <pango/pango-impl-utils.h>' >> all.h
echo '#include <pango/pango-modules.h>' >> all.h
echo '#include <pango/pangofc-fontmap.h>' >> all.h
echo '#include <pango/pango-ot.h>' >> all.h
# we will split these in separate modules
echo '#include <pango/pangocairo.h>' >> all.h
echo '#include <pango/pangoxft.h>' >> all.h
echo '#include <pango/pangoft2.h>' >> all.h
echo '#include <pango/pangocoretext.h>' >> all.h # macosx
echo '#include <pango/pangocairo-coretext.h>' >> all.h
echo '#include <pango/pangowin32.h>' >> all.h

cd ..
mkdir Carbon
touch Carbon/Carbon.h
touch windows.h
touch cairo-quartz.h
# cpp run with all headers to determine order
echo "cat \\" > $list

cpp -I. `pkg-config --cflags gtk+-3.0` pango/all.h $final
echo 'pango-features.h \' >> $list
# extract file names and push names to list
grep ssalewski $final | sed 's/_ssalewski;/ \\/' >> $list

# may that be usefull?
#echo 'pango-script-lang-table.h \' >> $list
#echo 'pango-color-table.h \' >> $list

i=`sort $list | uniq -d | wc -l`
if [ $i != 0 ]; then echo 'list contains duplicates!'; exit; fi;

# now we work again with original headers
rm -rf pango
cp -r $pango_dir/pango . 

# insert for each header file its name as first line
for j in $all_t ; do
  for i in pango/${j}/*.h; do
    sed -i "1i/* file: $i */" $i
    sed -i "1i#define headerfilename \"$i\"" $i # marker for splitting
  done
done

cd pango
  bash ../$list > ../$final
cd ..

# empty macros for c2nim
sed -i "1i#def G_BEGIN_DECLS" $final
sed -i "1i#def G_END_DECLS" $final
sed -i "1i#def G_GNUC_CONST" $final
sed -i "1i#def G_GNUC_PURE" $final
sed -i "1i#def G_GNUC_UNUSED" $final
sed -i "1i#def G_DEPRECATED_FOR(i)" $final
sed -i "1i#def PANGO_DEPRECATED_FOR(i)" $final
sed -i "1i#def PANGO_DEPRECATED_IN_1_32" $final
sed -i "1i#def PANGO_DEPRECATED_IN_1_38" $final
sed -i "1i#def PANGO_DEPRECATED" $final
sed -i "1i#def _PANGO_EXTERN" $final
sed -i "1i#def G_DEPRECATED" $final
sed -i "1i#def PANGO_DISABLE_DEPRECATED" $final
sed -i "1i#def PANGO_AVAILABLE_IN_ALL" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_2" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_6" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_4" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_8" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_18" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_10" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_14" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_24" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_16" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_26" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_20" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_22" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_12" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_38" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_30" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_32" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_34" $final
sed -i "1i#def PANGO_AVAILABLE_IN_1_12" $final

sed -i "/#define PANGO_MATRIX_INIT { 1., 0., 0., 1., 0., 0. }/d" $final

i='#define PANGO_ENGINE_DEFINE_TYPE(name, prefix, class_init, instance_init, parent_type) \
static GType prefix ## _type;						  \
static void								  \
prefix ## _register_type (GTypeModule *module)				  \
{									  \
  const GTypeInfo object_info =						  \
    {									  \
      sizeof (name ## Class),						  \
      (GBaseInitFunc) NULL,						  \
      (GBaseFinalizeFunc) NULL,						  \
      (GClassInitFunc) class_init,					  \
      (GClassFinalizeFunc) NULL,					  \
      NULL,          /* class_data */					  \
      sizeof (name),							  \
      0,             /* n_prelocs */					  \
      (GInstanceInitFunc) instance_init,				  \
      NULL           /* value_table */					  \
    };									  \
									  \
  prefix ## _type =  g_type_module_register_type (module, parent_type,	  \
						  # name,		  \
						  &object_info, 0);	  \
}
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define PANGO_ENGINE_LANG_DEFINE_TYPE(name, prefix, class_init, instance_init)	\
  PANGO_ENGINE_DEFINE_TYPE (name, prefix,				\
			    class_init, instance_init,			\
			    PANGO_TYPE_ENGINE_LANG)
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define PANGO_ENGINE_SHAPE_DEFINE_TYPE(name, prefix, class_init, instance_init)	\
  PANGO_ENGINE_DEFINE_TYPE (name, prefix,				\
			    class_init, instance_init,			\
			    PANGO_TYPE_ENGINE_SHAPE)

'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifdef PANGO_MODULE_PREFIX
#define PANGO_MODULE_ENTRY(func) _PANGO_MODULE_ENTRY2(PANGO_MODULE_PREFIX,func)
#define _PANGO_MODULE_ENTRY2(prefix,func) _PANGO_MODULE_ENTRY3(prefix,func)
#define _PANGO_MODULE_ENTRY3(prefix,func) prefix##_script_engine_##func
#else
#define PANGO_MODULE_ENTRY(func) script_engine_##func
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='static inline G_GNUC_UNUSED int
pango_unichar_width (gunichar c)
{
  return G_UNLIKELY (g_unichar_iszerowidth (c)) ? 0 :
	   G_UNLIKELY (g_unichar_iswide (c)) ? 2 : 1;
}

static G_GNUC_UNUSED glong
pango_utf8_strwidth (const gchar *p)
{
  glong len = 0;
  g_return_val_if_fail (p != NULL, 0);

  while (*p)
    {
      len += pango_unichar_width (g_utf8_get_char (p));
      p = g_utf8_next_char (p);
    }

  return len;
}

/* Glib'\''s g_utf8_strlen() is broken and stops at embedded NUL'\''s.
 * Wrap it here. */
static G_GNUC_UNUSED glong
pango_utf8_strlen (const gchar *p, gssize max)
{
  glong len = 0;
  const gchar *start = p;
  g_return_val_if_fail (p != NULL || max == 0, 0);

  if (max <= 0)
    return g_utf8_strlen (p, max);

  p = g_utf8_next_char (p);
  while (p - start < max)
    {
      ++len;
      p = g_utf8_next_char (p);
    }

  /* only do the last len increment if we got a complete
   * char (don'\''t count partial chars)
   */
  if (p - start <= max)
    ++len;

  return len;
}


/* To be made public at some point */

static G_GNUC_UNUSED void
pango_glyph_string_reverse_range (PangoGlyphString *glyphs,
				  int start, int end)
{
  int i, j;

  for (i = start, j = end - 1; i < j; i++, j--)
    {
      PangoGlyphInfo glyph_info;
      gint log_cluster;

      glyph_info = glyphs->glyphs[i];
      glyphs->glyphs[i] = glyphs->glyphs[j];
      glyphs->glyphs[j] = glyph_info;

      log_cluster = glyphs->log_clusters[i];
      glyphs->log_clusters[i] = glyphs->log_clusters[j];
      glyphs->log_clusters[j] = log_cluster;
    }
}
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

# add missing {} for struct
sed -i 's/typedef struct _PangoCoverage PangoCoverage;/typedef struct _PangoCoverage{} PangoCoverage;/g' $final
sed -i 's/typedef struct _PangoScriptIter PangoScriptIter;/typedef struct _PangoScriptIter{} PangoScriptIter;/g' $final
sed -i 's/typedef struct _PangoLanguage PangoLanguage;/typedef struct _PangoLanguage{} PangoLanguage;/g' $final
sed -i 's/typedef struct _PangoFontDescription PangoFontDescription;/typedef struct _PangoFontDescription{} PangoFontDescription;/g' $final
sed -i 's/typedef struct _PangoAttrIterator PangoAttrIterator;/typedef struct _PangoAttrIterator{} PangoAttrIterator;/g' $final
sed -i 's/typedef struct _PangoAttrList     PangoAttrList;/typedef struct _PangoAttrList{} PangoAttrList;/g' $final
sed -i 's/typedef struct _PangoFontsetSimple  PangoFontsetSimple;/typedef struct _PangoFontsetSimple{} PangoFontsetSimple;/g' $final
sed -i 's/typedef struct _PangoTabArray PangoTabArray;/typedef struct _PangoTabArray{} PangoTabArray;/g' $final
sed -i 's/typedef struct _PangoLayout      PangoLayout;/typedef struct _PangoLayout{} PangoLayout;/g' $final
sed -i 's/typedef struct _PangoLayoutIter PangoLayoutIter;/typedef struct _PangoLayoutIter{} PangoLayoutIter;/g' $final
sed -i 's/typedef struct _PangoRendererPrivate PangoRendererPrivate;/typedef struct _PangoRendererPrivate{} PangoRendererPrivate;/g' $final
sed -i 's/typedef struct _PangoCairoFontMap        PangoCairoFontMap;/typedef struct _PangoCairoFontMap{} PangoCairoFontMap;/g' $final
sed -i 's/typedef struct _PangoCairoFont      PangoCairoFont;/typedef struct _PangoCairoFont{} PangoCairoFont;/g' $final
sed -i 's/typedef struct _PangoXftRendererPrivate PangoXftRendererPrivate;/typedef struct _PangoXftRendererPrivate{} PangoXftRendererPrivate;/g' $final
sed -i 's/typedef struct _PangoFT2FontMap      PangoFT2FontMap;/typedef struct _PangoFT2FontMap{} PangoFT2FontMap;/g' $final
sed -i 's/typedef struct _PangoWin32FontCache PangoWin32FontCache;/typedef struct _PangoWin32FontCache{} PangoWin32FontCache;/g' $final
sed -i 's/typedef struct _PangoMap PangoMap;/typedef struct _PangoMap{} PangoMap;/g' $final
sed -i 's/typedef struct _PangoOTInfo       PangoOTInfo;/typedef struct _PangoOTInfo{} PangoOTInfo;/g' $final
sed -i 's/typedef struct _PangoOTBuffer     PangoOTBuffer;/typedef struct _PangoOTBuffer{} PangoOTBuffer;/g' $final
sed -i 's/typedef struct _PangoOTRuleset    PangoOTRuleset;/typedef struct _PangoOTRuleset{} PangoOTRuleset;/g' $final
sed -i 's/typedef struct _PangoFcFontsetKey  PangoFcFontsetKey;/typedef struct _PangoFcFontsetKey{} PangoFcFontsetKey;/g' $final
sed -i 's/typedef struct _PangoFcFontKey     PangoFcFontKey;/typedef struct _PangoFcFontKey{} PangoFcFontKey;/g' $final
sed -i 's/typedef struct _PangoFcFontMapPrivate PangoFcFontMapPrivate;/typedef struct _PangoFcFontMapPrivate{} PangoFcFontMapPrivate;/g' $final
sed -i 's/typedef struct _PangoCoreTextFontKey      PangoCoreTextFontKey;/typedef struct _PangoCoreTextFontKey{} PangoCoreTextFontKey;/g' $final
sed -i 's/typedef struct _PangoCoreTextFace         PangoCoreTextFace;/typedef struct _PangoCoreTextFace{} PangoCoreTextFace;/g' $final
sed -i 's/typedef struct _PangoCoreTextFontPrivate  PangoCoreTextFontPrivate;/typedef struct _PangoCoreTextFontPrivate{} PangoCoreTextFontPrivate;/g' $final
sed -i 's/typedef struct _PangoContext PangoContext;/typedef struct _PangoContext{} PangoContext;/g' $final
sed -i 's/typedef struct _PangoXftFont    PangoXftFont;/typedef struct _PangoXftFont{} PangoXftFont;/g' $final

ruby ../fix_.rb $final

i='
#ifdef C2NIM
#  dynlib lib
#endif
'
perl -0777 -p -i -e "s/^/$i/" $final

sed -i 's/#define PANGO_TYPE_COLOR pango_color_get_type ()/#define PANGO_TYPE_COLOR (pango_color_get_type ())/g' $final
sed -i 's/#define PANGO_TYPE_ATTR_LIST pango_attr_list_get_type ()/#define PANGO_TYPE_ATTR_LIST (pango_attr_list_get_type ())/g' $final

sed -i 's/\(#define PANGO_TYPE_\w\+\)\(\s\+(\?\w\+_get_g\?type\s*()\s*)\?\)/\1()\2/g' $final

#ruby ../func_alias_reorder.rb final.h PANGO

ruby ../struct_reorder.rb $final

sed -i 's/\bgchar\b/char/g' $final

c2nim --nep1 --skipcomments --skipinclude $final
sed -i 's/ {\.bycopy\.}//g' final.nim

sed -i "s/^\s*$//g" final.nim
echo -e "\n\n\n\n"  >> final.nim

for i in g_Maxuint pango_Version_Major pango_Version_Minor pango_Version_Micro pango_Enable_Engine pango_Enable_Backend; do
  sed -i "s/\b${i}\b/\U&/g" final.nim
done

for i in PANGO_ENABLE_BACKEND PANGO_ENABLE_ENGINE PANGO_DISABLE_DEPRECATED ; do
  sed -i "s/ defined\((${i})\)/ \U\1/g" final.nim
done

# we use our own defined pragma
sed -i "s/\bdynlib: lib\b/libpango/g" final.nim

i='const
  headerfilename* = '
perl -0777 -p -i -e "s~\Q$i\E~  ### ~sg" final.nim

i=' {.deadCodeElim: on.}
'
j='{.deadCodeElim: on.}

# Note: Not all pango C macros are available in Nim yet.
# Some are converted by c2nim to templates, some manually to procs.
# Most of these should be not necessary for Nim programmers.
# We may have to add more and to test and fix some, or remove unnecessary ones completely...
# pango-color-table.h and pango-script-lang-table.h is currently not included.

when defined(windows): 
  const LIB_PANGO* = "libpango-1.0-0.dll"
elif defined(macosx):
  const LIB_PANGO* = "libpango-1.0.dylib"
else: 
  const LIB_PANGO* = "libpango-1.0.so.0"

{.pragma: libpango, cdecl, dynlib: LIB_PANGO.}

const
  PANGO_DISABLE_DEPRECATED* = false
  PANGO_ENABLE_BACKEND* = true
  PANGO_ENABLE_ENGINE* = true
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='proc pangoGravityGetForScript*(script: PangoScript; baseGravity: PangoGravity;
                              hint: PangoGravityHint): PangoGravity {.
    importc: "pango_gravity_get_for_script", libpango.}
proc pangoGravityGetForScriptAndWidth*(script: PangoScript; wide: Gboolean;
                                      baseGravity: PangoGravity;
                                      hint: PangoGravityHint): PangoGravity {.
    importc: "pango_gravity_get_for_script_and_width", libpango.}
'
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim
j='proc pangoScriptForUnichar*(ch: Gunichar): PangoScript {.
    importc: "pango_script_for_unichar", libpango.}
'
perl -0777 -p -i -e "s/\Q$j\E/$i$j/s" final.nim

i='const
  PANGO_SCALE_XX_SMALL* = (cast[cdouble](0.5787037037036999))
  PANGO_SCALE_X_SMALL* = (cast[cdouble](0.6444444444444))
  PANGO_SCALE_SMALL* = (cast[cdouble](0.8333333333333))
  PANGO_SCALE_MEDIUM* = (cast[cdouble](1.0))
  PANGO_SCALE_LARGE* = (cast[cdouble](1.2))
  PANGO_SCALE_X_LARGE* = (cast[cdouble](1.4399999999999))
  PANGO_SCALE_XX_LARGE* = (cast[cdouble](1.728))
'
j='const
  PANGO_SCALE_XX_SMALL* = cdouble(0.5787037037036999)
  PANGO_SCALE_X_SMALL* = cdouble(0.6444444444444)
  PANGO_SCALE_SMALL* = cdouble(0.8333333333333)
  PANGO_SCALE_MEDIUM* = cdouble(1.0)
  PANGO_SCALE_LARGE* = cdouble(1.2)
  PANGO_SCALE_X_LARGE* = cdouble(1.4399999999999)
  PANGO_SCALE_XX_LARGE* = cdouble(1.728)
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='  type
    PangoAttribute* = object
      klass*: ptr PangoAttrClass
      startIndex*: Guint
      endIndex*: Guint

  type
    PangoAttrClass* = object
'
j='  type
    PangoAttribute* = object
      klass*: ptr PangoAttrClass
      startIndex*: Guint
      endIndex*: Guint

  #type
    PangoAttrClass* = object
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  PangoAttrType* {.size: sizeof(cint).} = enum
    PANGO_ATTR_INVALID, PANGO_ATTR_LANGUAGE, PANGO_ATTR_FAMILY, PANGO_ATTR_STYLE,
    PANGO_ATTR_WEIGHT, PANGO_ATTR_VARIANT, PANGO_ATTR_STRETCH, PANGO_ATTR_SIZE,
    PANGO_ATTR_FONT_DESC, PANGO_ATTR_FOREGROUND, PANGO_ATTR_BACKGROUND,
    PANGO_ATTR_UNDERLINE, PANGO_ATTR_STRIKETHROUGH, PANGO_ATTR_RISE,
    PANGO_ATTR_SHAPE, PANGO_ATTR_SCALE, PANGO_ATTR_FALLBACK,
    PANGO_ATTR_LETTER_SPACING, PANGO_ATTR_UNDERLINE_COLOR,
    PANGO_ATTR_STRIKETHROUGH_COLOR, PANGO_ATTR_ABSOLUTE_SIZE, PANGO_ATTR_GRAVITY,
    PANGO_ATTR_GRAVITY_HINT, PANGO_ATTR_FONT_FEATURES,
    PANGO_ATTR_FOREGROUND_ALPHA, PANGO_ATTR_BACKGROUND_ALPHA
'
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim
j='proc pangoFontGetFontMap*(font: ptr PangoFont): ptr PangoFontMap {.
    importc: "pango_font_get_font_map", libpango.}
'
perl -0777 -p -i -e "s/\Q$j\E/$j$i/s" final.nim

i='const
  PANGO_GLYPH_EMPTY* = (cast[PangoGlyph](0x0FFFFFFF))
  PANGO_GLYPH_INVALID_INPUT* = (cast[PangoGlyph](0xFFFFFFFF))
  PANGO_GLYPH_UNKNOWN_FLAG* = (cast[PangoGlyph](0x10000000))
'
j='const
  PANGO_GLYPH_EMPTY* = PangoGlyph(0x0FFFFFFF)
  PANGO_GLYPH_INVALID_INPUT* = PangoGlyph(0xFFFFFFFF)
  PANGO_GLYPH_UNKNOWN_FLAG* = PangoGlyph(0x10000000)
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  PangoAttrDataCopyFunc* = proc (userData: Gconstpointer): Gpointer
'
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim
j='  PangoAttrShape* = object
    attr*: PangoAttribute
    inkRect*: PangoRectangle
    logicalRect*: PangoRectangle
    data*: Gpointer
    copyFunc*: PangoAttrDataCopyFunc
    destroyFunc*: GDestroyNotify
'
perl -0777 -p -i -e "s/\Q$j\E/$i$j/s" final.nim

i='type
  PangoFontsetForeachFunc* = proc (fontset: ptr PangoFontset; font: ptr PangoFont;
                                userData: Gpointer): Gboolean
'
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim
j='type
  PangoItem* = object
    offset*: Gint
    length*: Gint
    numChars*: Gint
    analysis*: PangoAnalysis
'
k='#type
  PangoItem* = object
    offset*: Gint
    length*: Gint
    numChars*: Gint
    analysis*: PangoAnalysis
'
perl -0777 -p -i -e "s/\Q$j\E/$i$k/s" final.nim

i='when defined(xftVersion) and xftVersion >= 20000:
else:
'
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim

sed -i "s/_XFT_NO_COMPAT_\* = true/XFT_NO_COMPAT* = true/g" final.nim
sed -i "s/priv\*: ptr PangoXftRendererPrivate/priv0*: ptr PangoXftRendererPrivate/g" final.nim

i='  PangoFontClass* = object
    parentClass*: GObjectClass
    describe*: proc (font: ptr PangoFont): ptr PangoFontDescription
    getCoverage*: proc (font: ptr PangoFont; lang: ptr PangoLanguage): ptr PangoCoverage
    findShaper*: proc (font: ptr PangoFont; lang: ptr PangoLanguage; ch: Guint32): ptr PangoEngineShape
    getGlyphExtents*: proc (font: ptr PangoFont; glyph: PangoGlyph;
                          inkRect: ptr PangoRectangle;
                          logicalRect: ptr PangoRectangle)
    getMetrics*: proc (font: ptr PangoFont; language: ptr PangoLanguage): ptr PangoFontMetrics
    getFontMap*: proc (font: ptr PangoFont): ptr PangoFontMap
    describeAbsolute*: proc (font: ptr PangoFont): ptr PangoFontDescription
    pangoReserved1*: proc ()
    pangoReserved2*: proc ()
'
j='  PangoFontClass* = object
    parentClass*: GObjectClass
    describe*: proc (font: ptr PangoFont): ptr PangoFontDescription
    getCoverage*: proc (font: ptr PangoFont; lang: ptr PangoLanguage): ptr PangoCoverage
    findShaper*: proc (font: ptr PangoFont; lang: ptr PangoLanguage; ch: Guint32): ptr PangoEngineShape
    getGlyphExtents*: proc (font: ptr PangoFont; glyph: PangoGlyph;
                          inkRect: ptr PangoRectangle;
                          logicalRect: ptr PangoRectangle)
    getMetrics*: proc (font: ptr PangoFont; language: ptr PangoLanguage): ptr PangoFontMetrics
    getFontMap*: proc (font: ptr PangoFont): ptr PangoFontMap
    describeAbsolute*: proc (font: ptr PangoFont): ptr PangoFontDescription
    pangoReserved01*: proc ()
    pangoReserved02*: proc ()
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  PangoFontMapClass* = object
    parentClass*: GObjectClass
    loadFont*: proc (fontmap: ptr PangoFontMap; context: ptr PangoContext;
                   desc: ptr PangoFontDescription): ptr PangoFont
    listFamilies*: proc (fontmap: ptr PangoFontMap;
                       families: ptr ptr ptr PangoFontFamily; nFamilies: ptr cint)
    loadFontset*: proc (fontmap: ptr PangoFontMap; context: ptr PangoContext;
                      desc: ptr PangoFontDescription; language: ptr PangoLanguage): ptr PangoFontset
    shapeEngineType*: cstring
    getSerial*: proc (fontmap: ptr PangoFontMap): Guint
    changed*: proc (fontmap: ptr PangoFontMap)
    pangoReserved1*: proc ()
    pangoReserved2*: proc ()
'
j='type
  PangoFontMapClass* = object
    parentClass*: GObjectClass
    loadFont*: proc (fontmap: ptr PangoFontMap; context: ptr PangoContext;
                   desc: ptr PangoFontDescription): ptr PangoFont
    listFamilies*: proc (fontmap: ptr PangoFontMap;
                       families: ptr ptr ptr PangoFontFamily; nFamilies: ptr cint)
    loadFontset*: proc (fontmap: ptr PangoFontMap; context: ptr PangoContext;
                      desc: ptr PangoFontDescription; language: ptr PangoLanguage): ptr PangoFontset
    shapeEngineType*: cstring
    getSerial*: proc (fontmap: ptr PangoFontMap): Guint
    changed*: proc (fontmap: ptr PangoFontMap)
    pangoReserved1a*: proc ()
    pangoReserved2a*: proc ()
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='  PangoFontMapClass* = object
    parentClass*: GObjectClass
    loadFont*: proc (fontmap: ptr PangoFontMap; context: ptr PangoContext;
                   desc: ptr PangoFontDescription): ptr PangoFont
    listFamilies*: proc (fontmap: ptr PangoFontMap;
                       families: ptr ptr ptr PangoFontFamily; nFamilies: ptr cint)
    loadFontset*: proc (fontmap: ptr PangoFontMap; context: ptr PangoContext;
                      desc: ptr PangoFontDescription; language: ptr PangoLanguage): ptr PangoFontset
    shapeEngineType*: cstring
    getSerial*: proc (fontmap: ptr PangoFontMap): Guint
    changed*: proc (fontmap: ptr PangoFontMap)
    pangoReserved1*: proc ()
    pangoReserved2*: proc ()
'
j='  PangoFontMapClass* = object
    parentClass*: GObjectClass
    loadFont*: proc (fontmap: ptr PangoFontMap; context: ptr PangoContext;
                   desc: ptr PangoFontDescription): ptr PangoFont
    listFamilies*: proc (fontmap: ptr PangoFontMap;
                       families: ptr ptr ptr PangoFontFamily; nFamilies: ptr cint)
    loadFontset*: proc (fontmap: ptr PangoFontMap; context: ptr PangoContext;
                      desc: ptr PangoFontDescription; language: ptr PangoLanguage): ptr PangoFontset
    shapeEngineType*: cstring
    getSerial*: proc (fontmap: ptr PangoFontMap): Guint
    changed*: proc (fontmap: ptr PangoFontMap)
    pangoReserved1b*: proc ()
    pangoReserved2b*: proc ()
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='  PangoCoreTextFontMap* = object
    parentInstance*: PangoFontMap
    serial*: Guint
'
j='  PangoCoreTextFontMap* = object
    parentInstance*: PangoFontMap
    serial0*: Guint
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='  const
    PANGO_OT_ALL_GLYPHS* = (cast[Guint](0x0000FFFF))
    PANGO_OT_NO_FEATURE* = (cast[Guint](0x0000FFFF))
    PANGO_OT_NO_SCRIPT* = (cast[Guint](0x0000FFFF))
    PANGO_OT_DEFAULT_LANGUAGE* = (cast[Guint](0x0000FFFF))
'
j='  const
    PANGO_OT_ALL_GLYPHS* = Guint(0x0000FFFF)
    PANGO_OT_NO_FEATURE* = Guint(0x0000FFFF)
    PANGO_OT_NO_SCRIPT* = Guint(0x0000FFFF)
    PANGO_OT_DEFAULT_LANGUAGE* = Guint(0x0000FFFF)
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='  type
    PangoOTTag* = Guint32
  template pango_Ot_Tag_Make*(c1, c2, c3, c4: expr): expr =
    (cast[PangoOTTag](ft_Make_Tag(c1, c2, c3, c4)))

  template pango_Ot_Tag_Make_From_String*(s: expr): expr =
    (pango_Ot_Tag_Make((cast[cstring](s))[0], (cast[cstring](s))[1],
                       (cast[cstring](s))[2], (cast[cstring](s))[3]))
'
j='  type
    PangoOTTag* = Guint32
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim
i="  const
    PANGO_OT_TAG_DEFAULT_SCRIPT* = pango_Ot_Tag_Make('D', 'F', 'L', 'T')
    PANGO_OT_TAG_DEFAULT_LANGUAGE* = pango_Ot_Tag_Make('d', 'f', 'l', 't')
"
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim

# legacy xlib symbols
sed -i 's/\bptr Display\b/PDisplay/' final.nim
sed -i 's/\bptr LOGFONTA\b/PLOGFONTA/' final.nim

ruby ../glib_fix_proc.rb final.nim pango
sed -i -f ../cairo_sedlist final.nim
sed -i -f ../glib_sedlist final.nim
sed -i -f ../gobject_sedlist final.nim

i='from glib import Gunichar,
  Gboolean, Gpointer, Gconstpointer, GList, GSList, GString, GError, GDestroyNotify, GMarkupParseContext, G_MAXUINT

from gobject import GObjectObj, GObjectClassObj, GType, GTypeModule,
  gTypeCheckClassType, gTypeCheckClassCast, gTypeCheckInstanceCast, gTypeCheckInstanceType

'
j='when defined(windows): 
  const LIB_PANGO* = "libpango-1.0-0.dll"
'
perl -0777 -p -i -e "s~\Q$j\E~$i$j~s" final.nim

# fix c2nim --nep1 mess. We need this before glib_fix_T.rb call!
sed -i 's/[(][(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/(\1/g' final.nim
sed -i 's/, [(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/, \1/g' final.nim
perl -0777 -p -i -e 's/(  \(.*,)\n/\1/g' final.nim

sed -i 's/\(, \) \+/\1/g' final.nim

sed -i 's/\(g_Type_Check_Instance_Cast\)(\(`\?\w\+`\?, \)\(pango_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Instance_Get_Interface\)(\(`\?\w\+`\?, \)\(pango_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Check_Class_Cast\)(\(`\?\w\+`\?, \)\(pango_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Instance_Get_Class\)(\(`\?\w\+`\?, \)\(pango_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Type\)(\(`\?\w\+`\?, \)\(pango_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Class_Type\)(\(`\?\w\+`\?, \)\(pango_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Value_Type\)(\(`\?\w\+`\?, \)\(pango_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Fundamental_Type\)(\(`\?\w\+`\?, \)\(pango_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(gTypeIsA\)(\(`\?\w\+`\?, \)\(pango_Type_\w\+\))/\1(\2\3)/g' final.nim

sed -i 's/\bpango\([A-Z]\w\+GetType()\)/\l\1/g' final.nim

ruby ../glib_fix_T.rb final.nim pango Pango

ruby ../glib_fix_enum_prefix.rb final.nim

sed -i 's/\(dummy[0-9]\?\)\*/\1/g' final.nim
sed -i 's/\(reserved[0-9]\?\)\*/\1/g' final.nim

sed -i 's/[(][(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/(\1/g' final.nim
sed -i 's/, [(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/, \1/g' final.nim

ruby ../fix_object_of.rb final.nim

perl -0777 -p -i -e "s~([=:] proc \(.*?\)(?:: (?:ptr )?\w+)?)~\1 {.cdecl.}~sg" final.nim
sed -i 's/\([,=(<>] \{0,1\}\)[(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/\1\2/g' final.nim
sed -i 's/\bgobject\.GObjectObj\b/GObjectObj/g' final.nim
sed -i 's/\bgobject\.GObjectClassObj\b/GObjectClassObj/g' final.nim

i='const 
  STRICT* = true
when not(defined(WIN32_WINNT)): 
  const 
    WIN32_WINNT = 0x00000501
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim

i='template i(string: expr): expr = 
  g_intern_static_string(string)
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim

i='type
  PangoRenderPart* {.size: sizeof(cint), pure.} = enum
    FOREGROUND, BACKGROUND,
    UNDERLINE, STRIKETHROUGH
'
perl -0777 -p -i -e "s~\Q$i\E~~s" final.nim
j='type
  PangoEllipsizeMode* {.size: sizeof(cint), pure.} = enum
    NONE, START, MIDDLE,
    `END`
'
perl -0777 -p -i -e "s~\Q$j\E~$j$i~s" final.nim

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

sed -i 's/ ptr var / var ptr /g' final.nim

sed -i 's/PangoAttributeObj\* = object/PangoAttributeObj*{.inheritable, pure.} = object/g' final.nim
sed -i 's/PangoEngineClassObj\*{\.final\.} = object of GObjectClassObj/PangoEngineClassObj* = object of GObjectClassObj/g' final.nim
sed -i 's/PangoRendererClassObj\*{\.final\.} = object of GObjectClassObj/PangoRendererClassObj* = object of GObjectClassObj/g' final.nim
sed -i 's/PangoFontMapClassObj\*{\.final\.} = object of GObjectClassObj/PangoFontMapClassObj* = object of GObjectClassObj/g' final.nim
sed -i 's/PangoFontClassObj\*{\.final\.} = object of GObjectClassObj/PangoFontClassObj* = object of GObjectClassObj/g' final.nim
sed -i 's/PangoRendererObj\*{\.final\.} = object of GObjectObj/PangoRendererObj* = object of GObjectObj/g' final.nim
sed -i 's/PangoEngineObj\*{\.final\.} = object of GObjectObj/PangoEngineObj* = object of GObjectObj/g' final.nim
sed -i 's/PangoFontMapObj\*{\.final\.} = object of GObjectObj/PangoFontMapObj* = object of GObjectObj/g' final.nim
sed -i 's/PangoCoreTextFontMapObj\*{\.final\.} = object of PangoFontMapObj/PangoCoreTextFontMapObj* = object of PangoFontMapObj/g' final.nim
sed -i 's/PangoFontObj\*{\.final\.} = object of GObjectObj/PangoFontObj* = object of GObjectObj/g' final.nim
sed -i 's/priv\*: PangoXftRendererPrivate/priv00: PangoXftRendererPrivate/g' final.nim

# some procs with get_ prefix do not return something but need var objects instead of pointers:
# vim search term for candidates:
# proc get[^)]*)[^:}]*{

i='proc getGlyphExtents*(font: Font; glyph: Glyph;
                              inkRect: Rectangle;
                              logicalRect: Rectangle) {.
    importc: "pango_font_get_glyph_extents", libpango.}
'
j='proc getGlyphExtents*(font: Font; glyph: Glyph;
                              inkRect: var RectangleObj;
                              logicalRect: var RectangleObj) {.
    importc: "pango_font_get_glyph_extents", libpango.}
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

sed -i 's/\bPangoXftFontObj\b/PXXXangoXftFontObj/g' final.nim
sed -i 's/\bPangoXftFontPtr\b/PXXXangoXftFontPtr/g' final.nim
sed -i 's/\bPangoXftFont\b/PXXXangoXftFont/g' final.nim
ruby ../mangler.rb final.nim Pango
sed -i 's/\bPXXXangoXftFontObj\b/PangoXftFontObj/g' final.nim
sed -i 's/\bPXXXangoXftFontPtr\b/PangoXftFontPtr/g' final.nim
sed -i 's/\bPXXXangoXftFont\b/PangoXftFont/g' final.nim

sed -i 's/SCALE, FALLBACK,/XXXSCALE, FALLBACK,/' final.nim
ruby ../mangler.rb final.nim PANGO_
sed -i 's/XXXSCALE, FALLBACK,/SCALE, FALLBACK,/' final.nim

sed -i 's/\* = pango\([A-Z]\)/* = \L\1/g' final.nim

ruby ../fix_template.rb final.nim

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

sed -i "s/\bpango_Gravity_/Gravity./g" final.nim

sed -i "s/^\s*#type\s*$//g" final.nim
sed -i "s/\s*$//g" final.nim

# generate procs without get_ and set_ prefix
perl -0777 -p -i -e "s/(\n\s*)(proc set)([A-Z]\w+)(\*\([^}]*\) \{[^}]*})/\$&\1proc \`\l\3=\`\4/sg" final.nim
perl -0777 -p -i -e "s/(\n\s*)(proc get)([A-Z]\w+)(\*\([^}]*\): \w[^}]*})/\$&\1proc \l\3\4/sg" final.nim
sed -i 's/^proc ref\*(/proc `ref`\*(/g' final.nim
sed -i 's/^proc break\*(/proc `break`\*(/g' final.nim
sed -i 's/^proc iterator\*(/proc `iterator`\*(/g' final.nim

i='  Fontset* =  ptr FontsetObj
  FontsetPtr* = ptr FontsetObj
  FontsetObj*{.final.} = object of GObjectObj
'
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim
j='type
  FontsetForeachFunc* = proc (fontset: Fontset; font: Font;
                                userData: Gpointer): Gboolean {.cdecl.}
'
perl -0777 -p -i -e "s/\Q$j\E/type\n$i$j/s" final.nim

# now separare the cairo, win32 and other submodules
i='### "pango/./pangowin32.h"'
j='
{.deadCodeElim: on.}
import pango except fontGetType, fontMapGetType
from glib import Gunichar, Gboolean
from windows import HDC, HFONT, PLOGFONTA, LOGFONTW
{.pragma: libpango, cdecl, dynlib: LIB_PANGO.}
'
perl -0777 -p -i -e "s~\Q$i\E~$i$j~s" final.nim
csplit final.nim "/$i/"
mv xx00 final.nim
cat -s xx01 > pango_win32.nim
sed  -i "s/\(proc win32\)\([A-Z]\)\(\.*\)/proc \l\2\3/g" pango_win32.nim
ruby ../glib_fix_proc.rb pango_win32.nim win32
sed -i 's/\* = win32\([A-Z]\)/* = \L\1/g' pango_win32.nim

i='### "pango/./pangocoretext.h"'
j='
{.deadCodeElim: on.}
import pango except fontGetType, fontMapGetType
from glib import GHashTable, Gpointer, Gconstpointer, Gboolean
from gobject import GType
{.pragma: libpango, cdecl, dynlib: LIB_PANGO.}
type
  CTFontRef = ptr object # dummy objects!
  CTFontDescriptorRef = ptr object
'
perl -0777 -p -i -e "s~\Q$i\E~$i$j~s" final.nim
csplit final.nim "/$i/"
mv xx00 final.nim
cat -s xx01 > pango_coretext.nim

i='### "pango/./pangoft2.h"'
j='
{.deadCodeElim: on.}
import pango except fontGetType, fontMapGetType
from glib import Gpointer, GDestroyNotify
from gobject import GType

when defined(windows): 
  const LIB_PANGO_FT2* = "libpangoft2-1.0-0.dll"
elif defined(macosx):
  const LIB_PANGO_FT2* = "libpangoft2-1.0.dylib"
else: 
  const LIB_PANGO_FT2* = "libpangoft2-1.0.so.0"

{.pragma: libpango, cdecl, dynlib: LIB_PANGO_FT2.}

type
  FT_Face = ptr object # dummy objects!
  FcPattern = object
  FT_Bitmap = object
'
perl -0777 -p -i -e "s~\Q$i\E~$i$j~s" final.nim
csplit final.nim "/$i/"
mv xx00 final.nim
cat -s xx01 > pango_ft2.nim
sed  -i "s/\(proc ft2\)\([A-Z]\)\(\.*\)/proc \l\2\3/g" pango_ft2.nim
ruby ../glib_fix_proc.rb pango_ft2.nim ""
sed -i 's/\* = ft2\([A-Z]\)/* = \L\1/g' pango_ft2.nim

i='### "pango/./pangoxft-render.h"'
j='
{.deadCodeElim: on.}
import pango except fontGetType, fontMapGetType, rendererGetType
from glib import Gboolean, Gpointer, Gunichar, GDestroyNotify
from gobject import GType
from xlib import PDisplay

when defined(windows): 
  const LIB_PANGO_XFT* = "libpangoxft-1.0-0.dll"
elif defined(macosx):
  const LIB_PANGO_XFT* = "libpangoxft-1.0.dylib"
else: 
  const LIB_PANGO_XFT* = "libpangoxft-1.0.so.0"

{.pragma: libpango, cdecl, dynlib: LIB_PANGO_XFT.}

type
  Picture = ptr object # dummy objects!
  FcPattern = object
  FT_Face = ptr object
  XftDraw = object
  XTrapezoid = object
  XftGlyphSpec = object
  XftFont = object
  XftColor = object
'
perl -0777 -p -i -e "s~\Q$i\E~$i$j~s" final.nim
csplit final.nim "/$i/"
mv xx00 final.nim
cat -s  xx01 > pango_xft.nim
sed  -i "s/\(proc xft\)\([A-Z]\)\(\.*\)/proc \l\2\3/g" pango_xft.nim
ruby ../glib_fix_proc.rb pango_xft.nim xft
sed -i 's/\* = xft\([A-Z]\)/* = \L\1/g' pango_xft.nim

i='### "pango/./pangocairo.h"'
j='
{.deadCodeElim: on.}
import pango except fontGetType, fontMapGetType
from cairo import TheCairoContext, Font_type, Font_options, Scaled_Font
from glib import Gboolean, Gpointer, GDestroyNotify
from gobject import GType

when defined(windows): 
  const LIB_PANGO_CAIRO* = "libpangocairo-1.0-0.dll"
elif defined(macosx):
  const LIB_PANGO_CAIRO* = "libpangocairo-1.0.dylib"
else: 
  const LIB_PANGO_CAIRO* = "libpangocairo-1.0.so.0"

{.pragma: libpango, cdecl, dynlib: LIB_PANGO_CAIRO.}
'
perl -0777 -p -i -e "s~\Q$i\E~$i$j~s" final.nim
csplit final.nim "/$i/"
mv xx00 final.nim
sed -i 's/ Context\b/ pango.Context/g' xx01
sed -i 's/ TheCairoContext\b/ Context/g' xx01
cat -s xx01 > pango_cairo.nim
sed  -i "s/\(proc cairo\)\([A-Z]\)\(\.*\)/proc \l\2\3/g" pango_cairo.nim
ruby ../glib_fix_proc.rb pango_cairo.nim ""
sed -i 's/\* = cairo\([A-Z]\)/* = \L\1/g' pango_cairo.nim

i='### "pango/./pango-ot.h"'
j='
{.deadCodeElim: on.}
import pango except fontGetType, fontMapGetType
from glib import Gboolean
from gobject import GType
from pango_fc import FcFont
{.pragma: libpango, cdecl, dynlib: LIB_PANGO.}
type
  FT_Face = ptr object # dummy objects!
'
perl -0777 -p -i -e "s~\Q$i\E~$i$j~s" final.nim
csplit final.nim "/$i/"
mv xx00 final.nim
cat -s xx01 > pango_ot.nim
sed  -i "s/\(proc ot\)\([A-Z]\)\(\.*\)/proc \l\2\3/g" pango_ot.nim
sed -i 's/\* = ot\([A-Z]\)/* = \L\1/g' pango_ot.nim

i='### "pango/./pangofc-font.h"'
j='
{.deadCodeElim: on.}
import pango except fontGetType, fontMapGetType
from glib import Gpointer, GSList, Gunichar, Gconstpointer, Gboolean, GDestroyNotify
from gobject import GType, GObjectObj, GObjectClassObj
{.pragma: libpango, cdecl, dynlib: LIB_PANGO.}
type
  FT_Face = ptr object # dummy objects!
  FcPattern = object
  FcConfig = object
  FcCharSet = object
'
perl -0777 -p -i -e "s~\Q$i\E~$i$j~s" final.nim
csplit final.nim "/$i/"
mv xx00 final.nim
cat -s xx01 > pango_fc.nim
sed  -i "s/\(proc fc\)\([A-Z]\)\(\.*\)/proc \l\2\3/g" pango_fc.nim
sed -i 's/\* = fc\([A-Z]\)/* = \L\1/g' pango_fc.nim

# do we like the file markers?
for i in "pango*.nim final.nim"; do
  sed -i '/### "pango\/\.\/pango/d' $i
done

sed  -i "s/pango_reserved/&0/g" final.nim

cat -s final.nim > pango.nim

rm -rf pango
rm -rf Carbon
rm cairo-quartz.h windows.h list.txt final.h final.nim xx01

exit

