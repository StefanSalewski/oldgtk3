# This is a (nearly) verbatim translation of test-completion.c shipped
# with gtksourceview 3.14 to Nim language
# License and Copyright of the original authors persist.
#
# Conversion is done by the tool c2nim 0.97 followed by some manually cleanup
# Tested with GTK 3.14, Nim 0.10.3 and gcc 4.9.2
# build: nim c -dRelease testCompletion.nim

import oldgtk3/[gtk, glib, gobject, gtksource, gdk_pixbuf, pango]
from strutils import `%`

type
  TestProvider = ptr TestProviderObj
  TestProviderObj = object of CompletionProviderObj
    proposals: GList
    priority: cint
    name: cstring
    icon: GdkPixbuf
    # If it's a random provider, a subset of 'proposals' are choosen on
    # each populate. Otherwise, all the proposals are shown. */
    isRandom: bool

  TestProviderPrivate = ptr TestProviderPrivateObj
  TestProviderPrivateObj = object


  TestProviderClass = ptr TestProviderClassObj
  TestProviderClassObj = object of GObjectClassObj

var
  wordProvider: CompletionWords
  fixedProvider: TestProvider
  randomProvider: TestProvider

proc testProviderIfaceInit(iface: CompletionProviderIface)

# type_iface: The GType of the interface to add
# iface_init: The interface init function
proc gImplementInterfaceStr*(typeIface, ifaceInit: string): string =
  """
var gImplementInterfaceInfo = GInterfaceInfoObj(interfaceInit: cast[GInterfaceInitFunc]($2),
                                                     interfaceFinalize: nil,
                                                     interfaceData: nil)
addInterfaceStatic(gDefineTypeId, $1, addr(gImplementInterfaceInfo))

""" % [type_iface, iface_init]

gDefineTypeExtended(TestProvider, objectGetType(), 0,
  gImplementInterfaceStr("completionProviderGetType()", "testProviderIfaceInit"))

#gDefineTypeExtended("TestProvider", "testProvider", "gObjectGetType()", "0",
#  gImplementInterfaceStr("completionProviderGetType()", "testProviderIfaceInit"))

proc testProviderGetName(provider: CompletionProvider): cstring {.cdecl.} =
  dup(cast[TestProvider](provider).name)

proc testProviderGetPriority(provider: CompletionProvider): cint {.cdecl.} =
  cast[TestProvider](provider).priority

proc selectRandomProposals(allProposals: GList): GList =
  var selection: GList = nil
  var prop = allProposals
  while prop != nil:
    if gRandomBoolean():
      selection = glib.prepend(selection, prop.data)
    prop = next(prop)
  return selection

proc testProviderPopulate(completionProvider: CompletionProvider;
                             context: CompletionContext) {.cdecl.} =
  var provider = cast[TestProvider](completionProvider)
  var proposals: GList
  if provider.isRandom:
    proposals = selectRandomProposals(provider.proposals)
  else:
    proposals = provider.proposals
  addProposals(context, completionProvider, proposals, true)

proc testProviderGetIcon(provider: CompletionProvider): GdkPixbuf =
  var tp  = cast[TestProvider](provider)
  var error: GError = nil
  if tp.icon == nil:
    var theme = gtk.iconThemeGetDefault()
    tp.icon = gtk.loadIcon(theme, "dialog-information", 16, cast[IconLookupFlags](0), error)
  return tp.icon

proc testProviderIfaceInit(iface: CompletionProviderIface) =
  iface.getName = testProviderGetName
  iface.populate = testProviderPopulate
  iface.getPriority = testProviderGetPriority
  # iface->getIcon = testProviderGetIcon;

proc testProviderDispose(gobject: GObject) {.cdecl.} =
  var self = cast[TestProvider](gobject)
  freeFull(self.proposals, objectUnref)
  self.proposals = nil
  var hhh = cast[GObject](self.icon)
  clearObject(hhh)
  self.icon = nil
  gObjectClass(testProviderParentClass).dispose(gobject)

proc testProviderFinalize(gobject: GObject) {.cdecl.} =
  var self = cast[TestProvider](gobject)
  free(self.name)
  self.name = nil
  gObjectClass(testProviderParentClass).finalize(gobject)

proc testProviderClassInit(klass: TestProviderClass) =
  klass.dispose = testProviderDispose
  klass.finalize = testProviderFinalize

proc testProviderInit(self: TestProvider) =
  discard

proc testProviderSetFixed*(provider: TestProvider; nbProposals: cint) =
  var icon = testProviderGetIcon(provider)
  var proposals: GList = nil
  freeFull(provider.proposals, objectUnref)
  var i = nbProposals - 1
  while i > 0:
    var name = dupPrintf("Proposal %d", i)
    proposals = prepend(proposals, newCompletionItemWithLabel(name,
        name, icon, "The extra info of the proposal.\x0AA second line."))
    free(name)
    dec(i)
  proposals = prepend(proposals, newCompletionItemWithLabel(
      "A very long proposal. I repeat, a very long proposal!",
      "A very long proposal. I repeat, a very long proposal!", icon,
      "To test the horizontal scrollbar."))
  provider.proposals = proposals
  provider.isRandom = false

proc testProviderSetRandom(provider: TestProvider; nbProposals: cint) =
  var icon = testProviderGetIcon(provider)
  var proposals: GList = nil
  var i: cint = 0
  freeFull(provider.proposals, objectUnref)
  while i < nbProposals:
    var padding  = strnfill((i * 3) mod 10, 'o')
    var name = dupPrintf("Propo%ssal %d", padding, i)
    proposals = prepend(proposals, newCompletionItemWithLabel(name,
        name, icon, nil))
    free(padding)
    free(name)
    inc(i)
  provider.proposals = proposals
  provider.isRandom = true

proc addRemoveProvider(button: gtk.ToggleButton;
                          completion: gtksource.Completion;
                          provider: CompletionProvider) =
  var error: GError = nil
  if provider == nil:
    return
  if getActive(button):
    discard addProvider(completion, provider, error)
  else:
    discard removeProvider(completion, provider, error)

proc enableWordProviderToggledCb(button: gtk.ToggleButton;
                                      completion: gtksource.Completion) =
  addRemoveProvider(button, completion, wordProvider)

proc enableFixedProviderToggledCb(button: gtk.ToggleButton;
                                       completion: gtksource.Completion) =
  addRemoveProvider(button, completion, fixedProvider)


proc enableRandomProviderToggledCb(button: gtk.ToggleButton;
                                        completion: gtksource.Completion) =
  addRemoveProvider(button, completion, randomProvider)

proc nbProposalsChangedCb*(spinButton: gtk.SpinButton;
                              provider: TestProvider) =
  let nbProposals = valueAsInt(spinButton)
  if provider.isRandom:
    testProviderSetRandom(provider, nbProposals)
  else:
    testProviderSetFixed(provider, nbProposals)

proc createCompletion*(sourceView: gtksource.View;
                        completion: gtksource.Completion) =
  var error: GError = nil
  # Words completion provider
  wordProvider = newCompletionWords(nil, nil)
  register(wordProvider, getBuffer(TextView(sourceView)))
  discard addProvider(completion, wordProvider, error)
  objectSet(wordProvider, "priority", 10, nil)
  # Fixed provider: the proposals don't change
  fixedProvider = cast[TestProvider](newObject(testProviderGetType(), nil))
  testProviderSetFixed(fixedProvider, 3)
  fixedProvider.priority = 5
  fixedProvider.name = dup("Fixed Provider")
  discard addProvider(completion, fixedProvider, error)
  # Random provider: the proposals vary on each populate
  randomProvider = cast[TestProvider](newObject(testProviderGetType(), nil))
  testProviderSetRandom(randomProvider, 10)
  randomProvider.priority = 1
  randomProvider.name = dup("Random Provider")
  discard addProvider(completion, randomProvider, error)

proc createWindow() =
  const
    BFlags = GBindingFlags(GBindingFlags.BIDIRECTIONAL.ord + GBindingFlags.SYNC_CREATE.ord)
  var
    builder: gtk.Builder
    error: GError = nil
    window: gtk.Window
    sourceView: View
    completion: Completion
    rememberInfoVisibility: gtk.CheckButton
    selectOnShow: CheckButton
    showHeaders: CheckButton
    showIcons: CheckButton
    enableWordProvider: CheckButton
    enableFixedProvider: CheckButton
    enableRandomProvider: CheckButton
    nbFixedProposals: SpinButton
    nbRandomProposals: SpinButton
    fontDesc: pango.FontDescription
  builder = newBuilder()

  # register the GObject types so builder can use them, see
  # https://mail.gnome.org/archives/gtk-list/2015-March/msg00016.html
  discard viewGetType()
  discard completionInfoGetType()

  discard addFromFile(builder, "test-completion.ui", error)
  if error != nil:
    echo("Impossible to load test-completion.ui:")
    echo(error.message)
    assert false
    #gError("Impossible to load test-completion.ui: %s", error.message)
  window = Window(getObject(builder, "window"))
  sourceView = View(getObject(builder, "sourceView"))
  rememberInfoVisibility = CheckButton(
      getObject(builder, "checkbuttonRememberInfoVisibility"))
  selectOnShow = CheckButton(getObject(builder, "checkbuttonSelectOnShow"))
  showHeaders = CheckButton(getObject(builder, "checkbuttonShowHeaders"))
  showIcons = CheckButton(getObject(builder, "checkbuttonShowIcons"))
  enableWordProvider = CheckButton(
      getObject(builder, "checkbuttonWordProvider"))
  enableFixedProvider = CheckButton(getObject(builder, "checkbuttonFixedProvider"))
  enableRandomProvider = CheckButton(getObject(builder, "checkbuttonRandomProvider"))
  nbFixedProposals = SpinButton(getObject(builder, "spinbuttonNbFixedProposals"))
  nbRandomProposals = SpinButton(getObject(builder, "spinbuttonNbRandomProposals"))
  completion = getCompletion(sourceView)

  fontDesc = pango.fontDescriptionFromString("monospace")
  if fontDesc != nil:
    overrideFont(sourceView, fontDesc)
    pango.free(fontDesc)

  discard gSignalConnect(window, "destroy", gCallback(gtk.mainQuit), nil)
  discard objectBindProperty(completion, "remember-info-visibility",
                         rememberInfoVisibility, "active", BFlags)
  discard objectBindProperty(completion, "select-on-show", selectOnShow, "active", BFlags)
  discard objectBindProperty(completion, "show-headers", showHeaders, "active", BFlags)
  discard objectBindProperty(completion, "show-icons", showIcons, "active", BFlags)
  createCompletion(sourceView, completion)
  discard gSignalConnect(enableWordProvider, "toggled",
                   gCallback(enableWordProviderToggledCb), completion)
  discard gSignalConnect(enableFixedProvider, "toggled",
                   gCallback(enableFixedProviderToggledCb), completion)
  discard gSignalConnect(enableRandomProvider, "toggled",
                   gCallback(enableRandomProviderToggledCb), completion)
  discard gSignalConnect(nbFixedProposals, "value-changed",
                   gCallback(nbProposalsChangedCb), fixedProvider)
  discard gSignalConnect(nbRandomProposals, "value-changed",
                   gCallback(nbProposalsChangedCb), randomProvider)
  objectUnref(builder)

gtk.initWithArgv()
createWindow()
gtk.main()
# Not really useful, except for debugging memory leaks.
objectUnref(wordProvider)
objectUnref(fixedProvider)
objectUnref(randomProvider)

