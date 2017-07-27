# Manual extensions for gtk3.nim
#

converter TIO2TI*(i: var TextIterObj): TextIter =
  addr(i)

proc initWithArgv*() =
  var
    cmdLine{.importc.}: cstringArray
    cmdCount{.importc.}: cint
  gtk3.init(cmdCount, cmdLine)

proc newWindow*(): gtk3.Window =
  gtk3.newWindow(gtk3.WindowType.TOPLEVEL)

proc newRadioButton*(): gtk3.RadioButton =
  gtk3.newFromWidget(cast[gtk3.RadioButton](0))

proc newRadioButton*(label: cstring): gtk3.RadioButton =
  gtk3.newWithMnemonicFromWidget(cast[gtk3.RadioButton](0), label)

proc newRadioButton*(radioGroupMember: gtk3.RadioButton; label: cstring): gtk3.RadioButton =
  gtk3.newWithMnemonicFromWidget(radioGroupMember, label)

template widgetClassBindTemplateChildInternalPrivate*(widgetClass, TypeName, memberName): untyped =
  bindTemplateChildFull(widgetClass, astToStr(memberName), true, gPrivateOffset(TypeName, memberName))

template widgetClassBindTemplateChildPrivate*(widgetClass, TypeName, memberName): untyped =
  bindTemplateChildFull(widgetClass, astToStr(memberName), false, gPrivateOffset(TypeName, memberName))

template widgetClassBindTemplateCallback*(widgetKlass, callback): untyped =
  bindTemplateCallbackFull(widgetKlass, astToStr(callback), gCallback(callback))

template widgetClassBindTemplateChild*(widgetClass, TypeName, memberName): untyped =
  bindTemplateChildFull(widgetClass, astToStr(memberName), false, gStructOffset(TypeName, memberName))
