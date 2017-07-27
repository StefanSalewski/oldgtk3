# manual extensions for glib.nim
#
converter ghtio2ghti*(i: var GHashTableIterObj): GHashTableIter =
  addr(i)

const G_LOG_DOMAIN* = cast[ptr cchar](0)

proc critical*(format: cstring) {.varargs.} =
  glib.log(G_LOG_DOMAIN, GLogLevelFlags.LEVEL_CRITICAL, format)

proc gNot*(gb: Gboolean): Gboolean = Gboolean(GTRUE.cint - gb.cint)
