#!/bin/bash
# S. Salewski, 17-JUL-2017
# generate glib bindings for Nim
# this does not cover gobject and gmodule, they are in separate modules
#
glib_dir="/home/stefan/Downloads/glib-2.53.3"
final="final.h" # the input file for c2nim
list="list.txt"
wdir="tmp_glib"

targets=''
all_t=". ${targets}"

rm -rf $wdir # start from scratch
mkdir $wdir
cd $wdir
cp -r $glib_dir/glib .
cd glib

# indeed we missed gversionmacros.h and valgrind.h -- but do we need them?
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

cat glib.h > all.h

cd ..

# cpp run with all headers to determine order
echo "cat \\" > $list

cpp -I. `pkg-config --cflags gtk+-3.0` glib/all.h $final

# may we need this?
#echo 'gversionmacros.h \' >> $list

# extract file names and push names to list
grep ssalewski $final | sed 's/_ssalewski;/ \\/' >> $list

# strange macros -- we should not need them
sed -i '/gatomic.h/d' $list

i=`sort $list | uniq -d | wc -l`
if [ $i != 0 ]; then echo 'list contains duplicates!'; exit; fi;

# now we work again with original headers
rm -rf glib
cp -r $glib_dir/glib .

# insert for each header file its name as first line
for j in $all_t ; do
  for i in glib/${j}/*.h; do
    sed -i "1i/* file: $i */" $i
  done
done
cd glib
  bash ../$list > ../$final
cd ..

cp $final fun.h

# delete strange macros (define as empty)
# we restrict use of wildcards to limit risc of damage something!
for i in 28 30 32 34 36 38 40 42 44 46 48 50 52 54 ; do
  sed -i "1i#def GLIB_AVAILABLE_IN_2_$i\n#def GLIB_DEPRECATED_IN_2_${i}_FOR(x)" $final
done

sed -i "1i#def GLIB_DEPRECATED_IN_2_30" $final
sed -i "1i#def GLIB_DEPRECATED_IN_2_34" $final
sed -i "1i#def GLIB_DEPRECATED_IN_2_44" $final
sed -i "1i#def GLIB_DEPRECATED_IN_2_46" $final
sed -i "1i#def GLIB_DEPRECATED_IN_2_48" $final
sed -i "1i#def GLIB_DEPRECATED" $final
sed -i "1i#def G_INLINE_FUNC" $final
sed -i "1i#def G_BEGIN_DECLS" $final
sed -i "1i#def G_END_DECLS" $final
sed -i "1i#def GLIB_DEPRECATED_FOR(i)" $final
sed -i "1i#def GLIB_AVAILABLE_IN_ALL" $final
sed -i "1i#def G_GNUC_WARN_UNUSED_RESULT" $final
sed -i "1i#def G_ANALYZER_NORETURN" $final
sed -i "1i#def G_GNUC_NORETURN" $final
sed -i "1i#def G_LIKELY" $final
sed -i "1i#def G_GNUC_PRINTF(i,j)" $final
sed -i "1i#def G_GNUC_MALLOC" $final
sed -i "1i#def G_GNUC_CONST" $final
sed -i "1i#def G_GNUC_PURE" $final
sed -i "1i#def G_UNLIKELY" $final
sed -i "1i#def G_GNUC_NULL_TERMINATED" $final
sed -i "1i#def G_GNUC_ALLOC_SIZE(i)" $final
sed -i "1i#def G_GNUC_FORMAT(i)" $final
sed -i "1i#def G_GNUC_ALLOC_SIZE2(i, j)" $final

# we should not need this for Nim, so delete it
# next is long, so mark begin/end and use sed to delete

sed -i "/Unlock @locker's mutex/d" $final
# '\'' is the trick!

i='typedef void GMutexLocker;

/**
 * g_mutex_locker_new:
 * @mutex: a mutex to lock
 *
 * Lock @mutex and return a new #GMutexLocker. Unlock with
 * g_mutex_locker_free(). Using g_mutex_unlock() on @mutex
 * while a #GMutexLocker exists can lead to undefined behaviour.
 *
 * This is intended to be used with g_autoptr().  Note that g_autoptr()
 * is only available when using GCC or clang, so the following example
 * will only work with those compilers:
 * |[
 * typedef struct
 * {
 *   ...
 *   GMutex mutex;
 *   ...
 * } MyObject;
 *
 * static void
 * my_object_do_stuff (MyObject *self)
 * {
 *   g_autoptr(GMutexLocker) locker = g_mutex_locker_new (&self->mutex);
 *
 *   // Code with mutex locked here
 *
 *   if (cond)
 *     // No need to unlock
 *     return;
 *
 *   // Optionally early unlock
 *   g_clear_pointer (&locker, g_mutex_locker_free);
 *
 *   // Code with mutex unlocked here
 * }
 * ]|
 *
 * Returns: a #GMutexLocker
 * Since: 2.44
 */
static inline GMutexLocker *
g_mutex_locker_new (GMutex *mutex)
{
  g_mutex_lock (mutex);
  return (GMutexLocker *) mutex;
}

/**
 * g_mutex_locker_free:
 * @locker: a GMutexLocker
 *
 *
 * Since: 2.44
 */
static inline void
g_mutex_locker_free (GMutexLocker *locker)
{
  g_mutex_unlock ((GMutex *) locker);
}
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='typedef void GMutexLocker;

/**
 * g_mutex_locker_new:
'
perl -0777 -p -i -e "s~\Q$i\E~\nSalewskiDelStart\n~s" $final
i='static inline void
g_mutex_locker_free (GMutexLocker *locker)
{
  g_mutex_unlock ((GMutex *) locker);
}
'
perl -0777 -p -i -e "s~\Q$i\E~\nSalewskiDelEnd\n~s" $final
sed -i '/SalewskiDelStart/,/SalewskiDelEnd/d' $final

i='static inline gint
g_bit_nth_lsf_impl (gulong mask,
                    gint   nth_bit)
{
  if (G_UNLIKELY (nth_bit < -1))
    nth_bit = -1;
  while (nth_bit < ((GLIB_SIZEOF_LONG * 8) - 1))
    {
      nth_bit++;
      if (mask & (1UL << nth_bit))
        return nth_bit;
    }
  return -1;
}

static inline gint
g_bit_nth_msf_impl (gulong mask,
                    gint   nth_bit)
{
  if (nth_bit < 0 || G_UNLIKELY (nth_bit > GLIB_SIZEOF_LONG * 8))
    nth_bit = GLIB_SIZEOF_LONG * 8;
  while (nth_bit > 0)
    {
      nth_bit--;
      if (mask & (1UL << nth_bit))
        return nth_bit;
    }
  return -1;
}

static inline guint
g_bit_storage_impl (gulong number)
{
#if defined(__GNUC__) && (__GNUC__ >= 4) && defined(__OPTIMIZE__)
  return G_LIKELY (number) ?
           ((GLIB_SIZEOF_LONG * 8U - 1) ^ (guint) __builtin_clzl(number)) + 1 : 1;
#else
  guint n_bits = 0;

  do
    {
      n_bits++;
      number >>= 1;
    }
  while (number);
  return n_bits;
#endif
}
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define g_bit_nth_lsf(mask, nth_bit) g_bit_nth_lsf_impl(mask, nth_bit)
#define g_bit_nth_msf(mask, nth_bit) g_bit_nth_msf_impl(mask, nth_bit)
#define g_bit_storage(number)        g_bit_storage_impl(number)
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifndef _GLIB_TEST_OVERFLOW_FALLBACK
/* https://bugzilla.gnome.org/show_bug.cgi?id=769104 */
#if __GNUC__ >= 5 && !defined(__INTEL_COMPILER)
#define _GLIB_HAVE_BUILTIN_OVERFLOW_CHECKS
#elif __has_builtin(__builtin_uadd_overflow)
#define _GLIB_HAVE_BUILTIN_OVERFLOW_CHECKS
#endif
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='GLIB_AVAILABLE_IN_ALL
gint    (g_bit_nth_lsf)         (gulong mask,
                                 gint   nth_bit);
GLIB_AVAILABLE_IN_ALL
gint    (g_bit_nth_msf)         (gulong mask,
                                 gint   nth_bit);
GLIB_AVAILABLE_IN_ALL
guint   (g_bit_storage)         (gulong number);
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#if !defined (G_VA_COPY)
#  if defined (__GNUC__) && defined (__PPC__) && (defined (_CALL_SYSV) || defined (_WIN32))
#    define G_VA_COPY(ap1, ap2)	  (*(ap1) = *(ap2))
#  elif defined (G_VA_COPY_AS_ARRAY)
#    define G_VA_COPY(ap1, ap2)	  memmove ((ap1), (ap2), sizeof (va_list))
#  else /* va_list is a pointer */
#    define G_VA_COPY(ap1, ap2)	  ((ap1) = (ap2))
#  endif /* va_list is a pointer */
#endif /* !G_VA_COPY */
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifndef _GLIB_TEST_OVERFLOW_FALLBACK
#if __GNUC__ >= 5
#define _GLIB_HAVE_BUILTIN_OVERFLOW_CHECKS
#elif __has_builtin(__builtin_uadd_overflow)
#define _GLIB_HAVE_BUILTIN_OVERFLOW_CHECKS
#endif
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='/* Crashes the program. */
#if GLIB_VERSION_MAX_ALLOWED >= GLIB_VERSION_2_50
#ifndef G_OS_WIN32
#  define g_abort() abort ()
#else
GLIB_AVAILABLE_IN_2_50
void g_abort (void) G_GNUC_NORETURN G_ANALYZER_NORETURN;
#endif
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifdef _GLIB_HAVE_BUILTIN_OVERFLOW_CHECKS
static inline gboolean _GLIB_CHECKED_ADD_U32 (guint32 *dest, guint32 a, guint32 b) {
  return !__builtin_uadd_overflow(a, b, dest); }
static inline gboolean _GLIB_CHECKED_MUL_U32 (guint32 *dest, guint32 a, guint32 b) {
  return !__builtin_umul_overflow(a, b, dest); }
static inline gboolean _GLIB_CHECKED_ADD_U64 (guint64 *dest, guint64 a, guint64 b) {
  G_STATIC_ASSERT(sizeof (unsigned long long) == sizeof (guint64));
  return !__builtin_uaddll_overflow(a, b, (unsigned long long *) dest); }
static inline gboolean _GLIB_CHECKED_MUL_U64 (guint64 *dest, guint64 a, guint64 b) {
  return !__builtin_umulll_overflow(a, b, (unsigned long long *) dest); }
#else
static inline gboolean _GLIB_CHECKED_ADD_U32 (guint32 *dest, guint32 a, guint32 b) {
  *dest = a + b; return *dest >= a; }
static inline gboolean _GLIB_CHECKED_MUL_U32 (guint32 *dest, guint32 a, guint32 b) {
  *dest = a * b; return !a || *dest / a == b; }
static inline gboolean _GLIB_CHECKED_ADD_U64 (guint64 *dest, guint64 a, guint64 b) {
  *dest = a + b; return *dest >= a; }
static inline gboolean _GLIB_CHECKED_MUL_U64 (guint64 *dest, guint64 a, guint64 b) {
  *dest = a * b; return !a || *dest / a == b; }
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='/* Arch specific stuff for speed
 */
#if defined (__GNUC__) && (__GNUC__ >= 2) && defined (__OPTIMIZE__)

#  if __GNUC__ >= 4 && defined (__GNUC_MINOR__) && __GNUC_MINOR__ >= 3
#    define GUINT32_SWAP_LE_BE(val) ((guint32) __builtin_bswap32 ((gint32) (val)))
#    define GUINT64_SWAP_LE_BE(val) ((guint64) __builtin_bswap64 ((gint64) (val)))
#  endif

#  if defined (__i386__)
'
perl -0777 -p -i -e "s~\Q$i\E~\nSalewskiDelStart\n~s" $final
i='#    ifndef GUINT64_SWAP_LE_BE
#      define GUINT64_SWAP_LE_BE(val) (GUINT64_SWAP_LE_BE_CONSTANT (val))
#    endif
#  endif
#else /* generic */
#  define GUINT16_SWAP_LE_BE(val) (GUINT16_SWAP_LE_BE_CONSTANT (val))
#  define GUINT32_SWAP_LE_BE(val) (GUINT32_SWAP_LE_BE_CONSTANT (val))
#  define GUINT64_SWAP_LE_BE(val) (GUINT64_SWAP_LE_BE_CONSTANT (val))
#endif /* generic */
'
perl -0777 -p -i -e "s~\Q$i\E~\nSalewskiDelEnd\n~s" $final
sed -i '/SalewskiDelStart/,/SalewskiDelEnd/d' $final

i='typedef union  _GDoubleIEEE754	GDoubleIEEE754;
typedef union  _GFloatIEEE754	GFloatIEEE754;
#define G_IEEE754_FLOAT_BIAS	(127)
#define G_IEEE754_DOUBLE_BIAS	(1023)
/* multiply with base2 exponent to get base10 exponent (normal numbers) */
#define G_LOG_2_BASE_10		(0.30102999566398119521)
#if G_BYTE_ORDER == G_LITTLE_ENDIAN
union _GFloatIEEE754
{
  gfloat v_float;
  struct {
    guint mantissa : 23;
    guint biased_exponent : 8;
    guint sign : 1;
  } mpn;
};
union _GDoubleIEEE754
{
  gdouble v_double;
  struct {
    guint mantissa_low : 32;
    guint mantissa_high : 20;
    guint biased_exponent : 11;
    guint sign : 1;
  } mpn;
};
#elif G_BYTE_ORDER == G_BIG_ENDIAN
union _GFloatIEEE754
{
  gfloat v_float;
  struct {
    guint sign : 1;
    guint biased_exponent : 8;
    guint mantissa : 23;
  } mpn;
};
union _GDoubleIEEE754
{
  gdouble v_double;
  struct {
    guint sign : 1;
    guint biased_exponent : 11;
    guint mantissa_high : 20;
    guint mantissa_low : 32;
  } mpn;
};
#else /* !G_LITTLE_ENDIAN && !G_BIG_ENDIAN */
#error unknown ENDIAN type
#endif /* !G_LITTLE_ENDIAN && !G_BIG_ENDIAN */
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifndef GLIB_VAR
#  ifdef G_PLATFORM_WIN32
#    ifdef GLIB_STATIC_COMPILATION
#      define GLIB_VAR extern
#    else /* !GLIB_STATIC_COMPILATION */
#      ifdef GLIB_COMPILATION
#        ifdef DLL_EXPORT
#          define GLIB_VAR __declspec(dllexport)
#        else /* !DLL_EXPORT */
#          define GLIB_VAR extern
#        endif /* !DLL_EXPORT */
#      else /* !GLIB_COMPILATION */
#        define GLIB_VAR extern __declspec(dllimport)
#      endif /* !GLIB_COMPILATION */
#    endif /* !GLIB_STATIC_COMPILATION */
#  else /* !G_PLATFORM_WIN32 */
#    define GLIB_VAR _GLIB_EXTERN
#  endif /* !G_PLATFORM_WIN32 */
#endif /* GLIB_VAR */
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define G_DEFINE_QUARK(QN, q_n)                                         \
GQuark                                                                  \
q_n##_quark (void)                                                      \
{                                                                       \
  static GQuark q;                                                      \
                                                                        \
  if G_UNLIKELY (q == 0)                                                \
    q = g_quark_from_static_string (#QN);                               \
                                                                        \
  return q;                                                             \
}
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

sed -i '/#define G_PRIVATE_INIT(notify) { NULL, (notify), { NULL, NULL } }/d' $final
sed -i '/#define G_ONCE_INIT { G_ONCE_STATUS_NOTCALLED, NULL }/d' $final

i='#define G_LOCK_NAME(name)             g__ ## name ## _lock
#define G_LOCK_DEFINE_STATIC(name)    static G_LOCK_DEFINE (name)
#define G_LOCK_DEFINE(name)           GMutex G_LOCK_NAME (name)
#define G_LOCK_EXTERN(name)           extern GMutex G_LOCK_NAME (name)

#ifdef G_DEBUG_LOCKS
#  define G_LOCK(name)                G_STMT_START{             \
      g_log (G_LOG_DOMAIN, G_LOG_LEVEL_DEBUG,                   \
             "file %s: line %d (%s): locking: %s ",             \
             __FILE__,        __LINE__, G_STRFUNC,              \
             #name);                                            \
      g_mutex_lock (&G_LOCK_NAME (name));                       \
   }G_STMT_END
#  define G_UNLOCK(name)              G_STMT_START{             \
      g_log (G_LOG_DOMAIN, G_LOG_LEVEL_DEBUG,                   \
             "file %s: line %d (%s): unlocking: %s ",           \
             __FILE__,        __LINE__, G_STRFUNC,              \
             #name);                                            \
     g_mutex_unlock (&G_LOCK_NAME (name));                      \
   }G_STMT_END
#  define G_TRYLOCK(name)                                       \
      (g_log (G_LOG_DOMAIN, G_LOG_LEVEL_DEBUG,                  \
             "file %s: line %d (%s): try locking: %s ",         \
             __FILE__,        __LINE__, G_STRFUNC,              \
             #name), g_mutex_trylock (&G_LOCK_NAME (name)))
#else  /* !G_DEBUG_LOCKS */
#  define G_LOCK(name) g_mutex_lock       (&G_LOCK_NAME (name))
#  define G_UNLOCK(name) g_mutex_unlock   (&G_LOCK_NAME (name))
#  define G_TRYLOCK(name) g_mutex_trylock (&G_LOCK_NAME (name))
#endif /* !G_DEBUG_LOCKS */
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifdef __GNUC__
# define g_once_init_enter(location) \
  (G_GNUC_EXTENSION ({                                               \
    G_STATIC_ASSERT (sizeof *(location) == sizeof (gpointer));       \
    (void) (0 ? (gpointer) *(location) : 0);                         \
    (!g_atomic_pointer_get (location) &&                             \
     g_once_init_enter (location));                                  \
  }))
# define g_once_init_leave(location, result) \
  (G_GNUC_EXTENSION ({                                               \
    G_STATIC_ASSERT (sizeof *(location) == sizeof (gpointer));       \
    (void) (0 ? *(location) = (result) : 0);                         \
    g_once_init_leave ((location), (gsize) (result));                \
  }))
#else
# define g_once_init_enter(location) \
  (g_once_init_enter((location)))
# define g_once_init_leave(location, result) \
  (g_once_init_leave((location), (gsize) (result)))
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

sed -i '/#  define G_BREAKPOINT()        G_STMT_START{ __asm__ __volatile__ ("int $03"); }G_STMT_END/d' $final

i='#if (defined (__i386__) || defined (__x86_64__)) && defined (__GNUC__) && __GNUC__ >= 2
#elif (defined (_MSC_VER) || defined (__DMC__)) && defined (_M_IX86)
#  define G_BREAKPOINT()        G_STMT_START{ __asm int 3h }G_STMT_END
#elif defined (_MSC_VER)
#  define G_BREAKPOINT()        G_STMT_START{ __debugbreak(); }G_STMT_END
#elif defined (__alpha__) && !defined(__osf__) && defined (__GNUC__) && __GNUC__ >= 2
#  define G_BREAKPOINT()        G_STMT_START{ __asm__ __volatile__ ("bpt"); }G_STMT_END
#else   /* !__i386__ && !__alpha__ */
#  define G_BREAKPOINT()        G_STMT_START{ raise (SIGTRAP); }G_STMT_END
#endif  /* __i386__ */
'
i='#if (defined (__i386__) || defined (__x86_64__)) && defined (__GNUC__) && __GNUC__ >= 2
#elif (defined (_MSC_VER) || defined (__DMC__)) && defined (_M_IX86)
#  define G_BREAKPOINT()        G_STMT_START{ __asm int 3h }G_STMT_END
#elif defined (_MSC_VER)
#  define G_BREAKPOINT()        G_STMT_START{ __debugbreak(); }G_STMT_END
#elif defined (__alpha__) && !defined(__osf__) && defined (__GNUC__) && __GNUC__ >= 2
#  define G_BREAKPOINT()        G_STMT_START{ __asm__ __volatile__ ("bpt"); }G_STMT_END
#elif defined (__APPLE__)
#  define G_BREAKPOINT()        G_STMT_START{ __builtin_trap(); }G_STMT_END
#else   /* !__i386__ && !__alpha__ */
#  define G_BREAKPOINT()        G_STMT_START{ raise (SIGTRAP); }G_STMT_END
#endif  /* __i386__ */
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifdef __GNUC__

#define g_pointer_bit_lock(address, lock_bit) \
  (G_GNUC_EXTENSION ({                                                       \
    G_STATIC_ASSERT (sizeof *(address) == sizeof (gpointer));                \
    g_pointer_bit_lock ((address), (lock_bit));                              \
  }))

#define g_pointer_bit_trylock(address, lock_bit) \
  (G_GNUC_EXTENSION ({                                                       \
    G_STATIC_ASSERT (sizeof *(address) == sizeof (gpointer));                \
    g_pointer_bit_trylock ((address), (lock_bit));                           \
  }))

#define g_pointer_bit_unlock(address, lock_bit) \
  (G_GNUC_EXTENSION ({                                                       \
    G_STATIC_ASSERT (sizeof *(address) == sizeof (gpointer));                \
    g_pointer_bit_unlock ((address), (lock_bit));                            \
  }))

#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#if GLIB_SIZEOF_VOID_P > GLIB_SIZEOF_LONG
/**
 * G_MEM_ALIGN:
 *
 * Indicates the number of bytes to which memory will be aligned on the
 * current platform.
 */
#  define G_MEM_ALIGN	GLIB_SIZEOF_VOID_P
#else	/* GLIB_SIZEOF_VOID_P <= GLIB_SIZEOF_LONG */
#  define G_MEM_ALIGN	GLIB_SIZEOF_LONG
#endif	/* GLIB_SIZEOF_VOID_P <= GLIB_SIZEOF_LONG */
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define g_clear_pointer(pp, destroy) \
  G_STMT_START {                                                               \
    G_STATIC_ASSERT (sizeof *(pp) == sizeof (gpointer));                       \
    /* Only one access, please */                                              \
    gpointer *_pp = (gpointer *) (pp);                                         \
    gpointer _p;                                                               \
    /* This assignment is needed to avoid a gcc warning */                     \
    GDestroyNotify _destroy = (GDestroyNotify) (destroy);                      \
                                                                               \
    _p = *_pp;                                                                 \
    if (_p) 								       \
      { 								       \
        *_pp = NULL;							       \
        _destroy (_p);                                                         \
      }                                                                        \
  } G_STMT_END
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#if defined (__GNUC__) && (__GNUC__ >= 2) && defined (__OPTIMIZE__)
#  define _G_NEW(struct_type, n_structs, func) \
	(struct_type *) (G_GNUC_EXTENSION ({			\
	  gsize __n = (gsize) (n_structs);			\
	  gsize __s = sizeof (struct_type);			\
	  gpointer __p;						\
	  if (__s == 1)						\
	    __p = g_##func (__n);				\
	  else if (__builtin_constant_p (__n) &&		\
	           (__s == 0 || __n <= G_MAXSIZE / __s))	\
	    __p = g_##func (__n * __s);				\
	  else							\
	    __p = g_##func##_n (__n, __s);			\
	  __p;							\
	}))
#  define _G_RENEW(struct_type, mem, n_structs, func) \
	(struct_type *) (G_GNUC_EXTENSION ({			\
	  gsize __n = (gsize) (n_structs);			\
	  gsize __s = sizeof (struct_type);			\
	  gpointer __p = (gpointer) (mem);			\
	  if (__s == 1)						\
	    __p = g_##func (__p, __n);				\
	  else if (__builtin_constant_p (__n) &&		\
	           (__s == 0 || __n <= G_MAXSIZE / __s))	\
	    __p = g_##func (__p, __n * __s);			\
	  else							\
	    __p = g_##func##_n (__p, __n, __s);			\
	  __p;							\
	}))

#else

/* Unoptimised version: always call the _n() function. */

#define _G_NEW(struct_type, n_structs, func) \
        ((struct_type *) g_##func##_n ((n_structs), sizeof (struct_type)))
#define _G_RENEW(struct_type, mem, n_structs, func) \
        ((struct_type *) g_##func##_n (mem, (n_structs), sizeof (struct_type)))

#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

sed -i '/#define g_new0(struct_type, n_structs)			_G_NEW (struct_type, n_structs, malloc0)/d' $final
sed -i '/#define g_new(struct_type, n_structs)			_G_NEW (struct_type, n_structs, malloc)/d' $final
sed -i '/#define g_renew(struct_type, mem, n_structs)		_G_RENEW (struct_type, mem, n_structs, realloc)/d' $final
sed -i '/#define g_try_new(struct_type, n_structs)		_G_NEW (struct_type, n_structs, try_malloc)/d' $final
sed -i '/#define g_try_new0(struct_type, n_structs)		_G_NEW (struct_type, n_structs, try_malloc0)/d' $final
sed -i '/#define g_try_renew(struct_type, mem, n_structs)	_G_RENEW (struct_type, mem, n_structs, try_realloc)/d' $final
sed -i '/^GLIB_VAR .*;/d' $final

i='struct _GPollFD
{
#if defined (G_OS_WIN32) && GLIB_SIZEOF_VOID_P == 8
#ifndef __GTK_DOC_IGNORE__
  gint64	fd;
#endif
#else
  gint		fd;
#endif
  gushort 	events;
  gushort 	revents;
};
'
j='#if defined (G_OS_WIN32) && GLIB_SIZEOF_VOID_P == 8
struct _GPollFD
{
  gint64	fd;
  gushort 	events;
  gushort 	revents;
};
#else
struct _GPollFD
{
  gint		fd;
  gushort 	events;
  gushort 	revents;
};
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

i='typedef enum /*< flags >*/
{
  G_IO_IN	GLIB_SYSDEF_POLLIN,
  G_IO_OUT	GLIB_SYSDEF_POLLOUT,
  G_IO_PRI	GLIB_SYSDEF_POLLPRI,
  G_IO_ERR	GLIB_SYSDEF_POLLERR,
  G_IO_HUP	GLIB_SYSDEF_POLLHUP,
  G_IO_NVAL	GLIB_SYSDEF_POLLNVAL
} GIOCondition;
'
j='
#define GLIB_SYSDEF_POLLIN 1
#define GLIB_SYSDEF_POLLOUT 4
#define GLIB_SYSDEF_POLLPRI 2
#define GLIB_SYSDEF_POLLHUP 16
#define GLIB_SYSDEF_POLLERR 8
#define GLIB_SYSDEF_POLLNVAL 32

typedef enum /*< flags >*/
{
  G_IO_IN	= GLIB_SYSDEF_POLLIN,
  G_IO_PRI	= GLIB_SYSDEF_POLLPRI,
  G_IO_OUT	= GLIB_SYSDEF_POLLOUT,
  G_IO_ERR	= GLIB_SYSDEF_POLLERR,
  G_IO_HUP	= GLIB_SYSDEF_POLLHUP,
  G_IO_NVAL	= GLIB_SYSDEF_POLLNVAL
} GIOCondition;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final

# currently we have no support for va_list
i='GLIB_AVAILABLE_IN_ALL
GError*  g_error_new_valist    (GQuark         domain,
                                gint           code,
                                const gchar   *format,
                                va_list        args) G_GNUC_PRINTF(3, 0);
'
perl -0777 -p -i -e "s~\Q$i\E~#ifdef VALIST\n$i\n#endif\n~s" $final

i='GLIB_AVAILABLE_IN_ALL
gint                  g_vsnprintf          (gchar       *string,
					    gulong       n,
					    gchar const *format,
					    va_list      args)
					    G_GNUC_PRINTF(3, 0);
'
perl -0777 -p -i -e "s~\Q$i\E~#ifdef VALIST\n$i\n#endif\n~s" $final

i='GLIB_AVAILABLE_IN_ALL
void         g_string_vprintf           (GString         *string,
                                         const gchar     *format,
                                         va_list          args)
                                         G_GNUC_PRINTF(2, 0);
'
perl -0777 -p -i -e "s~\Q$i\E~#ifdef VALIST\n$i\n#endif\n~s" $final

i='GLIB_AVAILABLE_IN_ALL
void         g_string_append_vprintf    (GString         *string,
                                         const gchar     *format,
                                         va_list          args)
                                         G_GNUC_PRINTF(2, 0);
'
perl -0777 -p -i -e "s~\Q$i\E~#ifdef VALIST\n$i\n#endif\n~s" $final

i='GLIB_AVAILABLE_IN_ALL
gchar *g_markup_vprintf_escaped (const char *format,
				 va_list     args) G_GNUC_PRINTF(1, 0);
'
perl -0777 -p -i -e "s~\Q$i\E~#ifdef VALIST\n$i\n#endif\n~s" $final

i='GLIB_AVAILABLE_IN_ALL
gsize	g_printf_string_upper_bound (const gchar* format,
				     va_list	  args) G_GNUC_PRINTF(1, 0);
'
perl -0777 -p -i -e "s~\Q$i\E~#ifdef VALIST\n$i\n#endif\n~s" $final

i='GLIB_AVAILABLE_IN_ALL
void            g_logv                  (const gchar    *log_domain,
                                         GLogLevelFlags  log_level,
                                         const gchar    *format,
                                         va_list         args) G_GNUC_PRINTF(3, 0);
'
perl -0777 -p -i -e "s~\Q$i\E~#ifdef VALIST\n$i\n#endif\n~s" $final

i='GLIB_AVAILABLE_IN_ALL
gchar*	              g_strdup_vprintf (const gchar *format,
					va_list      args) G_GNUC_PRINTF(1, 0) G_GNUC_MALLOC;
'
perl -0777 -p -i -e "s~\Q$i\E~#ifdef VALIST\n$i\n#endif\n~s" $final

i='GLIB_AVAILABLE_IN_ALL
GVariant *                      g_variant_new_va                        (const gchar          *format_string,
                                                                         const gchar         **endptr,
                                                                         va_list              *app);
GLIB_AVAILABLE_IN_ALL
void                            g_variant_get_va                        (GVariant             *value,
                                                                         const gchar          *format_string,
                                                                         const gchar         **endptr,
                                                                         va_list              *app);
GLIB_AVAILABLE_IN_2_34
gboolean                        g_variant_check_format_string           (GVariant             *value,
                                                                         const gchar          *format_string,
                                                                         gboolean              copy_only);
'
perl -0777 -p -i -e "s~\Q$i\E~#ifdef VALIST\n$i\n#endif\n~s" $final

i='GLIB_AVAILABLE_IN_ALL
GVariant *                      g_variant_parse                         (const GVariantType   *type,
                                                                         const gchar          *text,
                                                                         const gchar          *limit,
                                                                         const gchar         **endptr,
                                                                         GError              **error);
GLIB_AVAILABLE_IN_ALL
GVariant *                      g_variant_new_parsed                    (const gchar          *format,
                                                                         ...);
GLIB_AVAILABLE_IN_ALL
GVariant *                      g_variant_new_parsed_va                 (const gchar          *format,
                                                                         va_list              *app);
'
perl -0777 -p -i -e "s~\Q$i\E~#ifdef VALIST\n$i\n#endif\n~s" $final

i="#if defined (G_HAVE_INLINE) && defined (__GNUC__) && defined (__STRICT_ANSI__)
#  undef inline
#  define inline __inline__
#elif !defined (G_HAVE_INLINE)
#  undef inline
#  if defined (G_HAVE___INLINE__)
#    define inline __inline__
#  elif defined (G_HAVE___INLINE)
#    define inline __inline
#  else /* !inline && !__inline__ && !__inline */
#    define inline  /* don't inline, then */
#  endif
#endif
#ifdef G_IMPLEMENT_INLINES
#  define G_INLINE_FUNC _GLIB_EXTERN
#  undef  G_CAN_INLINE
#elif defined (__GNUC__) 
#  define G_INLINE_FUNC static __inline __attribute__ ((unused))
#elif defined (G_CAN_INLINE) 
#  define G_INLINE_FUNC static inline
#else /* can't inline */
#  define G_INLINE_FUNC _GLIB_EXTERN
#endif /* !G_INLINE_FUNC */
"
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i="#ifndef G_DISABLE_DEPRECATED

/*
 * This macro is deprecated. This DllMain() is too complex. It is
 * recommended to write an explicit minimal DLlMain() that just saves
 * the handle to the DLL and then use that handle instead, for
 * instance passing it to
 * g_win32_get_package_installation_directory_of_module().
 *
 * On Windows, this macro defines a DllMain function that stores the
 * actual DLL name that the code being compiled will be included in.
 * STATIC should be empty or 'static'. DLL_NAME is the name of the
 * (pointer to the) char array where the DLL name will be stored. If
 * this is used, you must also include <windows.h>. If you need a more complex
 * DLL entry point function, you cannot use this.
 *
 * On non-Windows platforms, expands to nothing.
 */
"
perl -0777 -p -i -e "s~\Q$i\E~~s" $final
i='#ifndef G_PLATFORM_WIN32
# define G_WIN32_DLLMAIN_FOR_DLL_NAME(static, dll_name)
#else
# define G_WIN32_DLLMAIN_FOR_DLL_NAME(static, dll_name)			\
static char *dll_name;							\
									\
BOOL WINAPI								\
DllMain (HINSTANCE hinstDLL,						\
	 DWORD     fdwReason,						\
	 LPVOID    lpvReserved)						\
{									\
  wchar_t wcbfr[1000];							\
  char *tem;								\
  switch (fdwReason)							\
    {									\
    case DLL_PROCESS_ATTACH:						\
      GetModuleFileNameW ((HMODULE) hinstDLL, wcbfr, G_N_ELEMENTS (wcbfr)); \
      tem = g_utf16_to_utf8 (wcbfr, -1, NULL, NULL, NULL);		\
      dll_name = g_path_get_basename (tem);				\
      g_free (tem);							\
      break;								\
    }									\
									\
  return TRUE;								\
}

#endif	/* !G_DISABLE_DEPRECATED */

#endif /* G_PLATFORM_WIN32 */
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define  g_slice_new(type)      ((type*) g_slice_alloc (sizeof (type)))
#define  g_slice_new0(type)     ((type*) g_slice_alloc0 (sizeof (type)))
/* MemoryBlockType *
 *       g_slice_dup                    (MemoryBlockType,
 *	                                 MemoryBlockType *mem_block);
 *       g_slice_free                   (MemoryBlockType,
 *	                                 MemoryBlockType *mem_block);
 *       g_slice_free_chain             (MemoryBlockType,
 *                                       MemoryBlockType *first_chain_block,
 *                                       memory_block_next_field);
 * pseudo prototypes for the macro
 * definitions following below.
 */

/* we go through extra hoops to ensure type safety */
#define g_slice_dup(type, mem)                                  \
  (1 ? (type*) g_slice_copy (sizeof (type), (mem))              \
     : ((void) ((type*) 0 == (mem)), (type*) 0))
#define g_slice_free(type, mem)                                 \
G_STMT_START {                                                  \
  if (1) g_slice_free1 (sizeof (type), (mem));			\
  else   (void) ((type*) 0 == (mem)); 				\
} G_STMT_END
#define g_slice_free_chain(type, mem_chain, next)               \
G_STMT_START {                                                  \
  if (1) g_slice_free_chain_with_offset (sizeof (type),		\
                 (mem_chain), G_STRUCT_OFFSET (type, next)); 	\
  else   (void) ((type*) 0 == (mem_chain));			\
} G_STMT_END
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

# delete larger parts
i='/* assertion API */
#define g_assert_cmpstr(s1, cmp, s2)    G_STMT_START { \
                                             const char *__s1 = (s1), *__s2 = (s2); \
                                             if (g_strcmp0 (__s1, __s2) cmp 0) ; else \
                                               g_assertion_message_cmpstr (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, \
                                                 #s1 " " #cmp " " #s2, __s1, #cmp, __s2); \
                                        } G_STMT_END
'
perl -0777 -p -i -e "s~\Q$i\E~SalewskiDelStart\n~s" $final
i='#define g_assert(expr)                  G_STMT_START { \
                                             if G_LIKELY (expr) ; else \
                                               g_assertion_message_expr (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, \
                                                                         #expr); \
                                        } G_STMT_END
#endif /* !G_DISABLE_ASSERT */
'
perl -0777 -p -i -e "s~\Q$i\E~SalewskiDelEnd\n~s" $final
sed -i '/SalewskiDelStart/,/SalewskiDelEnd/d' $final

i="#if defined(G_HAVE_ISO_VARARGS) && !G_ANALYZER_ANALYZING
#ifdef G_LOG_USE_STRUCTURED
#define g_error(...)  G_STMT_START"
perl -0777 -p -i -e "s~\Q$i\E~SalewskiDelStart\n~s" $final
i="  va_end (args);
}
#endif  /* !__GNUC__ */
"
perl -0777 -p -i -e "s~\Q$i\E~SalewskiDelEnd\n~s" $final
sed -i '/SalewskiDelStart/,/SalewskiDelEnd/d' $final

i='#define g_warn_if_reached() \
  do { \
    g_warn_message (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, NULL); \
  } while (0)
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define g_warn_if_fail(expr) \
  do { \
    if G_LIKELY (expr) ; \
    else g_warn_message (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, #expr); \
  } while (0)
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i="#ifdef G_DISABLE_CHECKS

/\*\*
 \* g_return_if_fail:
 \* \@expr: the expression to check
 \*
 \* Verifies that the expression \@expr, usually representing a precondition,
"
perl -0777 -p -i -e "s~$i~\nSalewskiDelStart\n~s" $final
i='	    __LINE__,							\
	    G_STRFUNC);							\
     return (val);			}G_STMT_END

#endif /* !G_DISABLE_CHECKS */
'
perl -0777 -p -i -e "s~\Q$i\E~\nSalewskiDelEnd\n~s" $final
sed -i '/SalewskiDelStart/,/SalewskiDelEnd/d' $final

sed -i '/#define G_QUEUE_INIT { NULL, NULL, 0 }/d' $final

i='#ifndef G_DISABLE_DEPRECATED

/* keep downward source compatibility */
#define		g_scanner_add_symbol( scanner, symbol, value )	G_STMT_START { \
  g_scanner_scope_add_symbol ((scanner), 0, (symbol), (value)); \
} G_STMT_END
#define		g_scanner_remove_symbol( scanner, symbol )	G_STMT_START { \
  g_scanner_scope_remove_symbol ((scanner), 0, (symbol)); \
} G_STMT_END
#define		g_scanner_foreach_symbol( scanner, func, data )	G_STMT_START { \
  g_scanner_scope_foreach_symbol ((scanner), 0, (func), (data)); \
} G_STMT_END

/* The following two functions are deprecated and will be removed in
 * the next major release. They do no good. */
#define g_scanner_freeze_symbol_table(scanner) ((void)0)
#define g_scanner_thaw_symbol_table(scanner) ((void)0)

#endif /* G_DISABLE_DEPRECATED */

'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifndef G_DISABLE_DEPRECATED
  G_SPAWN_ERROR_2BIG = G_SPAWN_ERROR_TOO_BIG,
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define g_assert_cmpstr(s1, cmp, s2)    do { const char *__s1 = (s1), *__s2 = (s2); \
                                             if (g_strcmp0 (__s1, __s2) cmp 0) ; else \
                                               g_assertion_message_cmpstr (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, \
                                                 #s1 " " #cmp " " #s2, __s1, #cmp, __s2); } while (0)
'
perl -0777 -p -i -e "s~\Q$i\E~\nSalewskiDelStart\n~s" $final
i='#define g_assert_not_reached()          do { g_assertion_message_expr (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, NULL); } while (0)
#define g_assert(expr)                  do { if G_LIKELY (expr) ; else \
                                               g_assertion_message_expr (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, \
                                                                         #expr); \
                                           } while (0)
#endif /* !G_DISABLE_ASSERT */
'
perl -0777 -p -i -e "s~\Q$i\E~\nSalewskiDelEnd\n~s" $final
sed -i '/SalewskiDelStart/,/SalewskiDelEnd/d' $final

i='#define g_test_add(testpath, Fixture, tdata, fsetup, ftest, fteardown) \
					G_STMT_START {			\
                                         void (*add_vtable) (const char*,       \
                                                    gsize,             \
                                                    gconstpointer,     \
                                                    void (*) (Fixture*, gconstpointer),   \
                                                    void (*) (Fixture*, gconstpointer),   \
                                                    void (*) (Fixture*, gconstpointer)) =  (void (*) (const gchar *, gsize, gconstpointer, void (*) (Fixture*, gconstpointer), void (*) (Fixture*, gconstpointer), void (*) (Fixture*, gconstpointer))) g_test_add_vtable; \
                                         add_vtable \
                                          (testpath, sizeof (Fixture), tdata, fsetup, ftest, fteardown); \
					} G_STMT_END
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#define  g_test_trap_assert_passed()                      g_test_trap_assertions (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, 0, 0)
#define  g_test_trap_assert_failed()                      g_test_trap_assertions (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, 1, 0)
#define  g_test_trap_assert_stdout(soutpattern)           g_test_trap_assertions (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, 2, soutpattern)
#define  g_test_trap_assert_stdout_unmatched(soutpattern) g_test_trap_assertions (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, 3, soutpattern)
#define  g_test_trap_assert_stderr(serrpattern)           g_test_trap_assertions (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, 4, serrpattern)
#define  g_test_trap_assert_stderr_unmatched(serrpattern) g_test_trap_assertions (G_LOG_DOMAIN, __FILE__, __LINE__, G_STRFUNC, 5, serrpattern)
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

sed -i '/#define G_URI_RESERVED_CHARS_ALLOWED_IN_PATH_ELEMENT G_URI_RESERVED_CHARS_SUBCOMPONENT_DELIMITERS ":@"/d' $final
sed -i '/#define G_URI_RESERVED_CHARS_ALLOWED_IN_PATH G_URI_RESERVED_CHARS_ALLOWED_IN_PATH_ELEMENT "\/"/d' $final
sed -i '/#define G_URI_RESERVED_CHARS_ALLOWED_IN_USERINFO G_URI_RESERVED_CHARS_SUBCOMPONENT_DELIMITERS ":"/d' $final

# add missing {} for struct
sed -i 's/typedef struct _GThread         GThread;/typedef struct _GThread {} GThread;/g' $final
sed -i 's/typedef struct _GAsyncQueue GAsyncQueue;/typedef struct _GAsyncQueue {} GAsyncQueue;/g' $final
sed -i 's/typedef struct _GBookmarkFile GBookmarkFile;/typedef struct _GBookmarkFile {} GBookmarkFile;/g' $final
sed -i 's/typedef struct _GChecksum       GChecksum;/typedef struct _GChecksum {} GChecksum;/g' $final
sed -i 's/typedef struct _GData           GData;/typedef struct _GData {} GData;/g' $final
sed -i 's/typedef struct _GBytes          GBytes;/typedef struct _GBytes {} GBytes;/g' $final
sed -i 's/typedef struct _GTimeZone GTimeZone;/typedef struct _GTimeZone {} GTimeZone;/g' $final
sed -i 's/typedef struct _GDateTime GDateTime;/typedef struct _GDateTime {} GDateTime;/g' $final
sed -i 's/typedef struct _GDir GDir;/typedef struct _GDir {} GDir;/g' $final
sed -i 's/typedef struct _GHashTable  GHashTable;/typedef struct _GHashTable {} GHashTable;/g' $final
sed -i 's/typedef struct _GHmac       GHmac;/typedef struct _GHmac {} GHmac;/g' $final
sed -i 's/typedef struct _GMainContext            GMainContext;/typedef struct _GMainContext {} GMainContext;/g' $final
sed -i 's/typedef struct _GSourcePrivate          GSourcePrivate;/typedef struct _GSourcePrivate {} GSourcePrivate;/g' $final
sed -i 's/typedef struct _GMainLoop               GMainLoop;/typedef struct _GMainLoop {} GMainLoop;/g' $final
sed -i 's/typedef struct _GKeyFile GKeyFile;/typedef struct _GKeyFile {} GKeyFile;/g' $final
sed -i 's/typedef struct _GMappedFile GMappedFile;/typedef struct _GMappedFile {} GMappedFile;/g' $final
sed -i 's/typedef struct _GMarkupParseContext GMarkupParseContext;/typedef struct _GMarkupParseContext {} GMarkupParseContext;/g' $final
sed -i 's/typedef struct _GOptionContext GOptionContext;/typedef struct _GOptionContext {} GOptionContext;/g' $final
sed -i 's/typedef struct _GOptionGroup   GOptionGroup;/typedef struct _GOptionGroup {} GOptionGroup;/g' $final
sed -i 's/typedef struct _GPatternSpec    GPatternSpec;/typedef struct _GPatternSpec {} GPatternSpec;/g' $final
sed -i 's/typedef struct _GRand           GRand;/typedef struct _GRand {} GRand;/g' $final
sed -i 's/typedef struct _GMatchInfo	GMatchInfo;/typedef struct _GMatchInfo {}	GMatchInfo;/g' $final
sed -i 's/typedef struct _GRegex		GRegex;/typedef struct _GRegex {} GRegex;/g' $final
sed -i 's/typedef struct _GSequenceNode  GSequenceIter;/typedef struct _GSequenceIter {} GSequenceIter;/g' $final
sed -i 's/typedef struct _GSequence      GSequence;/typedef struct _GSequence {} GSequence;/g' $final
sed -i 's/typedef struct _GStringChunk GStringChunk;/typedef struct _GStringChunk {} GStringChunk;/g' $final
sed -i 's/typedef struct GTestCase  GTestCase;/typedef struct GTestCase {} GTestCase;/g' $final
sed -i 's/typedef struct GTestSuite GTestSuite;/typedef struct GTestSuite {} GTestSuite;/g' $final
sed -i 's/typedef struct _GTimer		GTimer;/typedef struct _GTimer {} GTimer;/g' $final
sed -i 's/typedef struct _GTree  GTree;/typedef struct _GTree {} GTree;/g' $final
sed -i 's/typedef struct _GVariantType GVariantType;/typedef struct _GVariantType {} GVariantType;/g' $final
sed -i 's/typedef struct _GVariant        GVariant;/typedef struct _GVariant {} GVariant;/g' $final

ruby ../fix_.rb $final

i='
#ifdef C2NIM
#  dynlib lib
#endif
'
perl -0777 -p -i -e "s/^/$i/" $final

i='#if !defined (__GLIB_H_INSIDE__) && !defined (__G_MAIN_H__) && !defined (GLIB_COMPILATION)
#error "Only <glib.h> can be included directly."
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifdef G_OS_UNIX
#include <dirent.h>
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#ifdef G_OS_UNIX
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='#if (__GNUC__ >= 3 || (__GNUC__ == 2 && __GNUC_MINOR__ >= 96))
#pragma GCC system_header
#endif
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

i='GLIB_AVAILABLE_IN_ALL
void         g_date_to_struct_tm          (const GDate *date,
                                           struct tm   *tm);
'
perl -0777 -p -i -e "s~\Q$i\E~~s" $final

# for GIConv a special notation is used in header file
i='
typedef struct _GIConv *GIConv;
'
j='
typedef struct _GICoSalewski {} GICoSalewski;
'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" $final
sed -i "s/GIConv/GIConv*/g" $final
sed -i "s/_GICoSalewski {} GICoSalewski;/_GIConv {} GIConv;/g" $final

sed -i '/#define  g_list_free1                   g_list_free_1/d' $final
sed -i '/#define	 g_slist_free1		         g_slist_free_1/d' $final

ruby ../fix_glib_error.rb final.h G_
sed -i 's/\bgchar\b/char/g' $final

sed -i '/#define G_VARIANT_BUILDER_INIT(variant_type) { { { 2942751021u, variant_type, { 0, } } } }/d' $final
sed -i '/#define G_VARIANT_DICT_INIT(asv) { { { asv, 3488698669u, { 0, } } } }/d' $final

c2nim --nep1 --skipcomments --skipinclude $final

sed -i 's/ {\.bycopy\.}//g' final.nim

i='type
  char* = char
  Gshort* = cshort
  Glong* = clong
  Gint* = cint
  Gboolean* = Gint
  Guchar* = cuchar
  Gushort* = cushort
  Gulong* = culong
  Guint* = cuint
  Gfloat* = cfloat
  Gdouble* = cdouble
'
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim

sed -i 's/\bG_CAN_INLINE\b/g_Can_Inline/g' final.nim

sed -i '/^when not defined(glib_H_Inside) and not defined(glib_Compilation):/d' final.nim
j="glib_H_Inside glib_Compilation VALIST cplusplus mingw_H stdlib_H G_DISABLE_DEPRECATED msc_Ver gnuc G_ATOMIC_OP_MEMORY_BARRIER_NEEDED __GTK_DOC_IGNORE__  G_DISABLE_CHECKS g_Can_Inline MINGW_H msc_Ver inc_Stdlib G_ENABLE_DEBUG"
for i in ${j}  ; do
 sed -i "s/\bdefined\((${i})\)/\U\1/g" final.nim
done

sed -i "s/__GTK_DOC_IGNORE__/GTK_DOC_IGNORE/g" final.nim
sed -i "s/_GLIB_TEST_OVERFLOW_FALLBACK/GLIB_TEST_OVERFLOW_FALLBACK/g" final.nim
sed -i "s/_GLIB_HAVE_BUILTIN_OVERFLOW_CHECKS/GLIB_HAVE_BUILTIN_OVERFLOW_CHECKS/g" final.nim

for i in glib_Sizeof_Void_P glib_Sysdef_Pollin glib_Sysdef_Pollpri glib_Sysdef_Pollout glib_Sysdef_Pollerr glib_Sysdef_Pollhup glib_Sysdef_Pollnval ; do
  sed -i "s/\b${i}\b/\U&/g" final.nim
done

# we use our own defined pragma
sed -i "s/\bdynlib: lib\b/libglib/g" final.nim

# for time_t see http://stackoverflow.com/questions/471248/what-is-ultimately-a-time-t-typedef-to
i=' {.deadCodeElim: on.}
'
j='{.deadCodeElim: on.}

# Note: Not all glib C macros are available in Nim yet.
# Some are converted by c2nim to templates, some manually to procs.
# Most of these should be not necessary for Nim programmers.
# We may have to add more and to test and fix some, or remove unnecessary ones completely...

from times import Time

export Time

when defined(windows):
  const LIB_GLIB* = "libglib-2.0-0.dll"
elif defined(macosx):
  const LIB_GLIB* = "libglib-2.0.dylib"
else:
  const LIB_GLIB* = "libglib-2.0.so(|.0)"

{.pragma: libglib, cdecl, dynlib: LIB_GLIB.}

const
  GLIB_H_INSIDE = true
  GLIB_COMPILATION = false
  VALIST = false
  CPLUSPLUS = false
  MINGW_H = false
  STDLIB_H = true
  G_DISABLE_DEPRECATED = false
  MSC_VER = false
  G_ATOMIC_OP_MEMORY_BARRIER_NEEDED = false
  GTK_DOC_IGNORE = false
  G_DISABLE_CHECKS = true
  G_CAN_INLINE = false
  INC_STDLIB = false
  G_ENABLE_DEBUG = false

type
  Gboolean* = distinct cint
  QQQGint* = cint # glib aliases which are not really needed
  QQQGuint* = cuint
  QQQGshort* = cshort
  QQQGushort* = cushort
  QQQGlong* = clong
  QQQGulong* = culong
  QQQGchar* = cchar
  QQQGuchar* = cuchar
  QQQGfloat* = cfloat
  QQQGdouble* = cdouble

# we should not need these constants often, because we have converters to and from Nim bool
const
  GFALSE* = Gboolean(0)
  GTRUE* = Gboolean(1)

converter gbool*(nimbool: bool): Gboolean =
  ord(nimbool).Gboolean

converter toBool*(gbool: Gboolean): bool =
  int(gbool) != 0

const
  G_MAXUINT* = high(cuint)
  G_MAXUSHORT* = high(cushort)
  GLIB_SIZEOF_VOID_P = sizeof(pointer)
  GLIB_SIZEOF_SIZE_T* = GLIB_SIZEOF_VOID_P
  GLIB_SIZEOF_LONG* = sizeof(clong)
type
  Gssize* = csize
  Gsize* = csize # note: csize is signed in Nim!
  Goffset* = int64
  GPid = cint

{.warning[SmallLshouldNotBeUsed]: off.}

'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i="const
  G_MININT8* = ((gint8) - 0x00000080)
  G_MAXINT8* = (cast[Gint8](0x0000007F))
  G_MAXUINT8* = (cast[Guint8](0x000000FF))
  G_MININT16* = ((gint16) - 0x00008000)
  G_MAXINT16* = (cast[Gint16](0x00007FFF))
  G_MAXUINT16* = (cast[Guint16](0x0000FFFF))
  G_MININT32* = ((gint32) - 0x80000000)
  G_MAXINT32* = (cast[Gint32](0x7FFFFFFF))
  G_MAXUINT32* = (cast[Guint32](0xFFFFFFFF))
  G_MININT64* = (cast[Gint64](g_Gint64Constant(- 0x8000000000000000'i64)))
  G_MAXINT64* = g_Gint64Constant(0x7FFFFFFFFFFFFFFF'i64)
  G_MAXUINT64* = g_Guint64Constant(0xFFFFFFFFFFFFFFFF'i64)
"
j="const
  G_MININT8* = 0x00000080'i8
  G_MAXINT8* = 0x0000007F'i8
  G_MAXUINT8* = 0x000000FF'u8
  G_MININT16* = 0x00008000'i16
  G_MAXINT16* = 0x00007FFF'i16
  G_MAXUINT16* = 0x0000FFFF'u16
  G_MININT32* = 0x80000000'i32
  G_MAXINT32* = 0x7FFFFFFF'i32
  G_MAXUINT32* = 0xFFFFFFFF'u32
  G_MININT64* = 0x8000000000000000'i64
  G_MAXINT64* = 0x7FFFFFFFFFFFFFFF'i64
  G_MAXUINT64* = 0xFFFFFFFFFFFFFFFF'u64
"
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

sed -i "s/(g_Gint64Constant(/(int64(/g" final.nim

i='type
  GTraverseFlags* {.size: sizeof(cint).} = enum
    G_TRAVERSE_LEAVES = 1 shl 0, G_TRAVERSE_NON_LEAVES = 1 shl 1,
    G_TRAVERSE_ALL = g_Traverse_Leaves or g_Traverse_Non_Leaves,
    G_TRAVERSE_MASK = 0x00000003, G_TRAVERSE_LEAFS = g_Traverse_Leaves,
    G_TRAVERSE_NON_LEAFS = g_Traverse_Non_Leaves
'
j='type
  GTraverseFlags* {.size: sizeof(cint).} = enum
    G_TRAVERSE_LEAVES = 1 shl 0, G_TRAVERSE_NON_LEAVES = 1 shl 1,
    G_TRAVERSE_ALL = GTraverseFlags.LEAVES.ord or GTraverseFlags.NON_LEAVES.ord
const
  G_TRAVERSE_MASK = GTraverseFlags.ALL
  G_TRAVERSE_LEAFS = GTraverseFlags.LEAVES
  G_TRAVERSE_NON_LEAFS = GTraverseFlags.NON_LEAVES
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GNormalizeMode* {.size: sizeof(cint).} = enum
    G_NORMALIZE_DEFAULT, G_NORMALIZE_NFD = g_Normalize_Default,
    G_NORMALIZE_DEFAULT_COMPOSE, G_NORMALIZE_NFC = g_Normalize_Default_Compose,
    G_NORMALIZE_ALL, G_NORMALIZE_NFKD = g_Normalize_All, G_NORMALIZE_ALL_COMPOSE,
    G_NORMALIZE_NFKC = g_Normalize_All_Compose
'
j='type
  GNormalizeMode* {.size: sizeof(cint).} = enum
    G_NORMALIZE_DEFAULT,
    G_NORMALIZE_DEFAULT_COMPOSE,
    G_NORMALIZE_ALL,
    G_NORMALIZE_ALL_COMPOSE
const
  G_NORMALIZE_NFD = GNormalizeMode.DEFAULT
  G_NORMALIZE_NFC = GNormalizeMode.DEFAULT_COMPOSE
  G_NORMALIZE_NFKD = GNormalizeMode.ALL
  G_NORMALIZE_NFKC = GNormalizeMode.ALL_COMPOSE
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='  GIOFlags* {.size: sizeof(cint).} = enum
    G_IO_FLAG_APPEND = 1 shl 0, G_IO_FLAG_NONBLOCK = 1 shl 1,
    G_IO_FLAG_IS_READABLE = 1 shl 2, G_IO_FLAG_IS_WRITABLE = 1 shl 3,
    G_IO_FLAG_IS_WRITEABLE = 1 shl 3, G_IO_FLAG_IS_SEEKABLE = 1 shl 4,
    G_IO_FLAG_MASK = (1 shl 5) - 1, G_IO_FLAG_GET_MASK = g_Io_Flag_Mask,
    G_IO_FLAG_SET_MASK = g_Io_Flag_Append or g_Io_Flag_Nonblock

'
j='  GIOFlags* {.size: sizeof(cint).} = enum
    G_IO_FLAG_APPEND = 1 shl 0, G_IO_FLAG_NONBLOCK = 1 shl 1,
    G_IO_FLAG_SET_MASK = GIOFlags.APPEND.ord or GIOFlags.NONBLOCK.ord,
    G_IO_FLAG_IS_READABLE = 1 shl 2, G_IO_FLAG_IS_WRITABLE = 1 shl 3,
    G_IO_FLAG_IS_SEEKABLE = 1 shl 4,
    G_IO_FLAG_MASK = (1 shl 5) - 1
const
  G_IO_FLAG_GET_MASK = GIOFlags.MASK
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GLogLevelFlags* {.size: sizeof(cint).} = enum
    G_LOG_FLAG_RECURSION = 1 shl 0, G_LOG_FLAG_FATAL = 1 shl 1,
    G_LOG_LEVEL_ERROR = 1 shl 2, G_LOG_LEVEL_CRITICAL = 1 shl 3,
    G_LOG_LEVEL_WARNING = 1 shl 4, G_LOG_LEVEL_MESSAGE = 1 shl 5,
    G_LOG_LEVEL_INFO = 1 shl 6, G_LOG_LEVEL_DEBUG = 1 shl 7,
    G_LOG_LEVEL_MASK = not (g_Log_Flag_Recursion or g_Log_Flag_Fatal)



const
  G_LOG_FATAL_MASK* = (g_Log_Flag_Recursion or g_Log_Level_Error)
'
j='type
  GLogLevelFlags* {.size: sizeof(cint).} = enum
    MASK = not(3)
    FLAG_RECURSION = 1 shl 0, FLAG_FATAL = 1 shl 1,
    LEVEL_ERROR = 1 shl 2,
    FATAL_MASK = GLogLevelFlags.FLAG_RECURSION.ord or GLogLevelFlags.LEVEL_ERROR.ord
    LEVEL_CRITICAL = 1 shl 3,
    LEVEL_WARNING = 1 shl 4, LEVEL_MESSAGE = 1 shl 5,
    LEVEL_INFO = 1 shl 6, LEVEL_DEBUG = 1 shl 7
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GRegexCompileFlags* {.size: sizeof(cint).} = enum
    G_REGEX_CASELESS = 1 shl 0, G_REGEX_MULTILINE = 1 shl 1, G_REGEX_DOTALL = 1 shl 2,
    G_REGEX_EXTENDED = 1 shl 3, G_REGEX_ANCHORED = 1 shl 4,
    G_REGEX_DOLLAR_ENDONLY = 1 shl 5, G_REGEX_UNGREEDY = 1 shl 9, G_REGEX_RAW = 1 shl 11,
    G_REGEX_NO_AUTO_CAPTURE = 1 shl 12, G_REGEX_OPTIMIZE = 1 shl 13,
    G_REGEX_FIRSTLINE = 1 shl 18, G_REGEX_DUPNAMES = 1 shl 19,
    G_REGEX_NEWLINE_CR = 1 shl 20, G_REGEX_NEWLINE_LF = 1 shl 21,
    G_REGEX_NEWLINE_CRLF = g_Regex_Newline_Cr or g_Regex_Newline_Lf,
    G_REGEX_NEWLINE_ANYCRLF = g_Regex_Newline_Cr or 1 shl 22,
    G_REGEX_BSR_ANYCRLF = 1 shl 23, G_REGEX_JAVASCRIPT_COMPAT = 1 shl 25
'
j='type
  GRegexCompileFlags* {.size: sizeof(cint).} = enum
    G_REGEX_CASELESS = 1 shl 0, G_REGEX_MULTILINE = 1 shl 1, G_REGEX_DOTALL = 1 shl 2,
    G_REGEX_EXTENDED = 1 shl 3, G_REGEX_ANCHORED = 1 shl 4,
    G_REGEX_DOLLAR_ENDONLY = 1 shl 5, G_REGEX_UNGREEDY = 1 shl 9, G_REGEX_RAW = 1 shl 11,
    G_REGEX_NO_AUTO_CAPTURE = 1 shl 12, G_REGEX_OPTIMIZE = 1 shl 13,
    G_REGEX_FIRSTLINE = 1 shl 18, G_REGEX_DUPNAMES = 1 shl 19,
    G_REGEX_NEWLINE_CR = 1 shl 20, G_REGEX_NEWLINE_LF = 1 shl 21,
    G_REGEX_NEWLINE_CRLF = GRegexCompileFlags.Newline_Cr.ord or GRegexCompileFlags.Newline_Lf.ord,
    G_REGEX_NEWLINE_ANYCRLF = GRegexCompileFlags.Newline_Cr.ord or 1 shl 22,
    G_REGEX_BSR_ANYCRLF = 1 shl 23, G_REGEX_JAVASCRIPT_COMPAT = 1 shl 25
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GRegexMatchFlags* {.size: sizeof(cint).} = enum
    G_REGEX_MATCH_ANCHORED = 1 shl 4, G_REGEX_MATCH_NOTBOL = 1 shl 7,
    G_REGEX_MATCH_NOTEOL = 1 shl 8, G_REGEX_MATCH_NOTEMPTY = 1 shl 10,
    G_REGEX_MATCH_PARTIAL = 1 shl 15, G_REGEX_MATCH_NEWLINE_CR = 1 shl 20,
    G_REGEX_MATCH_NEWLINE_LF = 1 shl 21, G_REGEX_MATCH_NEWLINE_CRLF = g_Regex_Match_Newline_Cr or
        g_Regex_Match_Newline_Lf, G_REGEX_MATCH_NEWLINE_ANY = 1 shl 22, G_REGEX_MATCH_NEWLINE_ANYCRLF = g_Regex_Match_Newline_Cr or
        g_Regex_Match_Newline_Any, G_REGEX_MATCH_BSR_ANYCRLF = 1 shl 23,
    G_REGEX_MATCH_BSR_ANY = 1 shl 24,
    G_REGEX_MATCH_PARTIAL_SOFT = g_Regex_Match_Partial,
    G_REGEX_MATCH_PARTIAL_HARD = 1 shl 27, G_REGEX_MATCH_NOTEMPTY_ATSTART = 1 shl 28
'
j='type
  GRegexMatchFlags* {.size: sizeof(cint).} = enum
    G_REGEX_MATCH_ANCHORED = 1 shl 4, G_REGEX_MATCH_NOTBOL = 1 shl 7,
    G_REGEX_MATCH_NOTEOL = 1 shl 8, G_REGEX_MATCH_NOTEMPTY = 1 shl 10,
    G_REGEX_MATCH_PARTIAL = 1 shl 15, G_REGEX_MATCH_NEWLINE_CR = 1 shl 20,
    G_REGEX_MATCH_NEWLINE_LF = 1 shl 21,
    G_REGEX_MATCH_NEWLINE_CRLF = (GRegexMatchFlags.Newline_Cr.ord or GRegexMatchFlags.Newline_Lf.ord)
    G_REGEX_MATCH_NEWLINE_ANY = 1 shl 22,
    G_REGEX_MATCH_NEWLINE_ANYCRLF = (GRegexMatchFlags.Newline_Cr.ord or GRegexMatchFlags.Newline_Any.ord)
    G_REGEX_MATCH_BSR_ANYCRLF = 1 shl 23,
    G_REGEX_MATCH_BSR_ANY = 1 shl 24,
    G_REGEX_MATCH_PARTIAL_HARD = 1 shl 27, G_REGEX_MATCH_NOTEMPTY_ATSTART = 1 shl 28

const
  G_REGEX_MATCH_PARTIAL_SOFT = GRegexMatchFlags.PARTIAL
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i="type
  GTokenType* {.size: sizeof(cint).} = enum
    G_TOKEN_EOF = 0, G_TOKEN_LEFT_PAREN = '(', G_TOKEN_RIGHT_PAREN = ')',
    G_TOKEN_LEFT_CURLY = '{', G_TOKEN_RIGHT_CURLY = '}', G_TOKEN_LEFT_BRACE = '[',
    G_TOKEN_RIGHT_BRACE = ']', G_TOKEN_EQUAL_SIGN = '=', G_TOKEN_COMMA = ',',
    G_TOKEN_NONE = 256, G_TOKEN_ERROR, G_TOKEN_CHAR, G_TOKEN_BINARY, G_TOKEN_OCTAL,
    G_TOKEN_INT, G_TOKEN_HEX, G_TOKEN_FLOAT, G_TOKEN_STRING, G_TOKEN_SYMBOL,
    G_TOKEN_IDENTIFIER, G_TOKEN_IDENTIFIER_NULL, G_TOKEN_COMMENT_SINGLE,
    G_TOKEN_COMMENT_MULTI, G_TOKEN_LAST
"
j="type
  GTokenType* {.size: sizeof(cint).} = enum
    G_TOKEN_EOF = 0, G_TOKEN_LEFT_PAREN = '(', G_TOKEN_RIGHT_PAREN = ')',
    G_TOKEN_COMMA = ',',
    G_TOKEN_EQUAL_SIGN = '=',
    G_TOKEN_LEFT_BRACE = '[', G_TOKEN_RIGHT_BRACE = ']',
    G_TOKEN_LEFT_CURLY = '{', G_TOKEN_RIGHT_CURLY = '}',
    G_TOKEN_NONE = 256,
    G_TOKEN_ERROR, G_TOKEN_CHAR, G_TOKEN_BINARY, G_TOKEN_OCTAL, G_TOKEN_INT,
    G_TOKEN_HEX, G_TOKEN_FLOAT, G_TOKEN_STRING, G_TOKEN_SYMBOL,
    G_TOKEN_IDENTIFIER, G_TOKEN_IDENTIFIER_NULL, G_TOKEN_COMMENT_SINGLE,
    G_TOKEN_COMMENT_MULTI, G_TOKEN_LAST
"
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i="  GVariantClass* {.size: sizeof(cint).} = enum
    G_VARIANT_CLASS_BOOLEAN = 'b', G_VARIANT_CLASS_BYTE = 'y',
    G_VARIANT_CLASS_INT16 = 'n', G_VARIANT_CLASS_UINT16 = 'q',
    G_VARIANT_CLASS_INT32 = 'i', G_VARIANT_CLASS_UINT32 = 'u',
    G_VARIANT_CLASS_INT64 = 'x', G_VARIANT_CLASS_UINT64 = 't',
    G_VARIANT_CLASS_HANDLE = 'h', G_VARIANT_CLASS_DOUBLE = 'd',
    G_VARIANT_CLASS_STRING = 's', G_VARIANT_CLASS_OBJECT_PATH = 'o',
    G_VARIANT_CLASS_SIGNATURE = 'g', G_VARIANT_CLASS_VARIANT = 'v',
    G_VARIANT_CLASS_MAYBE = 'm', G_VARIANT_CLASS_ARRAY = 'a',
    G_VARIANT_CLASS_TUPLE = '(', G_VARIANT_CLASS_DICT_ENTRY = '{'
"
j="  GVariantClass* {.size: sizeof(cint).} = enum
    G_VARIANT_CLASS_TUPLE = '(',
    G_VARIANT_CLASS_ARRAY = 'a',
    G_VARIANT_CLASS_BOOLEAN = 'b',
    G_VARIANT_CLASS_DOUBLE = 'd',
    G_VARIANT_CLASS_SIGNATURE = 'g',
    G_VARIANT_CLASS_HANDLE = 'h',
    G_VARIANT_CLASS_INT32 = 'i',
    G_VARIANT_CLASS_MAYBE = 'm',
    G_VARIANT_CLASS_INT16 = 'n',
    G_VARIANT_CLASS_OBJECT_PATH = 'o',
    G_VARIANT_CLASS_UINT16 = 'q',
    G_VARIANT_CLASS_STRING = 's',
    G_VARIANT_CLASS_UINT64 = 't',
    G_VARIANT_CLASS_UINT32 = 'u',
    G_VARIANT_CLASS_VARIANT = 'v',
    G_VARIANT_CLASS_INT64 = 'x',
    G_VARIANT_CLASS_BYTE = 'y',
    G_VARIANT_CLASS_DICT_ENTRY = '{'
"
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GChildWatchFunc* = proc (pid: GPid; status: Gint; userData: Gpointer)
  GSource* = object
    callbackData*: Gpointer
    callbackFuncs*: ptr GSourceCallbackFuncs
    sourceFuncs*: ptr GSourceFuncs
    refCount*: Guint
    context*: ptr GMainContext
    priority*: Gint
    flags*: Guint
    sourceId*: Guint
    pollFds*: ptr GSList
    prev*: ptr GSource
    next*: ptr GSource
    name*: cstring
    priv*: ptr GSourcePrivate

  GSourceCallbackFuncs* = object
    `ref`*: proc (cbData: Gpointer)
    unref*: proc (cbData: Gpointer)
    get*: proc (cbData: Gpointer; source: ptr GSource; `func`: ptr GSourceFunc;
              data: ptr Gpointer)



type
  GSourceDummyMarshal* = proc ()
  GSourceFuncs* = object
    prepare*: proc (source: ptr GSource; timeout: ptr Gint): Gboolean
    check*: proc (source: ptr GSource): Gboolean
    dispatch*: proc (source: ptr GSource; callback: GSourceFunc; userData: Gpointer): Gboolean
    finalize*: proc (source: ptr GSource)
    closureCallback*: GSourceFunc
    closureMarshal*: GSourceDummyMarshal
'
j='type
  GChildWatchFunc* = proc (pid: GPid; status: Gint; userData: Gpointer)
  GSource* = object
    callbackData*: Gpointer
    callbackFuncs*: ptr GSourceCallbackFuncs
    sourceFuncs*: ptr GSourceFuncs
    refCount*: Guint
    context*: ptr GMainContext
    priority*: Gint
    flags*: Guint
    sourceId*: Guint
    pollFds*: ptr GSList
    prev*: ptr GSource
    next*: ptr GSource
    name*: cstring
    priv*: ptr GSourcePrivate

  GSourceCallbackFuncs* = object
    `ref`*: proc (cbData: Gpointer)
    unref*: proc (cbData: Gpointer)
    get*: proc (cbData: Gpointer; source: ptr GSource; `func`: ptr GSourceFunc;
              data: ptr Gpointer)

#type
  GSourceDummyMarshal* = proc ()
  GSourceFuncs* = object
    prepare*: proc (source: ptr GSource; timeout: ptr Gint): Gboolean
    check*: proc (source: ptr GSource): Gboolean
    dispatch*: proc (source: ptr GSource; callback: GSourceFunc; userData: Gpointer): Gboolean
    finalize*: proc (source: ptr GSource)
    closureCallback*: GSourceFunc
    closureMarshal*: GSourceDummyMarshal
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

sed -i 's/    G_HOOK_FLAG_MASK = 0x0000000F/    G_HOOK_FLAG_MSK = 0x0000000F/g' final.nim

i='const
  G_CSET_A_2_Z* = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  G_CSET_a2Z* = "abcdefghijklmnopqrstuvwxyz"
'
j='const
  G_CSET_A_2_Z_U* = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  G_CSET_a_2_Z_L* = "abcdefghijklmnopqrstuvwxyz"
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='when not (G_DISABLE_DEPRECATED):
  const
    gDirname* = gPathGetDirname
proc gGetCurrentDir*(): cstring {.importc: "g_get_current_dir", libglib.}
proc gPathGetBasename*(fileName: cstring): cstring {.importc: "g_path_get_basename",
    libglib.}
proc gPathGetDirname*(fileName: cstring): cstring {.importc: "g_path_get_dirname",
    libglib.}
'
j='proc gGetCurrentDir*(): cstring {.importc: "g_get_current_dir", libglib.}
proc gPathGetBasename*(fileName: cstring): cstring {.importc: "g_path_get_basename",
    libglib.}
proc gPathGetDirname*(fileName: cstring): cstring {.importc: "g_path_get_dirname",
    libglib.}
when not (G_DISABLE_DEPRECATED):
  const
    gDirname* = pathGetDirname
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GHookCompareFunc* = proc (newHook: ptr GHook; sibling: ptr GHook): Gint
  GHookFindFunc* = proc (hook: ptr GHook; data: Gpointer): Gboolean
  GHookMarshaller* = proc (hook: ptr GHook; marshalData: Gpointer)
  GHookCheckMarshaller* = proc (hook: ptr GHook; marshalData: Gpointer): Gboolean
  GHookFunc* = proc (data: Gpointer)
  GHookCheckFunc* = proc (data: Gpointer): Gboolean
  GHookFinalizeFunc* = proc (hookList: ptr GHookList; hook: ptr GHook)
  GHookFlagMask* {.size: sizeof(cint).} = enum
    G_HOOK_FLAG_ACTIVE = 1 shl 0, G_HOOK_FLAG_IN_CALL = 1 shl 1,
    G_HOOK_FLAG_MSK = 0x0000000F


const
  G_HOOK_FLAG_USER_SHIFT* = (4)


type
  GHookList* = object
'
j='const
  G_HOOK_FLAG_USER_SHIFT* = (4)

type
  GHookCompareFunc* = proc (newHook: ptr GHook; sibling: ptr GHook): Gint
  GHookFindFunc* = proc (hook: ptr GHook; data: Gpointer): Gboolean
  GHookMarshaller* = proc (hook: ptr GHook; marshalData: Gpointer)
  GHookCheckMarshaller* = proc (hook: ptr GHook; marshalData: Gpointer): Gboolean
  GHookFunc* = proc (data: Gpointer)
  GHookCheckFunc* = proc (data: Gpointer): Gboolean
  GHookFinalizeFunc* = proc (hookList: ptr GHookList; hook: ptr GHook)
  GHookFlagMask* {.size: sizeof(cint).} = enum
    G_HOOK_FLAG_ACTIVE = 1 shl 0, G_HOOK_FLAG_IN_CALL = 1 shl 1,
    G_HOOK_FLAG_MSK = 0x0000000F

#type
  GHookList* = object
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GPollFunc* = proc (ufds: ptr GPollFD; nfsd: Guint; timeout: Gint): Gint


when defined(g_Os_Win32) and GLIB_SIZEOF_VOID_P == 8:
  type
    GPollFD* = object
      fd*: Gint64
      events*: Gushort
      revents*: Gushort

else:
  type
    GPollFD* = object
      fd*: Gint
      events*: Gushort
      revents*: Gushort
'
j='when defined(g_Os_Win32) and GLIB_SIZEOF_VOID_P == 8:
  type
    GPollFD* = object
      fd*: Gint64
      events*: Gushort
      revents*: Gushort

else:
  type
    GPollFD* = object
      fd*: Gint
      events*: Gushort
      revents*: Gushort

type
  GPollFunc* = proc (ufds: ptr GPollFD; nfsd: Guint; timeout: Gint): Gint
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GSourceFunc* = proc (userData: Gpointer): Gboolean


type
  GChildWatchFunc* = proc (pid: GPid; status: Gint; userData: Gpointer)
  GSource* = object
    callbackData*: Gpointer
    callbackFuncs*: ptr GSourceCallbackFuncs
    sourceFuncs*: ptr GSourceFuncs
    refCount*: Guint
    context*: ptr GMainContext
    priority*: Gint
    flags*: Guint
    sourceId*: Guint
    pollFds*: ptr GSList
    prev*: ptr GSource
    next*: ptr GSource
    name*: cstring
    priv*: ptr GSourcePrivate

  GSourceCallbackFuncs* = object
    `ref`*: proc (cbData: Gpointer)
    unref*: proc (cbData: Gpointer)
    get*: proc (cbData: Gpointer; source: ptr GSource; `func`: ptr GSourceFunc;
              data: ptr Gpointer)



type
  GSourceDummyMarshal* = proc ()
  GSourceFuncs* = object
    prepare*: proc (source: ptr GSource; timeout: ptr Gint): Gboolean
    check*: proc (source: ptr GSource): Gboolean
    dispatch*: proc (source: ptr GSource; callback: GSourceFunc; userData: Gpointer): Gboolean
    finalize*: proc (source: ptr GSource)
    closureCallback*: GSourceFunc
    closureMarshal*: GSourceDummyMarshal

'
j='type
  GSourceFunc* = proc (userData: Gpointer): Gboolean

#type
  GChildWatchFunc* = proc (pid: GPid; status: Gint; userData: Gpointer)
  GSource* = object
    callbackData*: Gpointer
    callbackFuncs*: ptr GSourceCallbackFuncs
    sourceFuncs*: ptr GSourceFuncs
    refCount*: Guint
    context*: ptr GMainContext
    priority*: Gint
    flags*: Guint
    sourceId*: Guint
    pollFds*: ptr GSList
    prev*: ptr GSource
    next*: ptr GSource
    name*: cstring
    priv*: ptr GSourcePrivate

  GSourceCallbackFuncs* = object
    `ref`*: proc (cbData: Gpointer)
    unref*: proc (cbData: Gpointer)
    get*: proc (cbData: Gpointer; source: ptr GSource; `func`: ptr GSourceFunc;
              data: ptr Gpointer)

#type
  GSourceDummyMarshal* = proc ()
  GSourceFuncs* = object
    prepare*: proc (source: ptr GSource; timeout: ptr Gint): Gboolean
    check*: proc (source: ptr GSource): Gboolean
    dispatch*: proc (source: ptr GSource; callback: GSourceFunc; userData: Gpointer): Gboolean
    finalize*: proc (source: ptr GSource)
    closureCallback*: GSourceFunc
    closureMarshal*: GSourceDummyMarshal
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='when not (G_DISABLE_DEPRECATED):
  const
    G_UNICODE_COMBINING_MARK* = g_Unicode_Spacing_Mark
'
j='when not (G_DISABLE_DEPRECATED):
  const
    G_UNICODE_COMBINING_MARK* = GUnicodeType.SPACING_MARK
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GCopyFunc* = proc (src: Gconstpointer; data: Gpointer): Gpointer


type
'
j='#type
  GCopyFunc* = proc (src: Gconstpointer; data: Gpointer): Gpointer

#type
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='type
  GScannerMsgFunc* = proc (scanner: ptr GScanner; message: cstring; error: Gboolean)
'
perl -0777 -p -i -e "s/\Q$i\E//s" final.nim
j='
  GScanner* = object
    userData*: Gpointer
    maxParseErrors*: Guint
    parseErrors*: Guint
    inputName*: cstring
    qdata*: ptr GData
    config*: ptr GScannerConfig
    token*: GTokenType
    value*: GTokenValue
    line*: Guint
    position*: Guint
    nextToken*: GTokenType
    nextValue*: GTokenValue
    nextLine*: Guint
    nextPosition*: Guint
    symbolTable*: ptr GHashTable
    inputFd*: Gint
    text*: cstring
    textEnd*: cstring
    buffer*: cstring
    scopeId*: Guint
    msgHandler*: GScannerMsgFunc
'
i='#type
  GScannerMsgFunc* = proc (scanner: ptr GScanner; message: cstring; error: Gboolean)
'
perl -0777 -p -i -e "s/\Q$j\E/$j$i/s" final.nim

sed -i 's/when defined(G_OS_UNIX):/when defined(unix): /g' final.nim

ruby ../glib_fix_proc.rb final.nim
ruby ../fix_template.rb final.nim ""
ruby ../glib_fix_T.rb final.nim glib ""
sed -i 's/ G_OPTION_FLAG_/ G_OPTION_FLAGS_/g' final.nim
sed -i 's/ G_IO_FLAG_/ G_IO_FLAGS_/g' final.nim
sed -i 's/ G_ERR_/ G_ERROR_TYPE_/g' final.nim
ruby ../glib_fix_enum_prefix.rb final.nim

sed -i 's/\bproc type\b/proc `type`/g' final.nim
sed -i 's/^proc ref\*(/proc `ref`\*(/g' final.nim
sed -i 's/^proc end\*(/proc `end`\*(/g' final.nim
sed -i 's/^proc continue\*(/proc `continue`\*(/g' final.nim

i='
  const
    gDateWeekday* = gDateGetWeekday
    gDateMonth* = gDateGetMonth
    gDateYear* = gDateGetYear
    gDateDay* = gDateGetDay
    gDateJulian* = gDateGetJulian
    gDateDayOfYear* = gDateGetDayOfYear
    gDateMondayWeekOfYear* = gDateGetMondayWeekOfYear
    gDateSundayWeekOfYear* = gDateGetSundayWeekOfYear
    gDateDaysInMonth* = gDateGetDaysInMonth
    gDateMondayWeeksInYear* = gDateGetMondayWeeksInYear
    gDateSundayWeeksInYear* = gDateGetSundayWeeksInYear
'
j='
  const
    gDateWeekday* = getWeekday
    gDateMonth* = getMonth
    gDateYear* = getYear
    gDateDay* = getDay
    gDateJulian* = getJulian
    gDateDayOfYear* = getDayOfYear
    gDateMondayWeekOfYear* = getMondayWeekOfYear
    gDateSundayWeekOfYear* = getSundayWeekOfYear
    gDateDaysInMonth* = getDaysInMonth
    gDateMondayWeeksInYear* = getMondayWeeksInYear
    gDateSundayWeeksInYear* = getSundayWeeksInYear
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

sed -i 's/proc dateValid/proc valid/g' final.nim
sed -i 's/proc dateIsLeapYear/proc isLeapYear/g' final.nim
sed -i 's/proc dateGet/proc get/g' final.nim

i='when not (G_DISABLE_DEPRECATED):
  const
    gStringSprintf* = gStringPrintf
    gStringSprintfa* = gStringAppendPrintf
'
j='when not (G_DISABLE_DEPRECATED):
  const
    gStringSprintf* = printf
    gStringSprintfa* = appendPrintf
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

sed -i 's/ TRUE\b/ GTRUE/g' final.nim
sed -i 's/ FALSE\b/ GFALSE/g' final.nim

for i in glib_Sizeof_Size_T gVaCopy gnuc ppc call_Sysv win32 g_Va_Copy_As_Array g_Os_Win32 cplusplus mingw_H stdlib_H optimize ; do
  sed -i "s/\b${i}\b/\U&/g" final.nim
done

sed -i 's/GTokenValue* = object  {.union.}/GTokenValue* {.final, pure.} = object  {.union.}/g' final.nim

sed -i 's/\(dummy[0-9]\?\)\*/\1/g' final.nim
sed -i 's/\(reserved[0-9]\?\)\*/\1/g' final.nim
sed -i 's/proc type\*(/proc `type`\*(/g' final.nim

sed -i 's/[(][(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/(\1/g' final.nim
sed -i 's/, [(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/, \1/g' final.nim

sed -i 's/when defined(G_OS_WIN32)/when defined(windows)/g' final.nim
sed -i 's/when not defined(G_OS_WIN32)/when not defined(windows)/g' final.nim

ruby ../fix_object_of.rb final.nim

perl -0777 -p -i -e "s~([=:] proc \(.*?\)(?:: \w+)?)~\1 {.cdecl.}~sg" final.nim
sed -i 's/\([,=(<>] \{0,1\}\)[(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/\1\2/g' final.nim

sed -i '/^#type$/d' final.nim

i='template gRandBoolean*(rand: untyped): untyped =
  ((gRandInt(rand) and (1 shl 15)) != 0)

proc int*(rand: GRand): Guint32 {.importc: "g_rand_int", libglib.}
'
j='proc gRandInt*(rand: GRand): Guint32 {.importc: "g_rand_int",
    libglib.}
proc gRandBoolean*(rand: GRand): Gboolean {.inline.} =
  cast[Gboolean]((cast[int32](g_rand_int(rand)) and (1 shl 15)) shr 15)
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='template gRandomBoolean*(): untyped =
  ((gRandomInt() and (1 shl 15)) != 0)

proc gRandomInt*(): Guint32 {.importc: "g_random_int", libglib.}
'
j='proc gRandomInt*(): Guint32 {.importc: "g_random_int", libglib.}
proc gRandomBoolean*(): Gboolean {.inline.} =
  cast[Gboolean]((cast[int32](g_random_int()) and (1 shl 15)) shr 15)
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='template gListPrevious*(list: untyped): untyped =
  (if (list): ((cast[GList](list)).prev) else: nil)

template gListNext*(list: untyped): untyped =
  (if (list): ((cast[GList](list)).next) else: nil)
'
j='proc previous*(list: GList): GList {.inline.} =
  if list != nil: list.prev else: nil

proc next*(list: GList): GList {.inline.} =
  if list != nil: list.next else: nil
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='        2, G_ASCII_DIGIT = 1 shl 3, G_ASCII_GRAPH = 1 shl 4, 
    G_ASCII_LOWER = 1 shl 5, G_ASCII_PRINT = 1 shl 6, G_ASCII_PUNCT = 1 shl
        7, G_ASCII_SPACE = 1 shl 8, G_ASCII_UPPER = 1 shl 9, 
    G_ASCII_XDIGIT = 1 shl 10
'
j='        2, DIGIT = 1 shl 3, GRAPH = 1 shl 4,
    LOWER = 1 shl 5, PRINT = 1 shl 6, PUNCT = 1 shl
        7, SPACE = 1 shl 8, UPPER = 1 shl 9,
    XDIGIT = 1 shl 10
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

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

# some procs with get_ prefix do not return something but need var objects instead of pointers:
# vim search term for candidates:
# proc get[^)]*)[^:}]*{
i='proc getCurrentTime*(source: GSource; timeval: GTimeVal) {.
    importc: "g_source_get_current_time", libglib.}
'
j='proc getCurrentTime*(source: GSource; timeval: var GTimeValObj) {.
    importc: "g_source_get_current_time", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='proc getCurrentTime*(result: GTimeVal) {.importc: "g_get_current_time",
    libglib.}
'
j='proc getCurrentTime*(result: var GTimeValObj) {.importc: "g_get_current_time", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

sed -i 's/stamp: ptr times.Time;/stamp: var times.Time;/g' final.nim
sed -i 's/\(0x\)0*\([0123456789ABCDEF]\)/\1\2/g' final.nim
sed -i 's/\s\+$//g' final.nim

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
sed -i "s/\bTimeT\b/times.Time/g" final.nim

sed -i 's/  QQQG/  G/g' final.nim

# generate procs without get_ and set_ prefix
perl -0777 -p -i -e "s/(\n\s*)(proc set)([A-Z]\w+)(\*\([^}]*\) \{[^}]*})/\$&\1proc \`\l\3=\`\4/sg" final.nim
perl -0777 -p -i -e "s/(\n\s*)(proc get)([A-Z]\w+)(\*\([^}]*\): \w[^}]*})/\$&\1proc \l\3\4/sg" final.nim

# these proc names generate trouble
for i in int uint string enum boolean double flags integer int64 uint64 ; do
  perl -0777 -p -i -e "s/(\n\s*)(proc ${i})(\*\([^}]*\): \w[^}]*})//sg" final.nim
  perl -0777 -p -i -e "s/(\n\s*)(proc \`?${i}=?\`?)(\*\([^}]*\): \w[^}]*})//sg" final.nim
  perl -0777 -p -i -e "s/(\n\s*)(proc \`?${i}=?\`?)(\*\([^}]*\) \{[^}]*})//sg" final.nim
done

# fix a few proc names used in templates
sed  -i "s/\(  gDatalist\)\([A-Z]\)\(\.*\)/  \l\2\3/g" final.nim
sed  -i "s/\(  gNode\)\([A-Z]\)\(\.*\)/  \l\2\3/g" final.nim
sed  -i "s/\bgNodeNew\b/new/g" final.nim

sed  -i "s/\bg_Dir_Separator\b/G_DIR_SEPARATOR/g" final.nim

sed -i "s/gArrayAppendVals(/appendVals(/g" final.nim
sed -i "s/gArrayPrependVals(/prependVals(/g" final.nim
sed -i "s/gArrayInsertVals(/insertVals(/g" final.nim
sed -i "s/gHookInsertBefore(insertBefore(//g" final.nim
sed -i "s/gStringAppendCInline/appendCInline/g" final.nim
sed -i "s/gTestQueueDestroy/testQueueDestroy/g" final.nim
sed -i "s/gTestAssertExpectedMessagesInternal/testAssertExpectedMessagesInternal/g" final.nim
sed -i "s/gVariantTypeChecked/variantTypeChecked/g" final.nim

i='template gStrstrip*(string: untyped: untyped =
  gStrchomp(gStrchug(string))
'
j='proc strip*(string: cstring): cstring = chomp(chug(string))
'
#perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

# rename the few new methods manually -- may need some more care---
i='proc newFromBytes*(bytes: GBytes; offset: Gsize; length: Gsize): GBytes {.
    importc: "g_bytes_new_from_bytes", libglib.}
'
j='proc newGBytes*(bytes: GBytes; offset: Gsize; length: Gsize): GBytes {.
    importc: "g_bytes_new_from_bytes", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='proc new*(init: cstring): GString {.importc: "g_string_new", libglib.}
proc newLen*(init: cstring; len: Gssize): GString {.
    importc: "g_string_new_len", libglib.}
'
j='proc newGString*(init: cstring): GString {.importc: "g_string_new", libglib.}
proc newGString*(init: cstring; len: Gssize): GString {.
    importc: "g_string_new_len", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

# TODO: Fix names
i='proc newArray*(element: GVariantType): GVariantType {.
    importc: "g_variant_type_new_array", libglib.}
proc newMaybe*(element: GVariantType): GVariantType {.
    importc: "g_variant_type_new_maybe", libglib.}
proc newTuple*(items: var GVariantType; length: cint): GVariantType {.
    importc: "g_variant_type_new_tuple", libglib.}
proc newDictEntry*(key: GVariantType; value: GVariantType): GVariantType {.
    importc: "g_variant_type_new_dict_entry", libglib.}
'
j='proc newArray*(element: GVariantType): GVariantType {.
    importc: "g_variant_type_new_array", libglib.}
proc newMaybe*(element: GVariantType): GVariantType {.
    importc: "g_variant_type_new_maybe", libglib.}
proc newTuple*(items: var GVariantType; length: cint): GVariantType {.
    importc: "g_variant_type_new_tuple", libglib.}
proc newDictEntry*(key: GVariantType; value: GVariantType): GVariantType {.
    importc: "g_variant_type_new_dict_entry", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='proc newFromBytes*(bytes: GBytes; offset: Gsize; length: Gsize): GBytes {.
    importc: "g_bytes_new_from_bytes", libglib.}
'
j='proc newGBytes*(bytes: GBytes; offset: Gsize; length: Gsize): GBytes {.
    importc: "g_bytes_new_from_bytes", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='proc new*(init: cstring): GString {.importc: "g_string_new", libglib.}
proc newLen*(init: cstring; len: Gssize): GString {.
    importc: "g_string_new_len", libglib.}
'
j='proc newGString*(init: cstring): GString {.importc: "g_string_new", libglib.}
proc newGString*(init: cstring; len: Gssize): GString {.
    importc: "g_string_new_len", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

# TODO: fix names
i='proc newArray*(element: GVariantType): GVariantType {.
    importc: "g_variant_type_new_array", libglib.}
proc newMaybe*(element: GVariantType): GVariantType {.
    importc: "g_variant_type_new_maybe", libglib.}
proc newTuple*(items: var GVariantType; length: cint): GVariantType {.
    importc: "g_variant_type_new_tuple", libglib.}
proc newDictEntry*(key: GVariantType; value: GVariantType): GVariantType {.
    importc: "g_variant_type_new_dict_entry", libglib.}
'
j='proc newArray*(element: GVariantType): GVariantType {.
    importc: "g_variant_type_new_array", libglib.}
proc newMaybe*(element: GVariantType): GVariantType {.
    importc: "g_variant_type_new_maybe", libglib.}
proc newTuple*(items: var GVariantType; length: cint): GVariantType {.
    importc: "g_variant_type_new_tuple", libglib.}
proc newDictEntry*(key: GVariantType; value: GVariantType): GVariantType {.
    importc: "g_variant_type_new_dict_entry", libglib.}
'
#perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='proc newVariant*(value: GVariant): GVariant {.
    importc: "g_variant_new_variant", libglib.}
'
j='proc newGVariant*(value: GVariant): GVariant {.
    importc: "g_variant_new_variant", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

# TODO: fix names
i='proc newTuple*(children: var GVariant; nChildren: Gsize): GVariant {.
    importc: "g_variant_new_tuple", libglib.}
proc newDictEntry*(key: GVariant; value: GVariant): GVariant {.
    importc: "g_variant_new_dict_entry", libglib.}
'
j='proc newTuple*(children: var GVariant; nChildren: Gsize): GVariant {.
    importc: "g_variant_new_tuple", libglib.}
proc newDictEntry*(key: GVariant; value: GVariant): GVariant {.
    importc: "g_variant_new_dict_entry", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

# variant is too confusing...
sed -i 's/proc variantNew/proc variantOOO/g' final.nim
sed -i 's/\(proc \w\+New\)[A-Z]\w\+/\1/g' final.nim
sed -i 's/proc \(\w\+\)New\*/proc new\u\1*/g' final.nim
sed -i 's/proc variantOOO/proc variantNew/g' final.nim
i='proc newBytes*(data: Gconstpointer; size: Gsize): GBytes {.
    importc: "g_bytes_new_static", libglib.}
'
j='proc newBytesStatic*(data: Gconstpointer; size: Gsize): GBytes {.
    importc: "g_bytes_new_static", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim
i='proc newBytes*(data: Gpointer; size: Gsize): GBytes {.
    importc: "g_bytes_new_take", libglib.}
'
j='proc newBytesTake*(data: Gpointer; size: Gsize): GBytes {.
    importc: "g_bytes_new_take", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim
i='proc newTimeZone*(): GTimeZone {.importc: "g_time_zone_new_utc", libglib.}
proc newTimeZone*(): GTimeZone {.importc: "g_time_zone_new_local",
                                       libglib.}
'
j='proc newTimeZoneUTC*(): GTimeZone {.importc: "g_time_zone_new_utc", libglib.}
proc newTimeZoneLocal*(): GTimeZone {.importc: "g_time_zone_new_local",
                                       libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim
i='proc newDateTime*(): GDateTime {.importc: "g_date_time_new_now_utc",
                                        libglib.}
proc newDateTime*(t: int64): GDateTime {.
    importc: "g_date_time_new_from_unix_local", libglib.}
proc newDateTime*(t: int64): GDateTime {.
    importc: "g_date_time_new_from_unix_utc", libglib.}
proc newDateTime*(tv: GTimeVal): GDateTime {.
    importc: "g_date_time_new_from_timeval_local", libglib.}
proc newDateTime*(tv: GTimeVal): GDateTime {.
    importc: "g_date_time_new_from_timeval_utc", libglib.}
proc newDateTime*(tz: GTimeZone; year: cint; month: cint; day: cint; hour: cint;
                  minute: cint; seconds: cdouble): GDateTime {.
    importc: "g_date_time_new", libglib.}
proc newDateTime*(year: cint; month: cint; day: cint; hour: cint; minute: cint;
                       seconds: cdouble): GDateTime {.
    importc: "g_date_time_new_local", libglib.}
proc newDateTime*(year: cint; month: cint; day: cint; hour: cint; minute: cint;
                     seconds: cdouble): GDateTime {.
    importc: "g_date_time_new_utc", libglib.}
'
j='proc newDateTimeNowUTC*(): GDateTime {.importc: "g_date_time_new_now_utc",
                                        libglib.}
proc newDateTimeFromUnixLocal*(t: int64): GDateTime {.
    importc: "g_date_time_new_from_unix_local", libglib.}
proc newDateTimeFromUnixUTC*(t: int64): GDateTime {.
    importc: "g_date_time_new_from_unix_utc", libglib.}
proc newDateTimeFromTimeValLocal*(tv: GTimeVal): GDateTime {.
    importc: "g_date_time_new_from_timeval_local", libglib.}
proc newDateTimeFromTimeValUTC*(tv: GTimeVal): GDateTime {.
    importc: "g_date_time_new_from_timeval_utc", libglib.}
proc newDateTime*(tz: GTimeZone; year: cint; month: cint; day: cint; hour: cint;
                  minute: cint; seconds: cdouble): GDateTime {.
    importc: "g_date_time_new", libglib.}
proc newDateTimeLocal*(year: cint; month: cint; day: cint; hour: cint; minute: cint;
                       seconds: cdouble): GDateTime {.
    importc: "g_date_time_new_local", libglib.}
proc newDateTimeUTC*(year: cint; month: cint; day: cint; hour: cint; minute: cint;
                     seconds: cdouble): GDateTime {.
    importc: "g_date_time_new_utc", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim
i='proc newTimeoutSource*(interval: cuint): GSource {.
    importc: "g_timeout_source_new_seconds", libglib.}
'
j='proc newTimeoutSourceSeconds*(interval: cuint): GSource {.
    importc: "g_timeout_source_new_seconds", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

i='  when GLIB_SIZEOF_VOID_P == 8:
    proc newIoChannelWin32*(hwnd: Gsize): GIOChannel {.
        importc: "g_io_channel_win32_new_messages", libglib.}
  else:
    proc newIoChannelWin32*(hwnd: cuint): GIOChannel {.
        importc: "g_io_channel_win32_new_messages", libglib.}
  proc newIoChannelWin32*(fd: cint): GIOChannel {.
      importc: "g_io_channel_win32_new_fd", libglib.}
  proc win32GetFd*(channel: GIOChannel): cint {.
      importc: "g_io_channel_win32_get_fd", libglib.}
  proc newIoChannelWin32*(socket: cint): GIOChannel {.
      importc: "g_io_channel_win32_new_socket", libglib.}
  proc newIoChannelWin32*(socket: cint): GIOChannel {.
      importc: "g_io_channel_win32_new_stream_socket", libglib.}
'
j='  when GLIB_SIZEOF_VOID_P == 8:
    proc newIoChannelWin32Message*(hwnd: Gsize): GIOChannel {.
        importc: "g_io_channel_win32_new_messages", libglib.}
  else:
    proc newIoChannelWin32Message*(hwnd: cuint): GIOChannel {.
        importc: "g_io_channel_win32_new_messages", libglib.}
  proc newIoChannelWin32NewFd*(fd: cint): GIOChannel {.
      importc: "g_io_channel_win32_new_fd", libglib.}
  proc win32GetFd*(channel: GIOChannel): cint {.
      importc: "g_io_channel_win32_get_fd", libglib.}
  proc newIoChannelWin32Socket*(socket: cint): GIOChannel {.
      importc: "g_io_channel_win32_new_socket", libglib.}
  proc newIoChannelWin32StreamSocket*(socket: cint): GIOChannel {.
      importc: "g_io_channel_win32_new_stream_socket", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim
i='  const
    ioChannelNewFileUtf8* = ioChannelNewFile
'
j='  const
    ioChannelNewFileUtf8* = newIoChannel
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

# some procs called from templates
sed  -i "s/gQuarkFromString(/quarkFromString(/g" final.nim
sed  -i "s/gDatasetIdSetDataFull(/datasetIdSetDataFull(/g" final.nim
sed  -i "s/gDatasetIdSetData(/datasetIdSetData(/g" final.nim
sed  -i "s/gDatasetIdGetData/datasetIdGetData/g" final.nim
sed  -i "s/gQuarkTryString(/quarkTryString(/g" final.nim
sed  -i "s/gHookInsertBefore(/hookInsertBefore(/g" final.nim
sed  -i "s/gStringInsertC(/stringInsertC(/g" final.nim
sed  -i "s/gRandomInt(/randomInt(/g" final.nim
sed  -i "s/gTestRandInt(/testRandInt(/g" final.nim
sed  -i "s/gDatasetIdRemoveNoNotify(/datasetIdRemoveNoNotify(/g" final.nim
sed  -i "s/gWin32GetSystemDataDirsForModule(/win32GetSystemDataDirsForModule(/g" final.nim

i='proc next*(iter: GHashTableIter; key: ptr Gpointer;
                        value: var Gpointer): Gboolean {.
    importc: "g_hash_table_iter_next", libglib.}
'
j='proc next*(iter: GHashTableIter; key: ptr Gpointer;
                        value: ptr Gpointer): Gboolean {.
    importc: "g_hash_table_iter_next", libglib.}
'
perl -0777 -p -i -e "s/\Q$i\E/$j/s" final.nim

cat ../glib_extensions.nim >> final.nim

cat -s final.nim > glib.nim

rm -r glib
rm final.h final.nim list.txt

exit

