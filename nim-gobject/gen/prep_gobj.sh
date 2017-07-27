#!/bin/bash
# S. Salewski, 17-JUL-2016
# generate gobject bindings for Nim
#
glib_dir="/home/stefan/Downloads/glib-2.53.3"
final="final.h" # the input file for c2nim
list="list.txt"
wdir="tmp_gobj"

targets=''
all_t=". ${targets}"

rm -rf $wdir # start from scratch
mkdir $wdir
cd $wdir
cp -r $glib_dir/gobject .
cd gobject

echo 'we may miss these headers -- please check:'
for i in $all_t ; do
  grep -c DECL ${i}/*.h | grep h:0
done

# we insert in each header a marker with the filename
# may fail if G_BEGIN_DECLS macro is missing in a header
for j in $all_t ; do
  for i in ${j}/*.h; do
    sed -i "/^G_BEGIN_DECLS/a${i}_ssalewski;" $i
  done
done

# caution: main file glib-object is in directory glib
cd ..
cat $glib_dir/glib/glib-object.h > all.h

# cpp run with all headers to determine order
echo "cat \\" > $list

cpp -I. `pkg-config --cflags gtk+-3.0` all.h $final

# extract file names and push names to list
grep ssalewski $final | sed 's/_ssalewski;/ \\/' >> $list

i=`sort $list | uniq -d | wc -l`
if [ $i != 0 ]; then echo 'list contains duplicates!'; exit; fi;

# now we work again with original headers
rm -rf gobject
cp -r $glib_dir/gobject . 

# insert for each header file its name as first line
for j in $all_t ; do
  for i in gobject/${j}/*.h; do
    sed -i "1i/* file: $i */" $i
  done
done
cd gobject
  bash ../$list > ../$final
cd ..

# delete strange macros (define as empty)
# we restrict use of wildcards to limit risc of damage something!
for i in 30 34 36 38 40 42 44 46 48 50 52 54 ; do
  sed -i "1i#def GLIB_AVAILABLE_IN_2_$i" $final
done

sed -i "1i#def GLIB_DEPRECATED_IN_2_32_FOR(x)" $final
sed -i "1i#def GLIB_DEPRECATED_IN_2_54_FOR(x)" $final
sed -i "1i#def GLIB_DEPRECATED_IN_2_36" $final
sed -i "1i#def GLIB_DEPRECATED" $final
sed -i "1i#def G_BEGIN_DECLS" $final
sed -i "1i#def G_END_DECLS" $final
sed -i "1i#def GLIB_DEPRECATED_FOR(i)" $final
sed -i "1i#def GLIB_AVAILABLE_IN_ALL" $final
sed -i "1i#def G_GNUC_CONST" $final
sed -i "1i#def G_GNUC_PURE" $final
sed -i "1i#def G_GNUC_NULL_TERMINATED" $final

# complicated macros -- we will care when we really should need them...
# maybe expanding by cpp preprocessor first and then manually converting to Nim?
sed -i '/#define G_DEFINE_TYPE(TN, t_n, T_P)			    G_DEFINE_TYPE_EXTENDED (TN, t_n, T_P, 0, {})/d' $final
sed -i '/#define G_DEFINE_TYPE_WITH_CODE(TN, t_n, T_P, _C_)	    _G_DEFINE_TYPE_EXTENDED_BEGIN (TN, t_n, T_P, 0) {_C_;} _G_DEFINE_TYPE_EXTENDED_END()/d' $final
sed -i '/#define G_DEFINE_ABSTRACT_TYPE(TN, t_n, T_P)		    G_DEFINE_TYPE_EXTENDED (TN, t_n, T_P, G_TYPE_FLAG_ABSTRACT, {})/d' $final
sed -i '/#define G_DEFINE_ABSTRACT_TYPE_WITH_CODE(TN, t_n, T_P, _C_) _G_DEFINE_TYPE_EXTENDED_BEGIN (TN, t_n, T_P, G_TYPE_FLAG_ABSTRACT) {_C_;} _G_DEFINE_TYPE_EXTENDED_END()/d' $final
sed -i '/#define G_DEFINE_TYPE_EXTENDED(TN, t_n, T_P, _f_, _C_)	    _G_DEFINE_TYPE_EXTENDED_BEGIN (TN, t_n, T_P, _f_) {_C_;} _G_DEFINE_TYPE_EXTENDED_END()/d' $final
sed -i '/#define G_DEFINE_INTERFACE(TN, t_n, T_P)		    G_DEFINE_INTERFACE_WITH_CODE(TN, t_n, T_P, ;)/d' $final
sed -i '/#define G_DEFINE_INTERFACE_WITH_CODE(TN, t_n, T_P, _C_)     _G_DEFINE_INTERFACE_EXTENDED_BEGIN(TN, t_n, T_P) {_C_;} _G_DEFINE_INTERFACE_EXTENDED_END()/d' $final

sed -i "s/#if     GLIB_SIZEOF_SIZE_T != GLIB_SIZEOF_LONG || !defined __cplusplus/#if GLIB_SIZEOF_SIZE_T != GLIB_SIZEOF_LONG || !defined(__cplusplus)/g" $final

# delete some strange macros
i='#define G_ADD_PRIVATE(TypeName) { \
  TypeName##_private_offset = \
    g_type_add_instance_private (g_define_type_id, sizeof (TypeName##Private)); \
}
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define G_PRIVATE_OFFSET(TypeName, field) \
  (TypeName##_private_offset + (G_STRUCT_OFFSET (TypeName##Private, field)))
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#if GLIB_VERSION_MAX_ALLOWED >= GLIB_VERSION_2_38
#define _G_DEFINE_TYPE_EXTENDED_CLASS_INIT(TypeName, type_name) \
static void     type_name##_class_intern_init (gpointer klass) \
{ \
  type_name##_parent_class = g_type_class_peek_parent (klass); \
  if (TypeName##_private_offset != 0) \
    g_type_class_adjust_private_offset (klass, &TypeName##_private_offset); \
  type_name##_class_init ((TypeName##Class*) klass); \
}

#else
#define _G_DEFINE_TYPE_EXTENDED_CLASS_INIT(TypeName, type_name) \
static void     type_name##_class_intern_init (gpointer klass) \
{ \
  type_name##_parent_class = g_type_class_peek_parent (klass); \
  type_name##_class_init ((TypeName##Class*) klass); \
}
#endif /* GLIB_VERSION_MAX_ALLOWED >= GLIB_VERSION_2_38 */
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define _G_DEFINE_TYPE_EXTENDED_BEGIN(TypeName, type_name, TYPE_PARENT, flags) \
\
static void     type_name##_init              (TypeName        *self); \
static void     type_name##_class_init        (TypeName##Class *klass); \
static gpointer type_name##_parent_class = NULL; \
static gint     TypeName##_private_offset; \
\
_G_DEFINE_TYPE_EXTENDED_CLASS_INIT(TypeName, type_name) \
\
G_GNUC_UNUSED \
static inline gpointer \
type_name##_get_instance_private (TypeName *self) \
{ \
  return (G_STRUCT_MEMBER_P (self, TypeName##_private_offset)); \
} \
\
GType \
type_name##_get_type (void) \
{ \
  static volatile gsize g_define_type_id__volatile = 0; \
  if (g_once_init_enter (&g_define_type_id__volatile))  \
    { \
      GType g_define_type_id = \
        g_type_register_static_simple (TYPE_PARENT, \
                                       g_intern_static_string (#TypeName), \
                                       sizeof (TypeName##Class), \
                                       (GClassInitFunc) type_name##_class_intern_init, \
                                       sizeof (TypeName), \
                                       (GInstanceInitFunc) type_name##_init, \
                                       (GTypeFlags) flags); \
      { /* custom code follows */
#define _G_DEFINE_TYPE_EXTENDED_END()	\
        /* following custom code */	\
      }					\
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id); \
    }					\
  return g_define_type_id__volatile;	\
} /* closes type_name##_get_type() */
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define _G_DEFINE_INTERFACE_EXTENDED_BEGIN(TypeName, type_name, TYPE_PREREQ) \
\
static void     type_name##_default_init        (TypeName##Interface *klass); \
\
GType \
type_name##_get_type (void) \
{ \
  static volatile gsize g_define_type_id__volatile = 0; \
  if (g_once_init_enter (&g_define_type_id__volatile))  \
    { \
      GType g_define_type_id = \
        g_type_register_static_simple (G_TYPE_INTERFACE, \
                                       g_intern_static_string (#TypeName), \
                                       sizeof (TypeName##Interface), \
                                       (GClassInitFunc)type_name##_default_init, \
                                       0, \
                                       (GInstanceInitFunc)NULL, \
                                       (GTypeFlags) 0); \
      if (TYPE_PREREQ) \
        g_type_interface_add_prerequisite (g_define_type_id, TYPE_PREREQ); \
      { /* custom code follows */
#define _G_DEFINE_INTERFACE_EXTENDED_END()	\
        /* following custom code */		\
      }						\
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id); \
    }						\
  return g_define_type_id__volatile;			\
} /* closes type_name##_get_type() */
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='
#define _G_DEFINE_TYPE_EXTENDED_BEGIN_PRE(TypeName, type_name, TYPE_PARENT) \
\
static void     type_name##_init              (TypeName        *self); \
static void     type_name##_class_init        (TypeName##Class *klass); \
static gpointer type_name##_parent_class = NULL; \
static gint     TypeName##_private_offset; \
\
_G_DEFINE_TYPE_EXTENDED_CLASS_INIT(TypeName, type_name) \
\
G_GNUC_UNUSED \
static inline gpointer \
type_name##_get_instance_private (TypeName *self) \
{ \
  return (G_STRUCT_MEMBER_P (self, TypeName##_private_offset)); \
} \
\
GType \
type_name##_get_type (void) \
{ \
  static volatile gsize g_define_type_id__volatile = 0;
  /* Prelude goes here */

/* Added for _G_DEFINE_TYPE_EXTENDED_WITH_PRELUDE */
#define _G_DEFINE_TYPE_EXTENDED_BEGIN_REGISTER(TypeName, type_name, TYPE_PARENT, flags) \
  if (g_once_init_enter (&g_define_type_id__volatile))  \
    { \
      GType g_define_type_id = \
        g_type_register_static_simple (TYPE_PARENT, \
                                       g_intern_static_string (#TypeName), \
                                       sizeof (TypeName##Class), \
                                       (GClassInitFunc) type_name##_class_intern_init, \
                                       sizeof (TypeName), \
                                       (GInstanceInitFunc) type_name##_init, \
                                       (GTypeFlags) flags); \
      { /* custom code follows */
#define _G_DEFINE_TYPE_EXTENDED_END()	\
        /* following custom code */	\
      }					\
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id); \
    }					\
  return g_define_type_id__volatile;	\
} /* closes type_name##_get_type() */

/* This was defined before we had G_DEFINE_TYPE_WITH_CODE_AND_PRELUDE, it'\''s simplest
 * to keep it.
 */
#define _G_DEFINE_TYPE_EXTENDED_BEGIN(TypeName, type_name, TYPE_PARENT, flags) \
  _G_DEFINE_TYPE_EXTENDED_BEGIN_PRE(TypeName, type_name, TYPE_PARENT) \
  _G_DEFINE_TYPE_EXTENDED_BEGIN_REGISTER(TypeName, type_name, TYPE_PARENT, flags) \
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

sed -i "/G_DEFINE_AUTOPTR_CLEANUP_FUNC(GTypeModule, g_object_unref)/d" $final

sed -i '/#define G_DEFINE_BOXED_TYPE(TypeName, type_name, copy_func, free_func) G_DEFINE_BOXED_TYPE_WITH_CODE (TypeName, type_name, copy_func, free_func, {})/d' $final
sed -i '/#define G_DEFINE_BOXED_TYPE_WITH_CODE(TypeName, type_name, copy_func, free_func, _C_) _G_DEFINE_BOXED_TYPE_BEGIN (TypeName, type_name, copy_func, free_func) {_C_;} _G_DEFINE_TYPE_EXTENDED_END()/d' $final

i='#if !defined (__cplusplus) && (__GNUC__ > 2 || (__GNUC__ == 2 && __GNUC_MINOR__ >= 7)) && !(defined (__APPLE__) && defined (__ppc64__))
#define _G_DEFINE_BOXED_TYPE_BEGIN(TypeName, type_name, copy_func, free_func) \
GType \
type_name##_get_type (void) \
{ \
  static volatile gsize g_define_type_id__volatile = 0; \
  if (g_once_init_enter (&g_define_type_id__volatile))  \
    { \
      GType (* _g_register_boxed) \
        (const gchar *, \
         union \
           { \
             TypeName * (*do_copy_type) (TypeName *); \
             TypeName * (*do_const_copy_type) (const TypeName *); \
             GBoxedCopyFunc do_copy_boxed; \
           } __attribute__((__transparent_union__)), \
         union \
           { \
             void (* do_free_type) (TypeName *); \
             GBoxedFreeFunc do_free_boxed; \
           } __attribute__((__transparent_union__)) \
        ) = g_boxed_type_register_static; \
      GType g_define_type_id = \
        _g_register_boxed (g_intern_static_string (#TypeName), copy_func, free_func); \
      { /* custom code follows */
#else
#define _G_DEFINE_BOXED_TYPE_BEGIN(TypeName, type_name, copy_func, free_func) \
GType \
type_name##_get_type (void) \
{ \
  static volatile gsize g_define_type_id__volatile = 0; \
  if (g_once_init_enter (&g_define_type_id__volatile))  \
    { \
      GType g_define_type_id = \
        g_boxed_type_register_static (g_intern_static_string (#TypeName), \
                                      (GBoxedCopyFunc) copy_func, \
                                      (GBoxedFreeFunc) free_func); \
      { /* custom code follows */
#endif /* __GNUC__ */
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

sed -i '/#define G_DEFINE_POINTER_TYPE(TypeName, type_name) G_DEFINE_POINTER_TYPE_WITH_CODE (TypeName, type_name, {})/d' $final
sed -i '/#define G_DEFINE_POINTER_TYPE_WITH_CODE(TypeName, type_name, _C_) _G_DEFINE_POINTER_TYPE_BEGIN (TypeName, type_name) {_C_;} _G_DEFINE_TYPE_EXTENDED_END()/d' $final

i='#define _G_DEFINE_POINTER_TYPE_BEGIN(TypeName, type_name) \
GType \
type_name##_get_type (void) \
{ \
  static volatile gsize g_define_type_id__volatile = 0; \
  if (g_once_init_enter (&g_define_type_id__volatile))  \
    { \
      GType g_define_type_id = \
        g_pointer_type_register_static (g_intern_static_string (#TypeName)); \
      { /* custom code follows */
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='
#ifdef	__GNUC__
#  define _G_TYPE_CIT(ip, gt)             (G_GNUC_EXTENSION ({ \
  GTypeInstance *__inst = (GTypeInstance*) ip; GType __t = gt; gboolean __r; \
  if (!__inst) \
    __r = FALSE; \
  else if (__inst->g_class && __inst->g_class->g_type == __t) \
    __r = TRUE; \
  else \
    __r = g_type_check_instance_is_a (__inst, __t); \
  __r; \
}))
#  define _G_TYPE_CCT(cp, gt)             (G_GNUC_EXTENSION ({ \
  GTypeClass *__class = (GTypeClass*) cp; GType __t = gt; gboolean __r; \
  if (!__class) \
    __r = FALSE; \
  else if (__class->g_type == __t) \
    __r = TRUE; \
  else \
    __r = g_type_check_class_is_a (__class, __t); \
  __r; \
}))
#  define _G_TYPE_CVH(vl, gt)             (G_GNUC_EXTENSION ({ \
  GValue *__val = (GValue*) vl; GType __t = gt; gboolean __r; \
  if (!__val) \
    __r = FALSE; \
  else if (__val->g_type == __t)		\
    __r = TRUE; \
  else \
    __r = g_type_check_value_holds (__val, __t); \
  __r; \
}))
#else  /* !__GNUC__ */
#  define _G_TYPE_CIT(ip, gt)             (g_type_check_instance_is_a ((GTypeInstance*) ip, gt))
#  define _G_TYPE_CCT(cp, gt)             (g_type_check_class_is_a ((GTypeClass*) cp, gt))
#  define _G_TYPE_CVH(vl, gt)             (g_type_check_value_holds ((GValue*) vl, gt))
#endif /* !__GNUC__ */
'
j='
#  define _G_TYPE_CIT(ip, gt)             (g_type_check_instance_is_a ((GTypeInstance*) ip, gt))
#  define _G_TYPE_CCT(cp, gt)             (g_type_check_class_is_a ((GTypeClass*) cp, gt))
#  define _G_TYPE_CVH(vl, gt)             (g_type_check_value_holds ((GValue*) vl, gt))
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

sed -i '/#define G_VALUE_INIT  { 0, { { 0 } } }/d' $final

i='#ifndef G_DISABLE_DEPRECATED
  G_PARAM_PRIVATE	      = G_PARAM_STATIC_NAME,
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

sed -i "/GLIB_DEPRECATED_FOR('G_TYPE_VARIANT')/d" $final

i='
#define G_OBJECT_WARN_INVALID_PSPEC(object, pname, property_id, pspec) \
G_STMT_START { \
  GObject *_glib__object = (GObject*) (object); \
  GParamSpec *_glib__pspec = (GParamSpec*) (pspec); \
  guint _glib__property_id = (property_id); \
  g_warning ("%s: invalid %s id %u for \"%s\" of type '\''%s'\'' in '\''%s'\''", \
             G_STRLOC, \
             (pname), \
             _glib__property_id, \
             _glib__pspec->name, \
             g_type_name (G_PARAM_SPEC_TYPE (_glib__pspec)), \
             G_OBJECT_TYPE_NAME (_glib__object)); \
} G_STMT_END
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifndef GOBJECT_VAR
#  ifdef G_PLATFORM_WIN32
#    ifdef GOBJECT_STATIC_COMPILATION
#      define GOBJECT_VAR extern
#    else /* !GOBJECT_STATIC_COMPILATION */
#      ifdef GOBJECT_COMPILATION
#        ifdef DLL_EXPORT
#          define GOBJECT_VAR __declspec(dllexport)
#        else /* !DLL_EXPORT */
#          define GOBJECT_VAR extern
#        endif /* !DLL_EXPORT */
#      else /* !GOBJECT_COMPILATION */
#        define GOBJECT_VAR extern __declspec(dllimport)
#      endif /* !GOBJECT_COMPILATION */
#    endif /* !GOBJECT_STATIC_COMPILATION */
#  else /* !G_PLATFORM_WIN32 */
#    define GOBJECT_VAR _GLIB_EXTERN
#  endif /* !G_PLATFORM_WIN32 */
#endif /* GOBJECT_VAR */
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

sed -i "/GOBJECT_VAR GType \*g_param_spec_types;/d" $final
sed -i "/#define G_DEFINE_DYNAMIC_TYPE(TN, t_n, T_P)          G_DEFINE_DYNAMIC_TYPE_EXTENDED (TN, t_n, T_P, 0, {})/d" $final

i='#define G_DEFINE_DYNAMIC_TYPE_EXTENDED(TypeName, type_name, TYPE_PARENT, flags, CODE) \
static void     type_name##_init              (TypeName        *self); \
static void     type_name##_class_init        (TypeName##Class *klass); \
static void     type_name##_class_finalize    (TypeName##Class *klass); \
static gpointer type_name##_parent_class = NULL; \
static GType    type_name##_type_id = 0; \
static gint     TypeName##_private_offset; \
\
_G_DEFINE_TYPE_EXTENDED_CLASS_INIT(TypeName, type_name) \
\
G_GNUC_UNUSED \
static inline gpointer \
type_name##_get_instance_private (TypeName *self) \
{ \
  return (G_STRUCT_MEMBER_P (self, TypeName##_private_offset)); \
} \
\
GType \
type_name##_get_type (void) \
{ \
  return type_name##_type_id; \
} \
static void \
type_name##_register_type (GTypeModule *type_module) \
{ \
  GType g_define_type_id G_GNUC_UNUSED; \
  const GTypeInfo g_define_type_info = { \
    sizeof (TypeName##Class), \
    (GBaseInitFunc) NULL, \
    (GBaseFinalizeFunc) NULL, \
    (GClassInitFunc) type_name##_class_intern_init, \
    (GClassFinalizeFunc) type_name##_class_finalize, \
    NULL,   /* class_data */ \
    sizeof (TypeName), \
    0,      /* n_preallocs */ \
    (GInstanceInitFunc) type_name##_init, \
    NULL    /* value_table */ \
  }; \
  type_name##_type_id = g_type_module_register_type (type_module, \
						     TYPE_PARENT, \
						     #TypeName, \
						     &g_define_type_info, \
						     (GTypeFlags) flags); \
  g_define_type_id = type_name##_type_id; \
  { CODE ; } \
}
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define G_DECLARE_FINAL_TYPE(ModuleObjName, module_obj_name, MODULE, OBJ_NAME, ParentName) \
  GType module_obj_name##_get_type (void);                                                               \
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS                                                                       \
  typedef struct _##ModuleObjName ModuleObjName;                                                         \
  typedef struct { ParentName##Class parent_class; } ModuleObjName##Class;                               \
                                                                                                         \
  _GLIB_DEFINE_AUTOPTR_CHAINUP (ModuleObjName, ParentName)                                               \
                                                                                                         \
  static inline ModuleObjName * MODULE##_##OBJ_NAME (gpointer ptr) {                                     \
    return G_TYPE_CHECK_INSTANCE_CAST (ptr, module_obj_name##_get_type (), ModuleObjName); }             \
  static inline gboolean MODULE##_IS_##OBJ_NAME (gpointer ptr) {                                         \
    return G_TYPE_CHECK_INSTANCE_TYPE (ptr, module_obj_name##_get_type ()); }                            \
  G_GNUC_END_IGNORE_DEPRECATIONS
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define G_DECLARE_DERIVABLE_TYPE(ModuleObjName, module_obj_name, MODULE, OBJ_NAME, ParentName) \
  GType module_obj_name##_get_type (void);                                                               \
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS                                                                       \
  typedef struct _##ModuleObjName ModuleObjName;                                                         \
  typedef struct _##ModuleObjName##Class ModuleObjName##Class;                                           \
  struct _##ModuleObjName { ParentName parent_instance; };                                               \
                                                                                                         \
  _GLIB_DEFINE_AUTOPTR_CHAINUP (ModuleObjName, ParentName)                                               \
                                                                                                         \
  static inline ModuleObjName * MODULE##_##OBJ_NAME (gpointer ptr) {                                     \
    return G_TYPE_CHECK_INSTANCE_CAST (ptr, module_obj_name##_get_type (), ModuleObjName); }             \
  static inline ModuleObjName##Class * MODULE##_##OBJ_NAME##_CLASS (gpointer ptr) {                      \
    return G_TYPE_CHECK_CLASS_CAST (ptr, module_obj_name##_get_type (), ModuleObjName##Class); }         \
  static inline gboolean MODULE##_IS_##OBJ_NAME (gpointer ptr) {                                         \
    return G_TYPE_CHECK_INSTANCE_TYPE (ptr, module_obj_name##_get_type ()); }                            \
  static inline gboolean MODULE##_IS_##OBJ_NAME##_CLASS (gpointer ptr) {                                 \
    return G_TYPE_CHECK_CLASS_TYPE (ptr, module_obj_name##_get_type ()); }                               \
  static inline ModuleObjName##Class * MODULE##_##OBJ_NAME##_GET_CLASS (gpointer ptr) {                  \
    return G_TYPE_INSTANCE_GET_CLASS (ptr, module_obj_name##_get_type (), ModuleObjName##Class); }       \
  G_GNUC_END_IGNORE_DEPRECATIONS
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define G_DECLARE_INTERFACE(ModuleObjName, module_obj_name, MODULE, OBJ_NAME, PrerequisiteName) \
  GType module_obj_name##_get_type (void);                                                                 \
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS                                                                         \
  typedef struct _##ModuleObjName ModuleObjName;                                                           \
  typedef struct _##ModuleObjName##Interface ModuleObjName##Interface;                                     \
                                                                                                           \
  _GLIB_DEFINE_AUTOPTR_CHAINUP (ModuleObjName, PrerequisiteName)                                           \
                                                                                                           \
  static inline ModuleObjName * MODULE##_##OBJ_NAME (gpointer ptr) {                                       \
    return G_TYPE_CHECK_INSTANCE_CAST (ptr, module_obj_name##_get_type (), ModuleObjName); }               \
  static inline gboolean MODULE##_IS_##OBJ_NAME (gpointer ptr) {                                           \
    return G_TYPE_CHECK_INSTANCE_TYPE (ptr, module_obj_name##_get_type ()); }                              \
  static inline ModuleObjName##Interface * MODULE##_##OBJ_NAME##_GET_IFACE (gpointer ptr) {                \
    return G_TYPE_INSTANCE_GET_INTERFACE (ptr, module_obj_name##_get_type (), ModuleObjName##Interface); } \
  G_GNUC_END_IGNORE_DEPRECATIONS
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define G_ADD_PRIVATE_DYNAMIC(TypeName)         { \
  TypeName##_private_offset = sizeof (TypeName##Private); \
}
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define G_OBJECT_WARN_INVALID_PSPEC(object, pname, property_id, pspec) \
G_STMT_START { \
  GObject *_glib__object = (GObject*) (object); \
  GParamSpec *_glib__pspec = (GParamSpec*) (pspec); \
  guint _glib__property_id = (property_id); \
  g_warning ("%s:%d: invalid %s id %u for \"%s\" of type '\''%s'\'' in '\''%s'\''", \
             __FILE__, __LINE__, \
             (pname), \
             _glib__property_id, \
             _glib__pspec->name, \
             g_type_name (G_PARAM_SPEC_TYPE (_glib__pspec)), \
             G_OBJECT_TYPE_NAME (_glib__object)); \
} G_STMT_END
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='static inline gboolean
(g_set_object) (GObject **object_ptr,
                GObject  *new_object)
{
  GObject *old_object = *object_ptr;

  /* rely on g_object_[un]ref() to check the pointers are actually GObjects;
   * elide a (object_ptr != NULL) check because most of the time we will be
   * operating on struct members with a constant offset, so a NULL check would
   * not catch bugs
   */

  if (old_object == new_object)
    return FALSE;

  if (new_object != NULL)
    g_object_ref (new_object);

  *object_ptr = new_object;

  if (old_object != NULL)
    g_object_unref (old_object);

  return TRUE;
}
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

# insert missing {}
sed -i 's/typedef union  _GTypeCValue             GTypeCValue;/typedef union _GTypeCValue {} GTypeCValue;/g' $final
sed -i 's/typedef struct _GTypePlugin             GTypePlugin;/typedef struct _GTypePlugin {} GTypePlugin;/g' $final
sed -i 's/typedef struct _GParamSpecPool  GParamSpecPool;/typedef struct _GParamSpecPool {} GParamSpecPool;/g' $final
sed -i 's/typedef struct _GBinding        GBinding;/typedef struct _GBinding {} GBinding;/g' $final

sed -i "/extern GTypeDebugFlags			_g_type_debug_flags;/d" $final

ruby ../fix_.rb $final

i='
#ifdef C2NIM
#  dynlib lib
#endif
'
perl -0777 -p -i -e "s/^/$i/" $final

sed -i 's/\bgchar\b/char/g' $final

#ruby ../func_alias_reorder.rb final.h G

#sed -i 's/#define G_TYPE_\w\+/&()/g' $final
sed -i 's/\(#define G_TYPE_\w\+\)\(\s\+(\?\w\+_get_g\?type\s*()\s*)\?\)/\1()\2/g' $final
sed -i 's/#define	G_TYPE_GTYPE			 (g_gtype_get_type())/#define	G_TYPE_GTYPE()			 (g_gtype_get_type())/g' $final
c2nim --nep1 --skipcomments --skipinclude $final
sed -i 's/ {\.bycopy\.}//g' final.nim

for i in g_Type_Fundamental_Shift glib_Sizeof_Size_T glib_Sizeof_Long g_Type_Flag_Reserved_Id_Bit ; do
  sed -i "s/\b${i}\b/\U&/g" final.nim
done

for i in  cplusplus G_DISABLE_CAST_CHECKS ; do
  sed -i "s/ defined\((${i})\)/ \U\1/g" final.nim
done

k='template g_Type_Make_Fundamental*(x: untyped): untyped =
  ((gType)((x) shl G_TYPE_FUNDAMENTAL_SHIFT))
'
perl -0777 -p -i -e "s~\Q$k\E~~sg" final.nim
i='const
  G_TYPE_FUNDAMENTAL_SHIFT* = (2)
'
perl -0777 -p -i -e "s~\Q$i\E~~sg" final.nim
j='const
  G_TYPE_FUNDAMENTAL_MAX* = (255 shl G_TYPE_FUNDAMENTAL_SHIFT)
'
perl -0777 -p -i -e "s~\Q$j\E~$i$j$k~s" final.nim

sed -i "s/((gType)((x) shl G_TYPE_FUNDAMENTAL_SHIFT))/((GType)((x) shl G_TYPE_FUNDAMENTAL_SHIFT))/g" final.nim
sed -i "s/G_TYPE_FLAG_RESERVED_ID_BIT\* = ((gType)(1 shl 0))/G_TYPE_FLAG_RESERVED_ID_BIT* = ((GType)(1 shl 0))/g" final.nim
sed -i "s/((cast[ptr GValue]((value))).gType)/((cast[ptr GValue]((value))).GType)/g" final.nim

sed -i "s/when glib_Version_Max_Allowed >= glib_Version_242:/when true: # &/g" final.nim

i='when GLIB_SIZEOF_SIZE_T != GLIB_SIZEOF_LONG or not (CPLUSPLUS):
  type
    GType* = Gsize
else:
  type
    GType* = Gulong
'
perl -0777 -p -i -e "s~\Q$i\E~~sg" final.nim
j='template g_Type_Make_Fundamental*(x: untyped): untyped =
  ((GType)((x) shl G_TYPE_FUNDAMENTAL_SHIFT))
'
perl -0777 -p -i -e "s~\Q$j\E~$i$j~s" final.nim

k='type
  INNER_C_UNION_81819396* = object {.union.}
    vInt*: Gint
    vUint*: Guint
    vLong*: Glong
    vUlong*: Gulong
    vInt64*: Gint64
    vUint64*: Guint64
    vFloat*: Gfloat
    vDouble*: Gdouble
    vPointer*: Gpointer

  GValue* = object
    gType*: GType
    data*: array[2, INNER_C_UNION_81819396]
'
perl -0777 -p -i -e "s~\Q$k\E~~sg" final.nim
i='type
  GTypeInfo* = object
    classSize*: Guint16
    baseInit*: GBaseInitFunc
    baseFinalize*: GBaseFinalizeFunc
    classInit*: GClassInitFunc
    classFinalize*: GClassFinalizeFunc
    classData*: Gconstpointer
    instanceSize*: Guint16
    nPreallocs*: Guint16
    instanceInit*: GInstanceInitFunc
    valueTable*: ptr GTypeValueTable



type
  GTypeFundamentalInfo* = object
    typeFlags*: GTypeFundamentalFlags



type
  GInterfaceInfo* = object
    interfaceInit*: GInterfaceInitFunc
    interfaceFinalize*: GInterfaceFinalizeFunc
    interfaceData*: Gpointer



type
  GTypeValueTable* = object
'
j='type
  GTypeInfo* = object
    classSize*: Guint16
    baseInit*: GBaseInitFunc
    baseFinalize*: GBaseFinalizeFunc
    classInit*: GClassInitFunc
    classFinalize*: GClassFinalizeFunc
    classData*: Gconstpointer
    instanceSize*: Guint16
    nPreallocs*: Guint16
    instanceInit*: GInstanceInitFunc
    valueTable*: ptr GTypeValueTable

#type
  GTypeFundamentalInfo* = object
    typeFlags*: GTypeFundamentalFlags

#type
  GInterfaceInfo* = object
    interfaceInit*: GInterfaceInitFunc
    interfaceFinalize*: GInterfaceFinalizeFunc
    interfaceData*: Gpointer

#type
  GTypeValueTable* = object
'
perl -0777 -p -i -e "s~\Q$i\E~$k$j~s" final.nim

i='template g_Define_Type_With_Private*(tn, tN, t_P: untyped): untyped =
  g_Define_Type_Extended(tn, tN, t_P, 0, g_Add_Private(tn))


template g_Define_Abstract_Type_With_Private*(tn, tN, t_P: untyped): untyped =
  g_Define_Type_Extended(tn, tN, t_P, g_Type_Flag_Abstract, g_Add_Private(tn))
'
j='template g_Define_Type_With_Private*(tn, tNU, t_P: untyped): untyped =
  g_Define_Type_Extended(tn, tNU, t_P, 0, g_Add_Private(tn))


template g_Define_Abstract_Type_With_Private*(tn, tNU, t_P: untyped): untyped =
  g_Define_Type_Extended(tn, tNU, t_P, g_Type_Flag_Abstract, g_Add_Private(tn))
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

i='type
  GVaClosureMarshal* = proc (closure: ptr GClosure; returnValue: ptr GValue;
                          instance: Gpointer; args: VaList; marshalData: Gpointer;
                          nParams: cint; paramTypes: ptr GType)
'
perl -0777 -p -i -e "s~\Q$i\E~#[$i]#~s" final.nim

i='type
  GSignalCVaMarshaller* = GVaClosureMarshal
'
perl -0777 -p -i -e "s~\Q$i\E~#[$i]#~s" final.nim

i='proc gSignalSetVaMarshaller*(signalId: Guint; instanceType: GType;
                            vaMarshaller: GSignalCVaMarshaller) {.
    importc: "g_signal_set_va_marshaller", dynlib: lib.}
'
perl -0777 -p -i -e "s~\Q$i\E~#[$i]#\n~sg" final.nim

i='type
  GSignalEmissionHook* = proc (ihint: ptr GSignalInvocationHint; nParamValues: Guint;
                            paramValues: ptr GValue; data: Gpointer): Gboolean


type
  GSignalAccumulator* = proc (ihint: ptr GSignalInvocationHint;
                           returnAccu: ptr GValue; handlerReturn: ptr GValue;
                           data: Gpointer): Gboolean
'
perl -0777 -p -i -e "s~\Q$i\E~~sg" final.nim
j='type
  GSignalInvocationHint* = object
    signalId*: Guint
    detail*: GQuark
    runType*: GSignalFlags



type
  GSignalQuery* = object
    signalId*: Guint
    signalName*: cstring
    itype*: GType
    signalFlags*: GSignalFlags
    returnType*: GType
    nParams*: Guint
    paramTypes*: ptr GType
'
perl -0777 -p -i -e "s~\Q$j\E~$i$j~sg" final.nim

i='type
  GSignalEmissionHook* = proc (ihint: ptr GSignalInvocationHint; nParamValues: Guint;
                            paramValues: ptr GValue; data: Gpointer): Gboolean


type
  GSignalAccumulator* = proc (ihint: ptr GSignalInvocationHint;
                           returnAccu: ptr GValue; handlerReturn: ptr GValue;
                           data: Gpointer): Gboolean
type
  GSignalInvocationHint* = object
    signalId*: Guint
    detail*: GQuark
    runType*: GSignalFlags
'
j='type
  GSignalEmissionHook* = proc (ihint: ptr GSignalInvocationHint; nParamValues: Guint;
                            paramValues: ptr GValue; data: Gpointer): Gboolean


#type
  GSignalAccumulator* = proc (ihint: ptr GSignalInvocationHint;
                           returnAccu: ptr GValue; handlerReturn: ptr GValue;
                           data: Gpointer): Gboolean
#type
  GSignalInvocationHint* = object
    signalId*: Guint
    detail*: GQuark
    runType*: GSignalFlags
'
perl -0777 -p -i -e "s~\Q$i\E~$j~sg" final.nim

i='when defined(__GI_SCANNER__):
  type
    GType* = Gsize
'
perl -0777 -p -i -e "s~\Q$i\E~~sg" final.nim

i='type
  GInitiallyUnowned* = gObject
  GInitiallyUnownedClass* = gObjectClass
'
perl -0777 -p -i -e "s~\Q$i\E~~sg" final.nim
i='type
  GInitiallyUnowned* = GObject
  GInitiallyUnownedClass* = GObjectClass
'
j='type
  GObject* = object
    gTypeInstance*: GTypeInstance
    refCount*: Guint
    qdata*: ptr GData



type
  GObjectClass* = object
    gTypeClass*: GTypeClass
    constructProperties*: ptr GSList
    constructor*: proc (`type`: GType; nConstructProperties: Guint;
                      constructProperties: ptr GObjectConstructParam): ptr GObject
    setProperty*: proc (`object`: ptr GObject; propertyId: Guint; value: ptr GValue;
                      pspec: ptr GParamSpec)
    getProperty*: proc (`object`: ptr GObject; propertyId: Guint; value: ptr GValue;
                      pspec: ptr GParamSpec)
    dispose*: proc (`object`: ptr GObject)
    finalize*: proc (`object`: ptr GObject)
    dispatchPropertiesChanged*: proc (`object`: ptr GObject; nPspecs: Guint;
                                    pspecs: ptr ptr GParamSpec)
    notify*: proc (`object`: ptr GObject; pspec: ptr GParamSpec)
    constructed*: proc (`object`: ptr GObject)
    flags*: Gsize
    pdummy*: array[6, Gpointer]
'
k='type
  GObjectConstructParam* = object
    pspec*: ptr GParamSpec
    value*: ptr GValue
'
perl -0777 -p -i -e "s~\Q$k\E~~sg" final.nim
l='type
  GObjectGetPropertyFunc* = proc (`object`: ptr GObject; propertyId: Guint;
                               value: ptr GValue; pspec: ptr GParamSpec)


type
  GObjectSetPropertyFunc* = proc (`object`: ptr GObject; propertyId: Guint;
                               value: ptr GValue; pspec: ptr GParamSpec)


type
  GObjectFinalizeFunc* = proc (`object`: ptr GObject)


type
  GWeakNotify* = proc (data: Gpointer; whereTheObjectWas: ptr GObject)

'
perl -0777 -p -i -e "s~\Q$l\E~~sg" final.nim

perl -0777 -p -i -e "s~\Q$j\E~$k$j$i$l~sg" final.nim

i='type
  GEnumClass* = object
    gTypeClass*: GTypeClass
    minimum*: Gint
    maximum*: Gint
    nValues*: Guint
    values*: ptr GEnumValue



type
  GFlagsClass* = object
    gTypeClass*: GTypeClass
    mask*: Guint
    nValues*: Guint
    values*: ptr GFlagsValue



type
  GEnumValue* = object
    value*: Gint
    valueName*: cstring
    valueNick*: cstring



type
  GFlagsValue* = object
    value*: Guint
    valueName*: cstring
    valueNick*: cstring

'
j='type
  GEnumClass* = object
    gTypeClass*: GTypeClass
    minimum*: Gint
    maximum*: Gint
    nValues*: Guint
    values*: ptr GEnumValue

#type
  GFlagsClass* = object
    gTypeClass*: GTypeClass
    mask*: Guint
    nValues*: Guint
    values*: ptr GFlagsValue

#type
  GEnumValue* = object
    value*: Gint
    valueName*: cstring
    valueNick*: cstring

#type
  GFlagsValue* = object
    value*: Guint
    valueName*: cstring
    valueNick*: cstring
'
perl -0777 -p -i -e "s~\Q$i\E~$j~sg" final.nim

i='const
  G_TYPE_PARAM_CHAR* = (gParamSpecTypes[0])


template g_Is_Param_Spec_Char*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Char))


template g_Param_Spec_Char*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Char, gParamSpecChar))


const
  G_TYPE_PARAM_UCHAR* = (gParamSpecTypes[1])


template g_Is_Param_Spec_Uchar*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Uchar))


template g_Param_Spec_Uchar*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Uchar, gParamSpecUChar))


const
  G_TYPE_PARAM_BOOLEAN* = (gParamSpecTypes[2])


template g_Is_Param_Spec_Boolean*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Boolean))


template g_Param_Spec_Boolean*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Boolean, gParamSpecBoolean))


const
  G_TYPE_PARAM_INT* = (gParamSpecTypes[3])


template g_Is_Param_Spec_Int*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Int))


template g_Param_Spec_Int*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Int, gParamSpecInt))


const
  G_TYPE_PARAM_UINT* = (gParamSpecTypes[4])


template g_Is_Param_Spec_Uint*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Uint))


template g_Param_Spec_Uint*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Uint, gParamSpecUInt))


const
  G_TYPE_PARAM_LONG* = (gParamSpecTypes[5])


template g_Is_Param_Spec_Long*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Long))


template g_Param_Spec_Long*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Long, gParamSpecLong))


const
  G_TYPE_PARAM_ULONG* = (gParamSpecTypes[6])


template g_Is_Param_Spec_Ulong*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Ulong))


template g_Param_Spec_Ulong*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Ulong, gParamSpecULong))


const
  G_TYPE_PARAM_INT64* = (gParamSpecTypes[7])


template g_Is_Param_Spec_Int64*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Int64))


template g_Param_Spec_Int64*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Int64, gParamSpecInt64))
'
perl -0777 -p -i -e "s~\Q$i\E~~sg" final.nim
i='const
  G_TYPE_PARAM_UINT64* = (gParamSpecTypes[8])


template g_Is_Param_Spec_Uint64*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Uint64))


template g_Param_Spec_Uint64*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Uint64, gParamSpecUInt64))


const
  G_TYPE_PARAM_UNICHAR* = (gParamSpecTypes[9])


template g_Param_Spec_Unichar*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Unichar, gParamSpecUnichar))


template g_Is_Param_Spec_Unichar*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Unichar))


const
  G_TYPE_PARAM_ENUM* = (gParamSpecTypes[10])


template g_Is_Param_Spec_Enum*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Enum))


template g_Param_Spec_Enum*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Enum, gParamSpecEnum))


const
  G_TYPE_PARAM_FLAGS* = (gParamSpecTypes[11])


template g_Is_Param_Spec_Flags*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Flags))


template g_Param_Spec_Flags*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Flags, gParamSpecFlags))


const
  G_TYPE_PARAM_FLOAT* = (gParamSpecTypes[12])


template g_Is_Param_Spec_Float*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Float))


template g_Param_Spec_Float*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Float, gParamSpecFloat))


const
  G_TYPE_PARAM_DOUBLE* = (gParamSpecTypes[13])


template g_Is_Param_Spec_Double*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Double))


template g_Param_Spec_Double*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Double, gParamSpecDouble))


const
  G_TYPE_PARAM_STRING* = (gParamSpecTypes[14])


template g_Is_Param_Spec_String*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_String))


template g_Param_Spec_String*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_String, gParamSpecString))


const
  G_TYPE_PARAM_PARAM* = (gParamSpecTypes[15])


template g_Is_Param_Spec_Param*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Param))


template g_Param_Spec_Param*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Param, gParamSpecParam))


const
  G_TYPE_PARAM_BOXED* = (gParamSpecTypes[16])


template g_Is_Param_Spec_Boxed*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Boxed))


template g_Param_Spec_Boxed*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Boxed, gParamSpecBoxed))
'
perl -0777 -p -i -e "s~\Q$i\E~~sg" final.nim
i='const
  G_TYPE_PARAM_POINTER* = (gParamSpecTypes[17])


template g_Is_Param_Spec_Pointer*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Pointer))


template g_Param_Spec_Pointer*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Pointer, gParamSpecPointer))


const
  G_TYPE_PARAM_VALUE_ARRAY* = (gParamSpecTypes[18])


template g_Is_Param_Spec_Value_Array*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Value_Array))


template g_Param_Spec_Value_Array*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Value_Array,
                              gParamSpecValueArray))


const
  G_TYPE_PARAM_OBJECT* = (gParamSpecTypes[19])


template g_Is_Param_Spec_Object*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Object))


template g_Param_Spec_Object*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Object, gParamSpecObject))


const
  G_TYPE_PARAM_OVERRIDE* = (gParamSpecTypes[20])


template g_Is_Param_Spec_Override*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Override))


template g_Param_Spec_Override*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Override, gParamSpecOverride))


const
  G_TYPE_PARAM_GTYPE* = (gParamSpecTypes[21])


template g_Is_Param_Spec_Gtype*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Gtype))


template g_Param_Spec_Gtype*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Gtype, gParamSpecGType))


const
  G_TYPE_PARAM_VARIANT* = (gParamSpecTypes[22])


template g_Is_Param_Spec_Variant*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Type((pspec), g_Type_Param_Variant))


template g_Param_Spec_Variant*(pspec: untyped): untyped =
  (g_Type_Check_Instance_Cast((pspec), g_Type_Param_Variant, gParamSpecVariant))

'
perl -0777 -p -i -e "s~\Q$i\E~~sg" final.nim

# we use our own defined pragma
sed -i "s/\bdynlib: lib\b/libgobj/g" final.nim

i='when not defined(glib_Gobject_H_Inside) and not defined(gobject_Compilation):
when not defined(__GI_SCANNER__):

'
perl -0777 -p -i -e "s~\Q$i\E~~sg" final.nim

i='when not defined(glib_Gobject_H_Inside) and not defined(gobject_Compilation) and
    not defined(glib_Compilation):
'
perl -0777 -p -i -e "s~\Q$i\E~~sg" final.nim

i='when not defined(glib_Gobject_H_Inside) and not defined(gobject_Compilation):
'
perl -0777 -p -i -e "s~\Q$i\E~~sg" final.nim

i=' {.deadCodeElim: on.}
'
j='{.deadCodeElim: on.}

# Note: Not all gobject C macros are available in Nim yet.
# Some are converted by c2nim to templates, some manually to procs.
# Most of these should be not necessary for Nim programmers.
# We may have to add more and to test and fix some, or remove unnecessary ones completely...

when defined(windows): 
  const LIB_GOBJ* = "libgobject-2.0-0.dll"
elif defined(macosx):
  const LIB_GOBJ* = "libgobject-2.0.dylib"
else: 
  const LIB_GOBJ* = "libgobject-2.0.so(|.0)"

{.pragma: libgobj, cdecl, dynlib: LIB_GOBJ.}
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

i='type
  GParamFlags* {.size: sizeof(cint).} = enum
    G_PARAM_READABLE = 1 shl 0, G_PARAM_WRITABLE = 1 shl 1,
    G_PARAM_READWRITE = (g_Param_Readable or g_Param_Writable),
    G_PARAM_CONSTRUCT = 1 shl 2, G_PARAM_CONSTRUCT_ONLY = 1 shl 3,
    G_PARAM_LAX_VALIDATION = 1 shl 4, G_PARAM_STATIC_NAME = 1 shl 5,
    G_PARAM_STATIC_NICK = 1 shl 6, G_PARAM_STATIC_BLURB = 1 shl 7,
    G_PARAM_EXPLICIT_NOTIFY = 1 shl 30, G_PARAM_DEPRECATED = (gint)(1 shl 31)



const
  G_PARAM_STATIC_STRINGS* = (
    g_Param_Static_Name or g_Param_Static_Nick or g_Param_Static_Blurb)
'

j='type 
  GParamFlags* {.size: sizeof(cint).} = enum
    G_PARAM_READABLE = 1 shl 0, G_PARAM_WRITABLE = 1 shl 1, 
    G_PARAM_CONSTRUCT = 1 shl 2, G_PARAM_CONSTRUCT_ONLY = 1 shl 3, 
    G_PARAM_LAX_VALIDATION = 1 shl 4, G_PARAM_STATIC_NAME = 1 shl 5, 
    G_PARAM_STATIC_NICK = 1 shl 6, G_PARAM_STATIC_BLURB = 1 shl 7, 
    G_PARAM_EXPLICIT_NOTIFY = 1 shl 30, G_PARAM_DEPRECATED = 1 shl 31
const
  G_PARAM_STATIC_STRINGS* = GParamFlags(
    GParamFlags.STATIC_NAME.ord or GParamFlags.STATIC_NICK.ord or GParamFlags.STATIC_BLURB.ord)
  G_PARAM_READWRITE = GParamFlags(GParamFlags.READABLE.ord or GParamFlags.WRITABLE.ord) 
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

i='proc gCclosureMarshalBOOLEAN_FLAGS*(closure: ptr GClosure; returnValue: ptr GValue;
                                   nParamValues: Guint; paramValues: ptr GValue;
                                   invocationHint: Gpointer; marshalData: Gpointer) {.
    importc: "g_cclosure_marshal_BOOLEAN__FLAGS", libgobj.}
proc gCclosureMarshalBOOLEAN_FLAGSv*(closure: ptr GClosure; returnValue: ptr GValue;
                                    instance: Gpointer; args: VaList;
                                    marshalData: Gpointer; nParams: cint;
                                    paramTypes: ptr GType) {.
    importc: "g_cclosure_marshal_BOOLEAN__FLAGSv", libgobj.}
const
  gCclosureMarshalBOOL_FLAGS* = gCclosureMarshalBOOLEAN_FLAGS
'
j='proc gCclosureMarshalBOOLEAN_FLAGS*(closure: ptr GClosure; returnValue: ptr GValue;
                                   nParamValues: Guint; paramValues: ptr GValue;
                                   invocationHint: Gpointer; marshalData: Gpointer) {.
    importc: "g_cclosure_marshal_BOOLEAN__FLAGS", libgobj.}
proc gCclosureMarshalBOOLEAN_FLAGSv*(closure: ptr GClosure; returnValue: ptr GValue;
                                    instance: Gpointer; args: VaList;
                                    marshalData: Gpointer; nParams: cint;
                                    paramTypes: ptr GType) {.
    importc: "g_cclosure_marshal_BOOLEAN__FLAGSv", libgobj.}
const
  gCclosureMarshalBOOL_FLAGS* = cclosureMarshalBOOLEAN_FLAGS
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim

sed -i 's/gCclosureMarshalBOOL_BOXED_BOXED\* = gCclosureMarshalBOOLEAN_BOXED_BOXED/gCclosureMarshalBOOL_BOXED_BOXED* = cclosureMarshalBOOLEAN_BOXED_BOXED/g' final.nim

#perl -0777 -p -i -e "s/(\n\s*)(proc )(\w+)(\*\([^}]*VaList[^}]*})/\n#[$&\n]#/sg" final.nim
perl -0777 -p -i -e "s/(\n\s*)(proc )(\w+)(\*\([^}]*VaList[^}]*})//sg" final.nim

echo -e "\n" >>  final.nim

# fix c2nim --nep1 mess. We need this before glib_fix_T.rb call!
sed -i 's/[(][(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/(\1/g' final.nim
sed -i 's/, [(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/, \1/g' final.nim
perl -0777 -p -i -e 's/(  \(.*,)\n/\1/g' final.nim
sed -i 's/\(, \) \+/\1/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Cast\)(\(`\?\w\+`\?, \)\(g_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Instance_Get_Interface\)(\(`\?\w\+`\?, \)\(g_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Check_Class_Cast\)(\(`\?\w\+`\?, \)\(g_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Instance_Get_Class\)(\(`\?\w\+`\?, \)\(g_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Type\)(\(`\?\w\+`\?, \)\(g_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Class_Type\)(\(`\?\w\+`\?, \)\(g_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Value_Type\)(\(`\?\w\+`\?, \)\(g_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Fundamental_Type\)(\(`\?\w\+`\?, \)\(g_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(gTypeIsA\)(\(`\?\w\+`\?, \)\(g_Type_\w\+\))/\1(\2\3)/g' final.nim

sed -i 's/\bg\([A-Z]\w\+GetType()\)/\l\1/g' final.nim

ruby ../glib_fix_proc.rb final.nim
ruby ../glib_fix_T.rb final.nim gobject ""
ruby ../glib_fix_enum_prefix.rb final.nim

sed -i 's/^proc ref\*(/proc `ref`\*(/g' final.nim
sed -i 's/\(\breserved[0-9]\)\*:/\1:/g' final.nim
sed -i 's/\(\bpadding\)\*:/\1:/g' final.nim

sed -i -f ../glib_sedlist final.nim

i='{.deadCodeElim: on.}
'
j='
from glib import Gboolean, Gpointer, Gconstpointer, Gunichar, Gsize, GList, GSList, GQuark, GData, GSource, GVariant,
  GVariantType, GCompareFunc, GDuplicateFunc, GCompareDataFunc, GDestroyNotify, clearPointer,
  GLIB_SIZEOF_SIZE_T, GLIB_SIZEOF_LONG

import macros, strutils

const
  CPLUSPLUS = false
  G_DISABLE_CAST_CHECKS = false
'
perl -0777 -p -i -e "s/\Q$i\E/$i$j/s" final.nim

sed -i 's/): var GParamSpec {/): ptr GParamSpec {/g' final.nim

sed -i 's/G_TYPE_FLAG_VALUE_ABSTRACT/GTypeFlags.VALUE_ABSTRACT/g' final.nim
sed -i 's/G_TYPE_FLAG_ABSTRACT/GTypeFlags.ABSTRACT/g' final.nim

sed -i 's/G_TYPE_FLAG_INSTANTIATABLE/GTypeFundamentalFlags.INSTANTIATABLE/g' final.nim
sed -i 's/G_TYPE_FLAG_DEEP_DERIVABLE/GTypeFundamentalFlags.DEEP_DERIVABLE/g' final.nim
sed -i 's/G_TYPE_FLAG_DERIVABLE/GTypeFundamentalFlags.DERIVABLE/g' final.nim
sed -i 's/G_TYPE_FLAG_CLASSED/GTypeFundamentalFlags.CLASSED/g' final.nim
sed -i 's/\bG_TYPE_FLAGS\b/G_TYPE_FLAG/g' final.nim
sed -i 's/G_CONNECT_SWAPPED/GConnectFlags.SWAPPED/g' final.nim
sed -i 's/G_CONNECT_AFTER/GConnectFlags.AFTER/g' final.nim

sed -i 's/G_SIGNAL_MATCH_FUNC or G_SIGNAL_MATCH_DATA/GSignalMatchType.FUNC.ord or GSignalMatchType.DATA.ord/g' final.nim
sed -i 's/G_SIGNAL_MATCH_DATA/GSignalMatchType.DATA/g' final.nim

sed -i 's/\(dummy[0-9]\{0,1\}\)\*/\1/g' final.nim
sed -i 's/\(reserved[0-9]\{0,1\}\)\*/\1/g' final.nim

sed -i 's/\([,=(] \{0,1\}\)[(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/\1\2/g' final.nim

i='template g_type_fundamental*(`type`: untyped): untyped = 
  (g_type_fundamental(`type`))
'
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim

ruby ../fix_object_of.rb final.nim

i='type
  GEnumClass* =  ptr GEnumClassObj
  GEnumClassPtr* = ptr GEnumClassObj
  GEnumClassObj* = object
    gTypeClass*: GTypeClassObj
    minimum*: Gint
    maximum*: Gint
    nValues*: Guint
    values*: GEnumValue

#type
  GFlagsClass* =  ptr GFlagsClassObj
  GFlagsClassPtr* = ptr GFlagsClassObj
  GFlagsClassObj* = object
    gTypeClass*: GTypeClassObj
    mask*: Guint
    nValues*: Guint
    values*: GFlagsValue
'
j='type
  GEnumClass* =  ptr GEnumClassObj
  GEnumClassPtr* = ptr GEnumClassObj
  GEnumClassObj* = object of GTypeClassObj
    minimum*: Gint
    maximum*: Gint
    nValues*: Guint
    values*: GEnumValue

#type
  GFlagsClass* =  ptr GFlagsClassObj
  GFlagsClassPtr* = ptr GFlagsClassObj
  GFlagsClassObj* = object of GTypeClassObj
    mask*: Guint
    nValues*: Guint
    values*: GFlagsValue
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GTypeInterface* =  ptr GTypeInterfaceObj
  GTypeInterfacePtr* = ptr GTypeInterfaceObj
  GTypeInterfaceObj* = object
    gType*: GType
    gInstanceType*: GType
'
j='type
  GTypeInterface* =  ptr GTypeInterfaceObj
  GTypeInterfacePtr* = ptr GTypeInterfaceObj
  GTypeInterfaceObj*{.inheritable, pure.} = object
    gType*: GType
    gInstanceType*: GType
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GTypePluginClass* =  ptr GTypePluginClassObj
  GTypePluginClassPtr* = ptr GTypePluginClassObj
  GTypePluginClassObj* = object
    baseIface*: GTypeInterfaceObj
    usePlugin*: GTypePluginUse
    unusePlugin*: GTypePluginUnuse
    completeTypeInfo*: GTypePluginCompleteTypeInfo
    completeInterfaceInfo*: GTypePluginCompleteInterfaceInfo
'
j='type
  GTypePluginClass* =  ptr GTypePluginClassObj
  GTypePluginClassPtr* = ptr GTypePluginClassObj
  GTypePluginClassObj* = object of GTypeInterfaceObj
    usePlugin*: GTypePluginUse
    unusePlugin*: GTypePluginUnuse
    completeTypeInfo*: GTypePluginCompleteTypeInfo
    completeInterfaceInfo*: GTypePluginCompleteInterfaceInfo
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GTypeClass* =  ptr GTypeClassObj
  GTypeClassPtr* = ptr GTypeClassObj
  GTypeClassObj* = object
    gType*: GType
'
j='type
  GTypeClass* =  ptr GTypeClassObj
  GTypeClassPtr* = ptr GTypeClassObj
  GTypeClassObj*{.inheritable, pure.} = object
    gType*: GType
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GParamSpecClass* =  ptr GParamSpecClassObj
  GParamSpecClassPtr* = ptr GParamSpecClassObj
  GParamSpecClassObj* = object
    gTypeClass*: GTypeClassObj
    valueType*: GType
    finalize*: proc (pspec: GParamSpec)
    valueSetDefault*: proc (pspec: GParamSpec; value: GValue)
    valueValidate*: proc (pspec: GParamSpec; value: GValue): Gboolean
    valuesCmp*: proc (pspec: GParamSpec; value1: GValue; value2: GValue): Gint
    dummy: array[4, Gpointer]
'
j='type
  GParamSpecClass* =  ptr GParamSpecClassObj
  GParamSpecClassPtr* = ptr GParamSpecClassObj
  GParamSpecClassObj* = object of GTypeClassObj
    valueType*: GType
    finalize*: proc (pspec: GParamSpec)
    valueSetDefault*: proc (pspec: GParamSpec; value: GValue)
    valueValidate*: proc (pspec: GParamSpec; value: GValue): Gboolean
    valuesCmp*: proc (pspec: GParamSpec; value1: GValue; value2: GValue): Gint
    dummy: array[4, Gpointer]
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GParamSpec* =  ptr GParamSpecObj
  GParamSpecPtr* = ptr GParamSpecObj
  GParamSpecObj* = object
    gTypeInstance*: GTypeInstanceObj
    name*: cstring
    flags*: GParamFlags
    valueType*: GType
    ownerType*: GType
    nick*: cstring
    blurb*: cstring
    qdata*: glib.GData
    refCount*: Guint
    paramId*: Guint
'
j='type
  GParamSpec* =  ptr GParamSpecObj
  GParamSpecPtr* = ptr GParamSpecObj
  GParamSpecObj* = object of GTypeInstanceObj
    name*: cstring
    flags*: GParamFlags
    valueType*: GType
    ownerType*: GType
    nick*: cstring
    blurb*: cstring
    qdata*: glib.GData
    refCount*: Guint
    paramId*: Guint
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GTypeInstance* =  ptr GTypeInstanceObj
  GTypeInstancePtr* = ptr GTypeInstanceObj
  GTypeInstanceObj* = object
    gClass*: GTypeClass
'
j='type
  GTypeInstance* =  ptr GTypeInstanceObj
  GTypeInstancePtr* = ptr GTypeInstanceObj
  GTypeInstanceObj*{.inheritable, pure.} = object
    gClass*: GTypeClass
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GObject* =  ptr GObjectObj
  GObjectPtr* = ptr GObjectObj
  GObjectObj* = object
    gTypeInstance*: GTypeInstanceObj
    refCount*: Guint
    qdata*: glib.GData



type
  GObjectClass* =  ptr GObjectClassObj
  GObjectClassPtr* = ptr GObjectClassObj
  GObjectClassObj* = object
    gTypeClass*: GTypeClassObj
    constructProperties*: glib.GSList
    constructor*: proc (`type`: GType; nConstructProperties: Guint;
                      constructProperties: GObjectConstructParam): GObject
    setProperty*: proc (`object`: GObject; propertyId: Guint; value: GValue;
                      pspec: GParamSpec)
    getProperty*: proc (`object`: GObject; propertyId: Guint; value: GValue;
                      pspec: GParamSpec)
    dispose*: proc (`object`: GObject)
    finalize*: proc (`object`: GObject)
    dispatchPropertiesChanged*: proc (`object`: GObject; nPspecs: Guint;
                                    pspecs: var GParamSpec)
    notify*: proc (`object`: GObject; pspec: GParamSpec)
    constructed*: proc (`object`: GObject)
    flags*: Gsize
    pdummy: array[6, Gpointer]
'
j='type
  GObject* =  ptr GObjectObj
  GObjectPtr* = ptr GObjectObj
  GObjectObj* = object of GTypeInstanceObj
    refCount*: Guint
    qdata*: glib.GData

type
  GObjectClass* =  ptr GObjectClassObj
  GObjectClassPtr* = ptr GObjectClassObj
  GObjectClassObj* = object of GTypeClassObj
    constructProperties*: glib.GSList
    constructor*: proc (`type`: GType; nConstructProperties: Guint;
                      constructProperties: GObjectConstructParam): GObject
    setProperty*: proc (`object`: GObject; propertyId: Guint; value: GValue;
                      pspec: GParamSpec)
    getProperty*: proc (`object`: GObject; propertyId: Guint; value: GValue;
                      pspec: GParamSpec)
    dispose*: proc (`object`: GObject)
    finalize*: proc (`object`: GObject)
    dispatchPropertiesChanged*: proc (`object`: GObject; nPspecs: Guint;
                                    pspecs: var GParamSpec)
    notify*: proc (`object`: GObject; pspec: GParamSpec)
    constructed*: proc (`object`: GObject)
    flags*: Gsize
    pdummy: array[6, Gpointer]
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='template g_Closure_Needs_Marshal*(closure: untyped): untyped =
  ((cast[GClosure](closure)).marshal == nil)


template g_Closure_N_Notifiers*(cl: untyped): untyped =
  ((cl.nGuards shl 1) + (cl).nFnotifiers + (cl).nInotifiers)


template g_Cclosure_Swap_Data*(cclosure: untyped): untyped =
  ((cast[GClosure](cclosure)).derivativeFlag)


template g_Callback*(f: untyped): untyped =
  (gCallback(f))


type
  GCallback* = proc ()


type
  GClosureNotify* = proc (data: Gpointer; closure: GClosure)


type
  GClosureMarshal* = proc (closure: GClosure; returnValue: GValue;
                        nParamValues: Guint; paramValues: GValue;
                        invocationHint: Gpointer; marshalData: Gpointer)


#[type
  GVaClosureMarshal* = proc (closure: GClosure; returnValue: GValue;
                          instance: Gpointer; args: VaList; marshalData: Gpointer;
                          nParams: cint; paramTypes: ptr GType)
]#

type
  GClosureNotifyData* =  ptr GClosureNotifyDataObj
  GClosureNotifyDataPtr* = ptr GClosureNotifyDataObj
  GClosureNotifyDataObj* = object
    data*: Gpointer
    notify*: GClosureNotify



type
  GClosure* =  ptr GClosureObj
  GClosurePtr* = ptr GClosureObj
  GClosureObj* = object
    refCount* {.bitsize: 15.}: Guint
    metaMarshalNouse* {.bitsize: 1.}: Guint
    nGuards* {.bitsize: 1.}: Guint
    nFnotifiers* {.bitsize: 2.}: Guint
    nInotifiers* {.bitsize: 8.}: Guint
    inInotify* {.bitsize: 1.}: Guint
    floating* {.bitsize: 1.}: Guint
    derivativeFlag* {.bitsize: 1.}: Guint
    inMarshal* {.bitsize: 1.}: Guint
    isInvalid* {.bitsize: 1.}: Guint
    marshal*: proc (closure: GClosure; returnValue: GValue; nParamValues: Guint;
                  paramValues: GValue; invocationHint: Gpointer;
                  marshalData: Gpointer)
    data*: Gpointer
    notifiers*: GClosureNotifyData



type
  GCClosure* =  ptr GCClosureObj
  GCClosurePtr* = ptr GCClosureObj
  GCClosureObj* = object
    closure*: GClosureObj
    callback*: Gpointer
'
j='type
  GCallback* = proc ()


#type
  GClosureNotify* = proc (data: Gpointer; closure: GClosure)


#type
  GClosureMarshal* = proc (closure: GClosure; returnValue: GValue;
                        nParamValues: Guint; paramValues: GValue;
                        invocationHint: Gpointer; marshalData: Gpointer)


#[type
  GVaClosureMarshal* = proc (closure: GClosure; returnValue: GValue;
                          instance: Gpointer; args: VaList; marshalData: Gpointer;
                          nParams: cint; paramTypes: ptr GType)
]#

#type
  GClosureNotifyData* =  ptr GClosureNotifyDataObj
  GClosureNotifyDataPtr* = ptr GClosureNotifyDataObj
  GClosureNotifyDataObj* = object
    data*: Gpointer
    notify*: GClosureNotify



#type
  GClosure* =  ptr GClosureObj
  GClosurePtr* = ptr GClosureObj
  GClosureObj*{.inheritable, pure.} = object
    refCount* {.bitsize: 15.}: Guint
    metaMarshalNouse* {.bitsize: 1.}: Guint
    nGuards* {.bitsize: 1.}: Guint
    nFnotifiers* {.bitsize: 2.}: Guint
    nInotifiers* {.bitsize: 8.}: Guint
    inInotify* {.bitsize: 1.}: Guint
    floating* {.bitsize: 1.}: Guint
    derivativeFlag* {.bitsize: 1.}: Guint
    inMarshal* {.bitsize: 1.}: Guint
    isInvalid* {.bitsize: 1.}: Guint
    marshal*: proc (closure: GClosure; returnValue: GValue; nParamValues: Guint;
                  paramValues: GValue; invocationHint: Gpointer;
                  marshalData: Gpointer)
    data*: Gpointer
    notifiers*: GClosureNotifyData



#type
  GCClosure* =  ptr GCClosureObj
  GCClosurePtr* = ptr GCClosureObj
  GCClosureObj* = object
    closure*: GClosureObj
    callback*: Gpointer


template g_Closure_Needs_Marshal*(closure: untyped): untyped =
  ((cast[GClosure](closure)).marshal == nil)


template g_Closure_N_Notifiers*(cl: untyped): untyped =
  ((cl.nGuards shl 1) + (cl).nFnotifiers + (cl).nInotifiers)


template g_Cclosure_Swap_Data*(cclosure: untyped): untyped =
  ((cast[GClosure](cclosure)).derivativeFlag)


#template g_Callback*(f: untyped): untyped =
#  (gCallback(f))
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='template gTypeFundamental*(`type`: untyped): untyped =
  (gTypeFundamental(`type`))
'
j='template gTypeFundamental*(`type`: untyped): untyped =
  fundamental(`type`)
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

sed -i 's/\bproc typeCheck/proc check/g' final.nim

sed -i 's/\bgTypeFundamental(/fundamental(/g' final.nim
sed -i 's/\bgTypeTestFlags(/testFlags(/g' final.nim
sed -i 's/\bgTypeCheckIsValueType(/checkIsValueType(/g' final.nim
sed -i 's/\bg_Define_Type_Extended(/gDefineTypeExtended(/g' final.nim
sed -i 's/\bg_Define_Type_Extended(/gDefineTypeExtended(/g' final.nim
sed -i 's/\bg_Struct_Member(/gStructMember(/g' final.nim
sed -i 's/\bg_Struct_Member_P(/gStructMemberP(/g' final.nim

sed -i 's/\bgTypeCheckInstanceIsFundamentallyA(/checkInstanceIsFundamentallyA(/g' final.nim
sed -i 's/\bgTypeValueTablePeek(/valueTablePeek(/g' final.nim
sed -i 's/\bgTypeCheckInstanceIsA(/checkInstanceIsA(/g' final.nim
sed -i 's/\bgTypeCheckClassIsA(/checkClassIsA(/g' final.nim
sed -i 's/\bgTypeCheckValueHolds(/checkValueHolds(/g' final.nim
sed -i 's/\bgTypeName(/name(/g' final.nim
sed -i 's/\bgClearPointer(/clearPointer(/g' final.nim
sed -i 's/\bgTypeModuleAddInterface(/addInterface(/g' final.nim

sed -i 's/ FLAG_\(\w\+ = \)/ \1/g' final.nim

sed -i 's/g_Type_Fundamental_Max/\U&/g' final.nim
sed -i 's/ g_Type_Flag_Classed/ GTypeFundamentalFlags.CLASSED/g' final.nim
sed -i 's/ g_Type_Flag_Instantiatable/ GTypeFundamentalFlags.INSTANTIATABLE/g' final.nim
sed -i 's/ g_Type_Flag_Derivable/ GTypeFundamentalFlags.DERIVABLE/g' final.nim
sed -i 's/ g_Type_Flag_Deep_Derivable/ GTypeFundamentalFlags.DEEP_DERIVABLE/g' final.nim
sed -i 's/ g_Type_Flag_Abstract/ GTypeFlags.ABSTRACT/g' final.nim
sed -i 's/ g_Type_Flag_Value_Abstract/ GTypeFlags.VALUE_ABSTRACT/g' final.nim

perl -0777 -p -i -e 's/(  \(.*,)\n/\1/g' final.nim
sed -i 's/\(, \) \+/\1/g' final.nim
sed -i 's/ == g_Type_\w\+/\U&/g' final.nim

# yes, apply multiple times!
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( cint)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gdouble)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gdouble)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gfloat)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gfloat)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gboolean)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( cstring)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Guchar)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Guchar)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gpointer)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( GPointer)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gsize)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gssize)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Glong)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Glong)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gsize)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( Gsize)/\1\2\3\4var\6/sg' final.nim

perl -0777 -p -i -e "s~([=:] proc \(.*?\)(?:: (?:ptr )?\w+)?)~\1 {.cdecl.}~sg" final.nim

i='  GCClosureObj* = object
    closure*: GClosureObj
'
j='  GCClosureObj*{.final.} = object of GClosureObj
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

sed -i 's/when GLIB_VERSION_MAX_ALLOWED >= GLIB_VERSION_2_42:/when true: #&/g' final.nim

sed -i '/^#type$/d' final.nim
sed -i 's/\(0x\)0*\([0123456789ABCDEF]\)/\1\2/g' final.nim

sed -i   's/\* = g\([A-Z]\)/* = \L\1/g' final.nim

ruby ../fix_template.rb final.nim ""

sed -i 's/\(: ptr \)\w\+PrivateObj/: pointer/g' final.nim
sed -i '/  \w\+PrivateObj = object$/d' final.nim

for i in uint8 uint16 uint32 uint64 int8 int16 int32 int64 ; do
  sed -i "s/\bG${i}\b/${i}/g" final.nim
done

sed -i "s/ $//g" final.nim

sed -i "s/\bGint\b/cint/g" final.nim
sed -i "s/\bGuint\b/cuint/g" final.nim
sed -i "s/\bGfloat\b/cfloat/g" final.nim
sed -i "s/\bGdouble\b/cdouble/g" final.nim
sed -i "s/\bGshort\b/cshort/g" final.nim
sed -i "s/\bGushort\b/cushort/g" final.nim
sed -i "s/\bGlong\b/clong/g" final.nim
sed -i "s/\bGulong\b/culong/g" final.nim
sed -i "s/\bGuchar\b/cuchar/g" final.nim

sed -i 's/\bfunc\([):,\*]\)/`func`\1/' final.nim
sed -i 's/ glib\./ /' final.nim
sed -i 's/\bproc object\b/proc `object`/g' final.nim
sed -i 's/\bproc enum\b/proc `enum`/g' final.nim

#proc setChar*(value: GValue;
for i in Char Schar Uchar Boolean Int Uint Long Ulong Int64 Uint64 Enum Flags Float Double String; do
  sed -i "s/proc set${i}\*(value: GValue;/proc set${i}\*(value: var GValueObj;/g" final.nim
done

# generate procs without get_ and set_ prefix
#perl -0777 -p -i -e "s/(\n\s*)(proc set)([A-Z]\w+)(\*\([^}]*\) \{[^}]*})/\$&\1proc \`\l\3=\`\4/sg" final.nim
#perl -0777 -p -i -e "s/(\n\s*)(proc get)([A-Z]\w+)(\*\([^}]*\): \w[^}]*})/\$&\1proc \l\3\4/sg" final.nim

# generate procs without get_ and set_ prefix
perl -0777 -p -i -e "s/(\n\s*)(proc set)([A-Z]\w+)(\*\([^}]*\) \{[^}]*})/\$&\1proc \`\l\3=\`\4/sg" final.nim
perl -0777 -p -i -e "s/(\n\s*)(proc get)([A-Z]\w+)(\*\([^}]*\): \w[^}]*})/\$&\1proc \l\3\4/sg" final.nim

# these proc names generate trouble
for i in char schar uchar int uint string enum boolean float double flags long ulong integer int64 uint64 pointer ; do
  #perl -0777 -p -i -e "s/(\n\s*)(proc \`?${i}\`?\=\?)(\*\([^}]*\): \w[^}]*})//sg" final.nim
  #perl -0777 -p -i -e "s/(\n\s*)(proc \`${i}\`\=)(\*\([^}]*\) \{[^}]*})//sg" final.nim
  perl -0777 -p -i -e "s/(\n\s*)(proc \`?${i}=?\`?)(\*\([^}]*\): \w[^}]*})//sg" final.nim
  perl -0777 -p -i -e "s/(\n\s*)(proc \`?${i}=?\`?)(\*\([^}]*\) \{[^}]*})//sg" final.nim
done

sed -i 's/^proc object\*(/proc `object`\*(/g' final.nim
sed -i 's/^proc enum\*(/proc `enum`\*(/g' final.nim

i='when not (G_DISABLE_CAST_CHECKS):
  template gTypeCic*(ip, gt, ct: untyped): untyped =
    (cast[ptr Ct](gTypeCheckInstanceCast(cast[GTypeInstance](ip), gt)))

  template gTypeCcc*(cp, gt, ct: untyped): untyped =
    (cast[ptr Ct](gTypeCheckClassCast(cast[GTypeClass](cp), gt)))

else:
  template gTypeCic*(ip, gt, ct: untyped): untyped =
    (cast[ptr Ct](ip))

  template gTypeCcc*(cp, gt, ct: untyped): untyped =
    (cast[ptr Ct](cp))

template gTypeChi*(ip: untyped): untyped =
  (gTypeCheckInstance(cast[GTypeInstance](ip)))

template gTypeChv*(vl: untyped): untyped =
  (gTypeCheckValue(cast[GValue](vl)))

template gTypeIgc*(ip, gt, ct: untyped): untyped =
  (cast[ptr Ct](((cast[GTypeInstance](ip)).gClass)))

template gTypeIgi*(ip, gt, ct: untyped): untyped =
  (cast[ptr Ct](gTypeInterfacePeek((cast[GTypeInstance](ip)).gClass, gt)))

template gTypeCift*(ip, ft: untyped): untyped =
  (checkInstanceIsFundamentallyA(cast[GTypeInstance](ip), ft))

template gTypeCit*(ip, gt: untyped): untyped =
  (checkInstanceIsA(cast[GTypeInstance](ip), gt))

template gTypeCct*(cp, gt: untyped): untyped =
  (checkClassIsA(cast[GTypeClass](cp), gt))

template gTypeCvh*(vl, gt: untyped): untyped =
  (checkValueHolds(cast[GValue](vl), gt))
'
j='when not (G_DISABLE_CAST_CHECKS):
  template gTypeCic*(ip, gt, ct: untyped): untyped =
    (cast[ptr ct](checkInstanceCast(cast[GTypeInstance](ip), cast[GType](gt))))

  template gTypeCcc*(cp, gt, ct: untyped): untyped =
    (cast[ptr ct](checkClassCast(cast[GTypeClass](cp), cast[GType](gt))))

else:
  template gTypeCic*(ip, gt, ct: untyped): untyped =
    (cast[ptr ct](ip))

  template gTypeCcc*(cp, gt, ct: untyped): untyped =
    (cast[ptr ct](cp))

template gTypeChi*(ip: untyped): untyped =
  (gTypeCheckInstance(cast[GTypeInstance](ip)))

template gTypeChv*(vl: untyped): untyped =
  (gTypeCheckValue(cast[GValue](vl)))

template gTypeIgc*(ip, gt, ct: untyped): untyped =
  (cast[ptr ct](((cast[GTypeInstance](ip)).gClass)))

template gTypeIgi*(ip, gt, ct: untyped): untyped =
  (cast[ptr ct](gTypeInterfacePeek((cast[GTypeInstance](ip)).gClass, gt)))

template gTypeCift*(ip, ft: untyped): untyped =
  (checkInstanceIsFundamentallyA(cast[GTypeInstance](ip), ft))

template gTypeCit*(ip, gt: untyped): untyped =
  (checkInstanceIsA(cast[GTypeInstance](ip), cast[GType](gt)))

template gTypeCct*(cp, gt: untyped): untyped =
  (checkClassIsA(cast[GTypeClass](cp), gt))

template gTypeCvh*(vl, gt: untyped): untyped =
  (checkValueHolds(cast[GValue](vl), gt))
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

sed -i "s/G_TYPE_INTERFACE/G_TYPE_INTERF/g" final.nim
sed -i "s/gSignalConnectData/signalConnectData/g" final.nim
sed -i "s/gTypeInterfacePeek/typeInterfacePeek/g" final.nim
sed -i "s/g_Connect_After/GConnectFlags.AFTER/g" final.nim
sed -i "s/g_Connect_Swapped/GConnectFlags.SWAPPED/g" final.nim
sed -i "s/gSignalMatchType/GSignalMatchType/g" final.nim

i='template gSignalHandlersDisconnectByFunc*(instance, `func`, data: untyped): untyped =
  gSignalHandlersDisconnectMatched(instance, GSignalMatchType(
      g_Signal_Match_Func or g_Signal_Match_Data), 0, 0, nil, `func`, data)


template gSignalHandlersDisconnectByData*(instance, data: untyped): untyped =
  gSignalHandlersDisconnectMatched(instance, g_Signal_Match_Data, 0, 0, nil, nil,
                                   (data))


template gSignalHandlersBlockByFunc*(instance, `func`, data: untyped): untyped =
  gSignalHandlersBlockMatched(instance, GSignalMatchType(
      g_Signal_Match_Func or g_Signal_Match_Data), 0, 0, nil, `func`, data)


template gSignalHandlersUnblockByFunc*(instance, `func`, data: untyped): untyped =
  gSignalHandlersUnblockMatched(instance, GSignalMatchType(
      g_Signal_Match_Func or g_Signal_Match_Data), 0, 0, nil, `func`, data)
'
j='template gSignalHandlersDisconnectByFunc*(instance, `func`, data: untyped): untyped =
  signalHandlersDisconnectMatched(instance, GSignalMatchType(
      GSignalMatchType.FUNC.ord or GSignalMatchType.DATA.ord), 0, 0, nil, `func`, data)

template gSignalHandlersDisconnectByData*(instance, data: untyped): untyped =
  signalHandlersDisconnectMatched(instance, GSignalMatchType.DATA, 0, 0, nil, nil,
                                   (data))

template gSignalHandlersBlockByFunc*(instance, `func`, data: untyped): untyped =
  signalHandlersBlockMatched(instance, GSignalMatchType(
      GSignalMatchType.FUNC.ord or GSignalMatchType.DATA.ord), 0, 0, nil, `func`, data)

template gSignalHandlersUnblockByFunc*(instance, `func`, data: untyped): untyped =
  gSignalHandlersUnblockMatched(instance, GSignalMatchType(
      GSignalMatchType.FUNC.ord or GSignalMatchType.DATA.ord), 0, 0, nil, `func`, data)
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

sed -i 's/= (1 shl \([0-9]\)),/= 1 shl \1,/g' final.nim
sed -i 's/= (1 shl \([0-9]\))$/= 1 shl \1/g' final.nim

sed -i 's/\(proc \w\+New\)[A-Z]\w\+/\1/g' final.nim
sed -i 's/proc \(\w\+\)New\*/proc new\u\1*/g' final.nim

i='proc newCclosure*(callbackFunc: GCallback; userData: Gpointer;
                      destroyData: GClosureNotify): GClosure {.
    importc: "g_cclosure_new_swap", libgobj.}
'
j='proc newCclosureSwap*(callbackFunc: GCallback; userData: Gpointer;
                      destroyData: GClosureNotify): GClosure {.
    importc: "g_cclosure_new_swap", libgobj.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='proc newCclosure*(callbackFunc: GCallback; `object`: GObject): GClosure {.
    importc: "g_cclosure_new_object_swap", libgobj.}
'
j='proc newCclosureSwap*(callbackFunc: GCallback; `object`: GObject): GClosure {.
    importc: "g_cclosure_new_object_swap", libgobj.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='template gTypeInstanceGetPrivate*(instance, gType, cType: untyped): untyped =
  (cast[ptr CType](gTypeInstanceGetPrivate(cast[GTypeInstance](instance), (gType))))

template gTypeClassGetPrivate*(klass, gType, cType: untyped): untyped =
  (cast[ptr CType](gTypeClassGetPrivate(cast[GTypeClass](klass), gType)))
'
j='template gTypeInstanceGetPrivate*(instance, gType, cType: untyped): untyped =
  (cast[ptr CType](getPrivate(cast[GTypeInstance](instance), (gType))))

template gTypeClassGetPrivate*(klass, gType, cType: untyped): untyped =
  (cast[ptr CType](getPrivate(cast[GTypeClass](klass), gType)))
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='template gTypeCheckInstance*(instance: untyped): untyped =
  (gTypeChi(cast[GTypeInstance](instance)))


template gTypeCheckInstanceCast*(instance, gType, cType: untyped): untyped =
  (gTypeCic(instance, gType, cType))


template gTypeCheckInstanceType*(instance, gType: untyped): untyped =
  (gTypeCit(instance, gType))


template gTypeCheckInstanceFundamentalType*(instance, gType: untyped): untyped =
  (gTypeCift(instance, gType))


template gTypeInstanceGetClass*(instance, gType, cType: untyped): untyped =
  (gTypeIgc(instance, gType, cType))


template gTypeInstanceGetInterface*(instance, gType, cType: untyped): untyped =
  (gTypeIgi(instance, gType, cType))


template gTypeCheckClassCast*(gClass, gType, cType: untyped): untyped =
  (gTypeCcc(gClass, gType, cType))


template gTypeCheckClassType*(gClass, gType: untyped): untyped =
  (gTypeCct(gClass, gType))


template gTypeCheckValue*(value: untyped): untyped =
  (gTypeChv(value))


template gTypeCheckValueType*(value, gType: untyped): untyped =
  (gTypeCvh(value, gType))


template gTypeFromInstance*(instance: untyped): untyped =
  (gTypeFromClass((cast[GTypeInstance](instance)).gClass))


template gTypeFromClass*(gClass: untyped): untyped =
  ((cast[GTypeClass](gClass)).gType)


template gTypeFromInterface*(gIface: untyped): untyped =
  ((cast[GTypeInterface](gIface)).gType)


template gTypeInstanceGetPrivate*(instance, gType, cType: untyped): untyped =
  (cast[ptr CType](gTypeInstanceGetPrivate(cast[GTypeInstance](instance), gType)))


template gTypeClassGetPrivate*(klass, gType, cType: untyped): untyped =
  (cast[ptr CType](gTypeClassGetPrivate(cast[GTypeClass](klass), gType)))
'
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim
j='const
  G_TYPE_FLAG_RESERVED_ID_BIT* = (GType(1 shl 0))
'
perl -0777 -p -i -e "s/\Q$j\E/$i$j/s" final.nim

i='proc newObject*(objectType: GType; firstPropertyName: cstring): Gpointer {.varargs,
    importc: "g_object_new", libgobj.}
'
j='proc newObject*(objectType: GType; firstPropertyName: cstring): GObject {.varargs,
    importc: "g_object_new", libgobj.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

# fundamental GTypes
sed -i 's/\bg_Type_\w\+/\U&/g' final.nim

# NOP
sed -i 's/\(proc \w\+New\)[A-Z]\w\+/\1/g' final.nim
sed -i 's/proc \(\w\+\)New\*/proc new\u\1*/g' final.nim

sed -i 's/proc init\*(value: GValue;/proc init\*(value: var GValueObj;/g' final.nim

cat ../gobject_extensions.nim >> final.nim

cat -s final.nim > gobject.nim

rm -r gobject
#rm all.h list.txt final.h final.nim

ln -s ~/ngtk3/nim-glib/src/glib.nim

exit

