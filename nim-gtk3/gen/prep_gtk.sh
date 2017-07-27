#!/bin/bash
# S. Salewski, 26-JUL-2017
# Generate GTK3 bindings for Nim

# NOTE: we call this script twice -- first with an arbitrary argument to generate final.h, after that without argument to generate gtk3.nim
# First call takes some minutes to terminate!

if [ $# -eq 1 ]; then
gtk3_dir="/home/stefan/Downloads/gtk+-3.22.16"
final="final.h" # the input file for c2nim
list="list.txt"
wdir="tmp_gtk"

targets='a11y deprecated'
all_t=". ${targets}"

rm -rf $wdir # start from scratch
mkdir $wdir
cd $wdir
cp -r $gtk3_dir/gtk .
cd gtk

# check already done for 3.20.1...
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

cat gtk.h gtkunixprint.h gtk-a11y.h > all.h

cd ..

# cpp run with all headers to determine order
echo "cat \\" > $list

cpp -I. `pkg-config --cflags gtk+-3.0` gtk/all.h $final

# extract file names and push names to list
grep ssalewski $final | sed 's/_ssalewski;/ \\/' >> $list

# maybe add remaining missing headers
# for now we put all at the bottom and do manually insertion if we need these at all
# echo 'gtkactionhelper.h \' >> $list  # do not add, it uses G_GNUC_INTERNAL macro, so it really only for internal use
echo 'gtkintl.h \' >> $list # not really helpful?
#echo 'gtkmenutracker.h \' >> $list # do we need this?
#echo 'gtkmenutrackeritem.h \' >> $list

i=`sort $list | uniq -d | wc -l`
if [ $i != 0 ]; then echo 'list contains duplicates!'; exit; fi;

# now we work again with original headers
rm -rf gtk
cp -r $gtk3_dir/gtk . 

# insert for each header file its name as first line
for j in $all_t ; do
  for i in gtk/${j}/*.h; do
    sed -i "1i/* file: $i */" $i
    sed -i "1i#define headerfilename \"$i\"" $i # marker for splitting
  done
done
cd gtk
  bash ../$list > ../$final
cd ..

# delete strange macros  -- define as empty for c2nim
# we restrict use of wildcards to limit risc of damage something!
for i in 2 4 6 8 10 12 14 16 18 20 22 ; do
  sed -i "1i#def GDK_AVAILABLE_IN_3_$i\n#def GDK_DEPRECATED_IN_3_$i\n#def GDK_DEPRECATED_IN_3_${i}_FOR(x)" $final
done

sed -i "1i#def G_BEGIN_DECLS" $final
sed -i "1i#def G_END_DECLS" $final
sed -i "1i#def GDK_AVAILABLE_IN_ALL" $final
sed -i "1i#def GDK_DEPRECATED" $final
sed -i "1i#def G_GNUC_DEPRECATED" $final
sed -i "1i#def G_DEPRECATED" $final
sed -i "1i#def GDK_DEPRECATED_IN_3_0" $final
sed -i "1i#def GDK_DEPRECATED_IN_3_0_FOR(x)" $final
sed -i "1i#def G_GNUC_MALLOC" $final
sed -i "1i#def G_GNUC_CONST" $final
sed -i "1i#def G_GNUC_NULL_TERMINATED" $final
sed -i "1i#def G_GNUC_PRINTF(i,j)" $final
sed -i "1i#def G_DEFINE_AUTOPTR_CLEANUP_FUNC(i, j)" $final

perl -0777 -p -i -e "s/#if !?defined.*?\n#error.*?\n#endif//g" $final

sed -i 's/typedef struct _GtkShortcutLabel      GtkShortcutLabel;/typedef struct _GtkShortcutLabel{} GtkShortcutLabel;/' final.h
sed -i 's/typedef struct _GtkPadController GtkPadController;/typedef struct _GtkPadController{} GtkPadController;/' final.h
sed -i 's/typedef struct _GtkAccelGroupPrivate      GtkAccelGroupPrivate;/typedef struct _GtkAccelGroupPrivate{} GtkAccelGroupPrivate;/' final.h
sed -i 's/typedef struct _GtkClipboard	       GtkClipboard;/typedef struct _GtkClipboard{} GtkClipboard;/' final.h
sed -i 's/typedef struct _GtkIconSet             GtkIconSet;/typedef struct _GtkIconSet{} GtkIconSet;/' final.h
sed -i 's/typedef struct _GtkIconSource          GtkIconSource;/typedef struct _GtkIconSource{} GtkIconSource;/' final.h
sed -i 's/typedef struct _GtkSelectionData       GtkSelectionData;/typedef struct _GtkSelectionData{} GtkSelectionData;/' final.h
sed -i 's/typedef struct _GtkTooltip             GtkTooltip;/typedef struct _GtkTooltip{} GtkTooltip;/' final.h
sed -i 's/typedef struct _GtkWidgetPath          GtkWidgetPath;/typedef struct _GtkWidgetPath{} GtkWidgetPath;/' final.h
sed -i 's/typedef struct _GtkWidgetPrivate       GtkWidgetPrivate;/typedef struct _GtkWidgetPrivate{} GtkWidgetPrivate;/' final.h
sed -i 's/typedef struct _GtkWidgetClassPrivate  GtkWidgetClassPrivate;/typedef struct _GtkWidgetClassPrivate{} GtkWidgetClassPrivate;/' final.h
sed -i 's/typedef struct _GtkApplicationPrivate GtkApplicationPrivate;/typedef struct _GtkApplicationPrivate{} GtkApplicationPrivate;/' final.h
sed -i 's/typedef struct _GtkContainerPrivate       GtkContainerPrivate;/typedef struct _GtkContainerPrivate{} GtkContainerPrivate;/' final.h
sed -i 's/typedef struct _GtkBinPrivate       GtkBinPrivate;/typedef struct _GtkBinPrivate{} GtkBinPrivate;/' final.h
sed -i 's/typedef struct _GtkWindowPrivate      GtkWindowPrivate;/typedef struct _GtkWindowPrivate{} GtkWindowPrivate;/' final.h
sed -i 's/typedef struct _GtkWindowGeometryInfo GtkWindowGeometryInfo;/typedef struct _GtkWindowGeometryInfo{} GtkWindowGeometryInfo;/' final.h
sed -i 's/typedef struct _GtkWindowGroupPrivate GtkWindowGroupPrivate;/typedef struct _GtkWindowGroupPrivate{} GtkWindowGroupPrivate;/' final.h
sed -i 's/typedef struct _GtkDialogPrivate       GtkDialogPrivate;/typedef struct _GtkDialogPrivate{} GtkDialogPrivate;/' final.h
sed -i 's/typedef struct _GtkAboutDialogPrivate GtkAboutDialogPrivate;/typedef struct _GtkAboutDialogPrivate{} GtkAboutDialogPrivate;/' final.h
sed -i 's/typedef struct _GtkMiscPrivate       GtkMiscPrivate;/typedef struct _GtkMiscPrivate{} GtkMiscPrivate;/' final.h
sed -i 's/typedef struct _GtkMenuShellPrivate GtkMenuShellPrivate;/typedef struct _GtkMenuShellPrivate{} GtkMenuShellPrivate;/' final.h
sed -i 's/typedef struct _GtkMenuPrivate GtkMenuPrivate;/typedef struct _GtkMenuPrivate{} GtkMenuPrivate;/' final.h
sed -i 's/typedef struct _GtkLabelPrivate       GtkLabelPrivate;/typedef struct _GtkLabelPrivate{} GtkLabelPrivate;/' final.h
sed -i 's/typedef struct _GtkLabelSelectionInfo GtkLabelSelectionInfo;/typedef struct _GtkLabelSelectionInfo{} GtkLabelSelectionInfo;/' final.h
sed -i 's/typedef struct _GtkAccelLabelPrivate GtkAccelLabelPrivate;/typedef struct _GtkAccelLabelPrivate{} GtkAccelLabelPrivate;/' final.h
sed -i 's/typedef struct _GtkAccelMap      GtkAccelMap;/typedef struct _GtkAccelMap{} GtkAccelMap;/' final.h
sed -i 's/typedef struct _GtkAccelMapClass GtkAccelMapClass;/typedef struct _GtkAccelMapClass{} GtkAccelMapClass;/' final.h
sed -i 's/typedef struct _GtkAccessiblePrivate GtkAccessiblePrivate;/typedef struct _GtkAccessiblePrivate{} GtkAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkActionable                               GtkActionable;/typedef struct _GtkActionable{} GtkActionable;/' final.h
sed -i 's/typedef struct _GtkActionBarPrivate       GtkActionBarPrivate;/typedef struct _GtkActionBarPrivate{} GtkActionBarPrivate;/' final.h
sed -i 's/typedef struct _GtkAdjustmentPrivate  GtkAdjustmentPrivate;/typedef struct _GtkAdjustmentPrivate{} GtkAdjustmentPrivate;/' final.h
sed -i 's/typedef struct _GtkAppChooser GtkAppChooser;/typedef struct _GtkAppChooser{} GtkAppChooser;/' final.h
sed -i 's/typedef struct _GtkAppChooserDialogPrivate GtkAppChooserDialogPrivate;/typedef struct _GtkAppChooserDialogPrivate{} GtkAppChooserDialogPrivate;/' final.h
sed -i 's/typedef struct _GtkBoxPrivate       GtkBoxPrivate;/typedef struct _GtkBoxPrivate{} GtkBoxPrivate;/' final.h
sed -i 's/typedef struct _GtkAppChooserWidgetPrivate GtkAppChooserWidgetPrivate;/typedef struct _GtkAppChooserWidgetPrivate{} GtkAppChooserWidgetPrivate;/' final.h
sed -i 's/typedef struct _GtkTreePath         GtkTreePath;/typedef struct _GtkTreePath{} GtkTreePath;/' final.h
sed -i 's/typedef struct _GtkTreeRowReference GtkTreeRowReference;/typedef struct _GtkTreeRowReference{} GtkTreeRowReference;/' final.h
sed -i 's/typedef struct _GtkTreeModel        GtkTreeModel;/typedef struct _GtkTreeModel{} GtkTreeModel;/' final.h
sed -i 's/typedef struct _GtkCellEditable      GtkCellEditable;/typedef struct _GtkCellEditable{} GtkCellEditable;/' final.h
sed -i 's/typedef struct _GtkCellRendererPrivate       GtkCellRendererPrivate;/typedef struct _GtkCellRendererPrivate{} GtkCellRendererPrivate;/' final.h
sed -i 's/typedef struct _GtkCellRendererClassPrivate  GtkCellRendererClassPrivate;/typedef struct _GtkCellRendererClassPrivate{} GtkCellRendererClassPrivate;/' final.h
sed -i 's/typedef struct _GtkTreeSortable      GtkTreeSortable;/typedef struct _GtkTreeSortable{} GtkTreeSortable;/' final.h
sed -i 's/typedef struct _GtkCellAreaPrivate       GtkCellAreaPrivate;/typedef struct _GtkCellAreaPrivate{} GtkCellAreaPrivate;/' final.h
sed -i 's/typedef struct _GtkTreeViewColumnPrivate GtkTreeViewColumnPrivate;/typedef struct _GtkTreeViewColumnPrivate{} GtkTreeViewColumnPrivate;/' final.h
sed -i 's/typedef struct _GtkTextTagPrivate      GtkTextTagPrivate;/typedef struct _GtkTextTagPrivate{} GtkTextTagPrivate;/' final.h
sed -i 's/typedef struct _GtkTargetList  GtkTargetList;/typedef struct _GtkTargetList{} GtkTargetList;/' final.h
sed -i 's/typedef struct _GtkEditable          GtkEditable;/typedef struct _GtkEditable{} GtkEditable;/' final.h
sed -i 's/typedef struct _GtkEntryBufferPrivate     GtkEntryBufferPrivate;/typedef struct _GtkEntryBufferPrivate{} GtkEntryBufferPrivate;/' final.h
sed -i 's/typedef struct _GtkListStorePrivate       GtkListStorePrivate;/typedef struct _GtkListStorePrivate{} GtkListStorePrivate;/' final.h
sed -i 's/typedef struct _GtkTreeModelFilterPrivate   GtkTreeModelFilterPrivate;/typedef struct _GtkTreeModelFilterPrivate{} GtkTreeModelFilterPrivate;/' final.h
sed -i 's/typedef struct _GtkEntryCompletionPrivate     GtkEntryCompletionPrivate;/typedef struct _GtkEntryCompletionPrivate{} GtkEntryCompletionPrivate;/' final.h
sed -i 's/typedef struct _GtkImagePrivate       GtkImagePrivate;/typedef struct _GtkImagePrivate{} GtkImagePrivate;/' final.h
sed -i 's/typedef struct _GtkEntryPrivate       GtkEntryPrivate;/typedef struct _GtkEntryPrivate{} GtkEntryPrivate;/' final.h
sed -i 's/typedef struct _GtkTreeViewPrivate    GtkTreeViewPrivate;/typedef struct _GtkTreeViewPrivate{} GtkTreeViewPrivate;/' final.h
sed -i 's/typedef struct _GtkComboBoxPrivate GtkComboBoxPrivate;/typedef struct _GtkComboBoxPrivate{} GtkComboBoxPrivate;/' final.h
sed -i 's/typedef struct _GtkAppChooserButtonPrivate GtkAppChooserButtonPrivate;/typedef struct _GtkAppChooserButtonPrivate{} GtkAppChooserButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkApplicationWindowPrivate GtkApplicationWindowPrivate;/typedef struct _GtkApplicationWindowPrivate{} GtkApplicationWindowPrivate;/' final.h
sed -i 's/typedef struct _GtkFramePrivate       GtkFramePrivate;/typedef struct _GtkFramePrivate{} GtkFramePrivate;/' final.h
sed -i 's/typedef struct _GtkAspectFramePrivate       GtkAspectFramePrivate;/typedef struct _GtkAspectFramePrivate{} GtkAspectFramePrivate;/' final.h
sed -i 's/typedef struct _GtkAssistantPrivate GtkAssistantPrivate;/typedef struct _GtkAssistantPrivate{} GtkAssistantPrivate;/' final.h
sed -i 's/typedef struct _GtkButtonBoxPrivate       GtkButtonBoxPrivate;/typedef struct _GtkButtonBoxPrivate{} GtkButtonBoxPrivate;/' final.h
sed -i 's/typedef struct _GtkBuilderPrivate GtkBuilderPrivate;/typedef struct _GtkBuilderPrivate{} GtkBuilderPrivate;/' final.h
sed -i 's/typedef struct _GtkBuildable      GtkBuildable;/typedef struct _GtkBuildable{} GtkBuildable;/' final.h
sed -i 's/typedef struct _GtkButtonPrivate      GtkButtonPrivate;/typedef struct _GtkButtonPrivate{} GtkButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkCalendarPrivate     GtkCalendarPrivate;/typedef struct _GtkCalendarPrivate{} GtkCalendarPrivate;/' final.h
sed -i 's/typedef struct _GtkCellAreaBoxPrivate       GtkCellAreaBoxPrivate;/typedef struct _GtkCellAreaBoxPrivate{} GtkCellAreaBoxPrivate;/' final.h
sed -i 's/typedef struct _GtkCellAreaContextPrivate       GtkCellAreaContextPrivate;/typedef struct _GtkCellAreaContextPrivate{} GtkCellAreaContextPrivate;/' final.h
sed -i 's/typedef struct _GtkCellLayout           GtkCellLayout;/typedef struct _GtkCellLayout{} GtkCellLayout;/' final.h
sed -i 's/typedef struct _GtkCellRendererTextPrivate       GtkCellRendererTextPrivate;/typedef struct _GtkCellRendererTextPrivate{} GtkCellRendererTextPrivate;/' final.h
sed -i 's/typedef struct _GtkCellRendererAccelPrivate       GtkCellRendererAccelPrivate;/typedef struct _GtkCellRendererAccelPrivate{} GtkCellRendererAccelPrivate;/' final.h
sed -i 's/typedef struct _GtkCellRendererComboPrivate       GtkCellRendererComboPrivate;/typedef struct _GtkCellRendererComboPrivate{} GtkCellRendererComboPrivate;/' final.h
sed -i 's/typedef struct _GtkCellRendererPixbufPrivate       GtkCellRendererPixbufPrivate;/typedef struct _GtkCellRendererPixbufPrivate{} GtkCellRendererPixbufPrivate;/' final.h
sed -i 's/typedef struct _GtkCellRendererProgressPrivate  GtkCellRendererProgressPrivate;/typedef struct _GtkCellRendererProgressPrivate{} GtkCellRendererProgressPrivate;/' final.h
sed -i 's/typedef struct _GtkCellRendererSpinPrivate GtkCellRendererSpinPrivate;/typedef struct _GtkCellRendererSpinPrivate{} GtkCellRendererSpinPrivate;/' final.h
sed -i 's/typedef struct _GtkCellRendererSpinnerPrivate GtkCellRendererSpinnerPrivate;/typedef struct _GtkCellRendererSpinnerPrivate{} GtkCellRendererSpinnerPrivate;/' final.h
sed -i 's/typedef struct _GtkCellRendererTogglePrivate       GtkCellRendererTogglePrivate;/typedef struct _GtkCellRendererTogglePrivate{} GtkCellRendererTogglePrivate;/' final.h
sed -i 's/typedef struct _GtkCellViewPrivate      GtkCellViewPrivate;/typedef struct _GtkCellViewPrivate{} GtkCellViewPrivate;/' final.h
sed -i 's/typedef struct _GtkToggleButtonPrivate       GtkToggleButtonPrivate;/typedef struct _GtkToggleButtonPrivate{} GtkToggleButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkMenuItemPrivate GtkMenuItemPrivate;/typedef struct _GtkMenuItemPrivate{} GtkMenuItemPrivate;/' final.h
sed -i 's/typedef struct _GtkCheckMenuItemPrivate       GtkCheckMenuItemPrivate;/typedef struct _GtkCheckMenuItemPrivate{} GtkCheckMenuItemPrivate;/' final.h
sed -i 's/typedef struct _GtkColorButtonPrivate   GtkColorButtonPrivate;/typedef struct _GtkColorButtonPrivate{} GtkColorButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkColorChooser          GtkColorChooser;/typedef struct _GtkColorChooser{} GtkColorChooser;/' final.h
sed -i 's/typedef struct _GtkColorChooserDialogPrivate GtkColorChooserDialogPrivate;/typedef struct _GtkColorChooserDialogPrivate{} GtkColorChooserDialogPrivate;/' final.h
sed -i 's/typedef struct _GtkColorChooserWidgetPrivate GtkColorChooserWidgetPrivate;/typedef struct _GtkColorChooserWidgetPrivate{} GtkColorChooserWidgetPrivate;/' final.h
sed -i 's/typedef struct _GtkComboBoxTextPrivate      GtkComboBoxTextPrivate;/typedef struct _GtkComboBoxTextPrivate{} GtkComboBoxTextPrivate;/' final.h
sed -i 's/typedef struct _GtkCssSection GtkCssSection;/typedef struct _GtkCssSection{} GtkCssSection;/' final.h
sed -i 's/typedef struct _GtkCssProviderPrivate GtkCssProviderPrivate;/typedef struct _GtkCssProviderPrivate{} GtkCssProviderPrivate;/' final.h
sed -i 's/typedef struct _GtkEventBoxPrivate GtkEventBoxPrivate;/typedef struct _GtkEventBoxPrivate{} GtkEventBoxPrivate;/' final.h
sed -i 's/typedef struct _GtkEventController GtkEventController;/typedef struct _GtkEventController{} GtkEventController;/' final.h
sed -i 's/typedef struct _GtkEventControllerClass GtkEventControllerClass;/typedef struct _GtkEventControllerClass{} GtkEventControllerClass;/' final.h
sed -i 's/typedef struct _GtkExpanderPrivate GtkExpanderPrivate;/typedef struct _GtkExpanderPrivate{} GtkExpanderPrivate;/' final.h
sed -i 's/typedef struct _GtkFixedPrivate       GtkFixedPrivate;/typedef struct _GtkFixedPrivate{} GtkFixedPrivate;/' final.h
sed -i 's/typedef struct _GtkFileFilter     GtkFileFilter;/typedef struct _GtkFileFilter{} GtkFileFilter;/' final.h
sed -i 's/typedef struct _GtkFileChooser      GtkFileChooser;/typedef struct _GtkFileChooser{} GtkFileChooser;/' final.h
sed -i 's/typedef struct _GtkFileChooserButtonPrivate GtkFileChooserButtonPrivate;/typedef struct _GtkFileChooserButtonPrivate{} GtkFileChooserButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkFileChooserDialogPrivate GtkFileChooserDialogPrivate;/typedef struct _GtkFileChooserDialogPrivate{} GtkFileChooserDialogPrivate;/' final.h
sed -i 's/typedef struct _GtkFileChooserWidgetPrivate GtkFileChooserWidgetPrivate;/typedef struct _GtkFileChooserWidgetPrivate{} GtkFileChooserWidgetPrivate;/' final.h
sed -i 's/typedef struct _GtkFontButtonPrivate GtkFontButtonPrivate;/typedef struct _GtkFontButtonPrivate{} GtkFontButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkFontChooser      GtkFontChooser;/typedef struct _GtkFontChooser{} GtkFontChooser;/' final.h
sed -i 's/typedef struct _GtkFontChooserDialogPrivate       GtkFontChooserDialogPrivate;/typedef struct _GtkFontChooserDialogPrivate{} GtkFontChooserDialogPrivate;/' final.h
sed -i 's/typedef struct _GtkFontChooserWidgetPrivate       GtkFontChooserWidgetPrivate;/typedef struct _GtkFontChooserWidgetPrivate{} GtkFontChooserWidgetPrivate;/' final.h
sed -i 's/typedef struct _GtkGesture GtkGesture;/typedef struct _GtkGesture{} GtkGesture;/' final.h
sed -i 's/typedef struct _GtkGestureClass GtkGestureClass;/typedef struct _GtkGestureClass{} GtkGestureClass;/' final.h
sed -i 's/typedef struct _GtkGestureSingle GtkGestureSingle;/typedef struct _GtkGestureSingle{} GtkGestureSingle;/' final.h
sed -i 's/typedef struct _GtkGestureSingleClass GtkGestureSingleClass;/typedef struct _GtkGestureSingleClass{} GtkGestureSingleClass;/' final.h
sed -i 's/typedef struct _GtkGestureDrag GtkGestureDrag;/typedef struct _GtkGestureDrag{} GtkGestureDrag;/' final.h
sed -i 's/typedef struct _GtkGestureDragClass GtkGestureDragClass;/typedef struct _GtkGestureDragClass{} GtkGestureDragClass;/' final.h
sed -i 's/typedef struct _GtkGestureLongPress GtkGestureLongPress;/typedef struct _GtkGestureLongPress{} GtkGestureLongPress;/' final.h
sed -i 's/typedef struct _GtkGestureLongPressClass GtkGestureLongPressClass;/typedef struct _GtkGestureLongPressClass{} GtkGestureLongPressClass;/' final.h
sed -i 's/typedef struct _GtkGestureMultiPress GtkGestureMultiPress;/typedef struct _GtkGestureMultiPress{} GtkGestureMultiPress;/' final.h
sed -i 's/typedef struct _GtkGestureMultiPressClass GtkGestureMultiPressClass;/typedef struct _GtkGestureMultiPressClass{} GtkGestureMultiPressClass;/' final.h
sed -i 's/typedef struct _GtkGesturePan GtkGesturePan;/typedef struct _GtkGesturePan{} GtkGesturePan;/' final.h
sed -i 's/typedef struct _GtkGesturePanClass GtkGesturePanClass;/typedef struct _GtkGesturePanClass{} GtkGesturePanClass;/' final.h
sed -i 's/typedef struct _GtkGestureRotate GtkGestureRotate;/typedef struct _GtkGestureRotate{} GtkGestureRotate;/' final.h
sed -i 's/typedef struct _GtkGestureRotateClass GtkGestureRotateClass;/typedef struct _GtkGestureRotateClass{} GtkGestureRotateClass;/' final.h
sed -i 's/typedef struct _GtkGestureSwipe GtkGestureSwipe;/typedef struct _GtkGestureSwipe{} GtkGestureSwipe;/' final.h
sed -i 's/typedef struct _GtkGestureSwipeClass GtkGestureSwipeClass;/typedef struct _GtkGestureSwipeClass{} GtkGestureSwipeClass;/' final.h
sed -i 's/typedef struct _GtkGestureZoom GtkGestureZoom;/typedef struct _GtkGestureZoom{} GtkGestureZoom;/' final.h
sed -i 's/typedef struct _GtkGestureZoomClass GtkGestureZoomClass;/typedef struct _GtkGestureZoomClass{} GtkGestureZoomClass;/' final.h
sed -i 's/typedef struct _GtkGridPrivate       GtkGridPrivate;/typedef struct _GtkGridPrivate{} GtkGridPrivate;/' final.h
sed -i 's/typedef struct _GtkHeaderBarPrivate       GtkHeaderBarPrivate;/typedef struct _GtkHeaderBarPrivate{} GtkHeaderBarPrivate;/' final.h
sed -i 's/typedef struct _GtkIconFactoryPrivate       GtkIconFactoryPrivate;/typedef struct _GtkIconFactoryPrivate{} GtkIconFactoryPrivate;/' final.h
sed -i 's/typedef struct _GtkStylePropertiesPrivate GtkStylePropertiesPrivate;/typedef struct _GtkStylePropertiesPrivate{} GtkStylePropertiesPrivate;/' final.h
sed -i 's/typedef struct _GtkSymbolicColor GtkSymbolicColor;/typedef struct _GtkSymbolicColor{} GtkSymbolicColor;/' final.h
sed -i 's/typedef struct _GtkGradient GtkGradient;/typedef struct _GtkGradient{} GtkGradient;/' final.h
sed -i 's/typedef struct _GtkStyleProvider GtkStyleProvider;/typedef struct _GtkStyleProvider{} GtkStyleProvider;/' final.h
sed -i 's/typedef struct _GtkStyleContextPrivate GtkStyleContextPrivate;/typedef struct _GtkStyleContextPrivate{} GtkStyleContextPrivate;/' final.h
sed -i 's/typedef struct _GtkIconInfo         GtkIconInfo;/typedef struct _GtkIconInfo{} GtkIconInfo;/' final.h
sed -i 's/typedef struct _GtkIconInfoClass    GtkIconInfoClass;/typedef struct _GtkIconInfoClass{} GtkIconInfoClass;/' final.h
sed -i 's/typedef struct _GtkIconThemePrivate GtkIconThemePrivate;/typedef struct _GtkIconThemePrivate{} GtkIconThemePrivate;/' final.h
sed -i 's/typedef struct _GtkIconViewPrivate    GtkIconViewPrivate;/typedef struct _GtkIconViewPrivate{} GtkIconViewPrivate;/' final.h
sed -i 's/typedef struct _GtkIMContextSimplePrivate       GtkIMContextSimplePrivate;/typedef struct _GtkIMContextSimplePrivate{} GtkIMContextSimplePrivate;/' final.h
sed -i 's/typedef struct _GtkIMMulticontextPrivate GtkIMMulticontextPrivate;/typedef struct _GtkIMMulticontextPrivate{} GtkIMMulticontextPrivate;/' final.h
sed -i 's/typedef struct _GtkInfoBarPrivate GtkInfoBarPrivate;/typedef struct _GtkInfoBarPrivate{} GtkInfoBarPrivate;/' final.h
sed -i 's/typedef struct _GtkInvisiblePrivate       GtkInvisiblePrivate;/typedef struct _GtkInvisiblePrivate{} GtkInvisiblePrivate;/' final.h
sed -i 's/typedef struct _GtkLayoutPrivate       GtkLayoutPrivate;/typedef struct _GtkLayoutPrivate{} GtkLayoutPrivate;/' final.h
sed -i 's/typedef struct _GtkLevelBarPrivate GtkLevelBarPrivate;/typedef struct _GtkLevelBarPrivate{} GtkLevelBarPrivate;/' final.h
sed -i 's/typedef struct _GtkLinkButtonPrivate	GtkLinkButtonPrivate;/typedef struct _GtkLinkButtonPrivate{} GtkLinkButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkLockButtonPrivate GtkLockButtonPrivate;/typedef struct _GtkLockButtonPrivate{} GtkLockButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkMenuBarPrivate  GtkMenuBarPrivate;/typedef struct _GtkMenuBarPrivate{} GtkMenuBarPrivate;/' final.h
sed -i 's/typedef struct _GtkPopoverPrivate GtkPopoverPrivate;/typedef struct _GtkPopoverPrivate{} GtkPopoverPrivate;/' final.h
sed -i 's/typedef struct _GtkMenuButtonPrivate GtkMenuButtonPrivate;/typedef struct _GtkMenuButtonPrivate{} GtkMenuButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkSizeGroupPrivate       GtkSizeGroupPrivate;/typedef struct _GtkSizeGroupPrivate{} GtkSizeGroupPrivate;/' final.h
sed -i 's/typedef struct _GtkToolItemPrivate GtkToolItemPrivate;/typedef struct _GtkToolItemPrivate{} GtkToolItemPrivate;/' final.h
sed -i 's/typedef struct _GtkToolButtonPrivate GtkToolButtonPrivate;/typedef struct _GtkToolButtonPrivate{} GtkToolButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkMenuToolButtonPrivate GtkMenuToolButtonPrivate;/typedef struct _GtkMenuToolButtonPrivate{} GtkMenuToolButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkMessageDialogPrivate       GtkMessageDialogPrivate;/typedef struct _GtkMessageDialogPrivate{} GtkMessageDialogPrivate;/' final.h
sed -i 's/typedef struct _GtkModelButton        GtkModelButton;/typedef struct _GtkModelButton{} GtkModelButton;/' final.h
sed -i 's/typedef struct _GtkMountOperationPrivate  GtkMountOperationPrivate;/typedef struct _GtkMountOperationPrivate{} GtkMountOperationPrivate;/' final.h
sed -i 's/typedef struct _GtkNotebookPrivate       GtkNotebookPrivate;/typedef struct _GtkNotebookPrivate{} GtkNotebookPrivate;/' final.h
sed -i 's/typedef struct _GtkOrientable       GtkOrientable;/typedef struct _GtkOrientable{} GtkOrientable;/' final.h
sed -i 's/typedef struct _GtkOverlayPrivate  GtkOverlayPrivate;/typedef struct _GtkOverlayPrivate{} GtkOverlayPrivate;/' final.h
sed -i 's/typedef struct _GtkPaperSize GtkPaperSize;/typedef struct _GtkPaperSize{} GtkPaperSize;/' final.h
sed -i 's/typedef struct _GtkPageSetup GtkPageSetup;/typedef struct _GtkPageSetup{} GtkPageSetup;/' final.h
sed -i 's/typedef struct _GtkPanedPrivate GtkPanedPrivate;/typedef struct _GtkPanedPrivate{} GtkPanedPrivate;/' final.h
sed -i 's/typedef struct _GtkPlacesSidebar GtkPlacesSidebar;/typedef struct _GtkPlacesSidebar{} GtkPlacesSidebar;/' final.h
sed -i 's/typedef struct _GtkPlacesSidebarClass GtkPlacesSidebarClass;/typedef struct _GtkPlacesSidebarClass{} GtkPlacesSidebarClass;/' final.h
sed -i 's/typedef struct _GtkPopoverMenu GtkPopoverMenu;/typedef struct _GtkPopoverMenu{} GtkPopoverMenu;/' final.h
sed -i 's/typedef struct _GtkPrintContext GtkPrintContext;/typedef struct _GtkPrintContext{} GtkPrintContext;/' final.h
sed -i 's/typedef struct _GtkPrintSettings GtkPrintSettings;/typedef struct _GtkPrintSettings{} GtkPrintSettings;/' final.h
sed -i 's/typedef struct _GtkPrintOperationPreview      GtkPrintOperationPreview;/typedef struct _GtkPrintOperationPreview{} GtkPrintOperationPreview;/' final.h
sed -i 's/typedef struct _GtkPrintOperationPrivate GtkPrintOperationPrivate;/typedef struct _GtkPrintOperationPrivate{} GtkPrintOperationPrivate;/' final.h
sed -i 's/typedef struct _GtkProgressBarPrivate       GtkProgressBarPrivate;/typedef struct _GtkProgressBarPrivate{} GtkProgressBarPrivate;/' final.h
sed -i 's/typedef struct _GtkRadioButtonPrivate       GtkRadioButtonPrivate;/typedef struct _GtkRadioButtonPrivate{} GtkRadioButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkRadioMenuItemPrivate       GtkRadioMenuItemPrivate;/typedef struct _GtkRadioMenuItemPrivate{} GtkRadioMenuItemPrivate;/' final.h
sed -i 's/typedef struct _GtkToggleToolButtonPrivate GtkToggleToolButtonPrivate;/typedef struct _GtkToggleToolButtonPrivate{} GtkToggleToolButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkRangePrivate       GtkRangePrivate;/typedef struct _GtkRangePrivate{} GtkRangePrivate;/' final.h
sed -i 's/typedef struct _GtkRecentInfo		GtkRecentInfo;/typedef struct _GtkRecentInfo{} GtkRecentInfo;/' final.h
sed -i 's/typedef struct _GtkRecentManagerPrivate GtkRecentManagerPrivate;/typedef struct _GtkRecentManagerPrivate{} GtkRecentManagerPrivate;/' final.h
sed -i 's/typedef struct _GtkRecentFilter		GtkRecentFilter;/typedef struct _GtkRecentFilter{} GtkRecentFilter;/' final.h
sed -i 's/typedef struct _GtkRecentChooser      GtkRecentChooser;/typedef struct _GtkRecentChooser{} GtkRecentChooser;/' final.h
sed -i 's/typedef struct _GtkRecentChooserDialogPrivate GtkRecentChooserDialogPrivate;/typedef struct _GtkRecentChooserDialogPrivate{} GtkRecentChooserDialogPrivate;/' final.h
sed -i 's/typedef struct _GtkRecentChooserMenuPrivate	GtkRecentChooserMenuPrivate;/typedef struct _GtkRecentChooserMenuPrivate{} GtkRecentChooserMenuPrivate;/' final.h
sed -i 's/typedef struct _GtkRecentChooserWidgetPrivate GtkRecentChooserWidgetPrivate;/typedef struct _GtkRecentChooserWidgetPrivate{} GtkRecentChooserWidgetPrivate;/' final.h
sed -i 's/typedef struct _GtkScalePrivate       GtkScalePrivate;/typedef struct _GtkScalePrivate{} GtkScalePrivate;/' final.h
sed -i 's/typedef struct _GtkScaleButtonPrivate GtkScaleButtonPrivate;/typedef struct _GtkScaleButtonPrivate{} GtkScaleButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkScrollable          GtkScrollable;/typedef struct _GtkScrollable{} GtkScrollable;/' final.h
sed -i 's/typedef struct _GtkScrolledWindowPrivate       GtkScrolledWindowPrivate;/typedef struct _GtkScrolledWindowPrivate{} GtkScrolledWindowPrivate;/' final.h
sed -i 's/typedef struct _GtkSeparatorPrivate       GtkSeparatorPrivate;/typedef struct _GtkSeparatorPrivate{} GtkSeparatorPrivate;/' final.h
sed -i 's/typedef struct _GtkSeparatorToolItemPrivate GtkSeparatorToolItemPrivate;/typedef struct _GtkSeparatorToolItemPrivate{} GtkSeparatorToolItemPrivate;/' final.h
sed -i 's/typedef struct _GtkSettingsPrivate GtkSettingsPrivate;/typedef struct _GtkSettingsPrivate{} GtkSettingsPrivate;/' final.h
sed -i 's/typedef struct _GtkShortcutsGroup         GtkShortcutsGroup;/typedef struct _GtkShortcutsGroup{} GtkShortcutsGroup;/' final.h
sed -i 's/typedef struct _GtkShortcutsGroupClass    GtkShortcutsGroupClass;/typedef struct _GtkShortcutsGroupClass{} GtkShortcutsGroupClass;/' final.h
sed -i 's/typedef struct _GtkShortcutsSection      GtkShortcutsSection;/typedef struct _GtkShortcutsSection{} GtkShortcutsSection;/' final.h
sed -i 's/typedef struct _GtkShortcutsSectionClass GtkShortcutsSectionClass;/typedef struct _GtkShortcutsSectionClass{} GtkShortcutsSectionClass;/' final.h
sed -i 's/typedef struct _GtkShortcutsShortcut      GtkShortcutsShortcut;/typedef struct _GtkShortcutsShortcut{} GtkShortcutsShortcut;/' final.h
sed -i 's/typedef struct _GtkShortcutsShortcutClass GtkShortcutsShortcutClass;/typedef struct _GtkShortcutsShortcutClass{} GtkShortcutsShortcutClass;/' final.h
sed -i 's/typedef struct _GtkStackSidebarPrivate GtkStackSidebarPrivate;/typedef struct _GtkStackSidebarPrivate{} GtkStackSidebarPrivate;/' final.h
sed -i 's/typedef struct _GtkSpinButtonPrivate       GtkSpinButtonPrivate;/typedef struct _GtkSpinButtonPrivate{} GtkSpinButtonPrivate;/' final.h
sed -i 's/typedef struct _GtkSpinnerPrivate  GtkSpinnerPrivate;/typedef struct _GtkSpinnerPrivate{} GtkSpinnerPrivate;/' final.h
sed -i 's/typedef struct _GtkStatusbarPrivate       GtkStatusbarPrivate;/typedef struct _GtkStatusbarPrivate{} GtkStatusbarPrivate;/' final.h
sed -i 's/typedef struct _GtkSwitchPrivate        GtkSwitchPrivate;/typedef struct _GtkSwitchPrivate{} GtkSwitchPrivate;/' final.h
sed -i 's/typedef struct _GtkTextTagTablePrivate       GtkTextTagTablePrivate;/typedef struct _GtkTextTagTablePrivate{} GtkTextTagTablePrivate;/' final.h
sed -i 's/typedef struct _GtkTextBTree GtkTextBTree;/typedef struct _GtkTextBTree{} GtkTextBTree;/' final.h
sed -i 's/typedef struct _GtkTextBufferPrivate GtkTextBufferPrivate;/typedef struct _GtkTextBufferPrivate{} GtkTextBufferPrivate;/' final.h
sed -i 's/typedef struct _GtkTextViewPrivate GtkTextViewPrivate;/typedef struct _GtkTextViewPrivate{} GtkTextViewPrivate;/' final.h
sed -i 's/typedef struct _GtkToolbarPrivate       GtkToolbarPrivate;/typedef struct _GtkToolbarPrivate{} GtkToolbarPrivate;/' final.h
sed -i 's/typedef struct _GtkToolItemGroupPrivate GtkToolItemGroupPrivate;/typedef struct _GtkToolItemGroupPrivate{} GtkToolItemGroupPrivate;/' final.h
sed -i 's/typedef struct _GtkToolPalettePrivate    GtkToolPalettePrivate;/typedef struct _GtkToolPalettePrivate{} GtkToolPalettePrivate;/' final.h
sed -i 's/typedef struct _GtkToolShell           GtkToolShell;/typedef struct _GtkToolShell{} GtkToolShell;/' final.h
sed -i 's/typedef struct _GtkTreeDragSource      GtkTreeDragSource;/typedef struct _GtkTreeDragSource{} GtkTreeDragSource;/' final.h
sed -i 's/typedef struct _GtkTreeDragDest      GtkTreeDragDest;/typedef struct _GtkTreeDragDest{} GtkTreeDragDest;/' final.h
sed -i 's/typedef struct _GtkTreeModelSortPrivate GtkTreeModelSortPrivate;/typedef struct _GtkTreeModelSortPrivate{} GtkTreeModelSortPrivate;/' final.h
sed -i 's/typedef struct _GtkTreeSelectionPrivate      GtkTreeSelectionPrivate;/typedef struct _GtkTreeSelectionPrivate{} GtkTreeSelectionPrivate;/' final.h
sed -i 's/typedef struct _GtkTreeStorePrivate GtkTreeStorePrivate;/typedef struct _GtkTreeStorePrivate{} GtkTreeStorePrivate;/' final.h
sed -i 's/typedef struct _GtkViewportPrivate       GtkViewportPrivate;/typedef struct _GtkViewportPrivate{} GtkViewportPrivate;/' final.h
sed -i 's/typedef struct _GtkArrowPrivate       GtkArrowPrivate;/typedef struct _GtkArrowPrivate{} GtkArrowPrivate;/' final.h
sed -i 's/typedef struct _GtkActionPrivate GtkActionPrivate;/typedef struct _GtkActionPrivate{} GtkActionPrivate;/' final.h
sed -i 's/typedef struct _GtkActivatable      GtkActivatable;/typedef struct _GtkActivatable{} GtkActivatable;/' final.h
sed -i 's/typedef struct _GtkActionGroupPrivate GtkActionGroupPrivate;/typedef struct _GtkActionGroupPrivate{} GtkActionGroupPrivate;/' final.h
sed -i 's/typedef struct _GtkAlignmentPrivate       GtkAlignmentPrivate;/typedef struct _GtkAlignmentPrivate{} GtkAlignmentPrivate;/' final.h
sed -i 's/typedef struct _GtkColorSelectionPrivate  GtkColorSelectionPrivate;/typedef struct _GtkColorSelectionPrivate{} GtkColorSelectionPrivate;/' final.h
sed -i 's/typedef struct _GtkColorSelectionDialogPrivate       GtkColorSelectionDialogPrivate;/typedef struct _GtkColorSelectionDialogPrivate{} GtkColorSelectionDialogPrivate;/' final.h
sed -i 's/typedef struct _GtkFontSelectionPrivate       GtkFontSelectionPrivate;/typedef struct _GtkFontSelectionPrivate{} GtkFontSelectionPrivate;/' final.h
sed -i 's/typedef struct _GtkFontSelectionDialogPrivate       GtkFontSelectionDialogPrivate;/typedef struct _GtkFontSelectionDialogPrivate{} GtkFontSelectionDialogPrivate;/' final.h
sed -i 's/typedef struct _GtkHandleBoxPrivate       GtkHandleBoxPrivate;/typedef struct _GtkHandleBoxPrivate{} GtkHandleBoxPrivate;/' final.h
sed -i 's/typedef struct _GtkHSVPrivate       GtkHSVPrivate;/typedef struct _GtkHSVPrivate{} GtkHSVPrivate;/' final.h
sed -i 's/typedef struct _GtkImageMenuItemPrivate       GtkImageMenuItemPrivate;/typedef struct _GtkImageMenuItemPrivate{} GtkImageMenuItemPrivate;/' final.h
sed -i 's/typedef struct _GtkNumerableIconPrivate GtkNumerableIconPrivate;/typedef struct _GtkNumerableIconPrivate{} GtkNumerableIconPrivate;/' final.h
sed -i 's/typedef struct _GtkToggleActionPrivate GtkToggleActionPrivate;/typedef struct _GtkToggleActionPrivate{} GtkToggleActionPrivate;/' final.h
sed -i 's/typedef struct _GtkRadioActionPrivate GtkRadioActionPrivate;/typedef struct _GtkRadioActionPrivate{} GtkRadioActionPrivate;/' final.h
sed -i 's/typedef struct _GtkRcContext    GtkRcContext;/typedef struct _GtkRcContext{} GtkRcContext;/' final.h
sed -i 's/typedef struct _GtkRecentActionPrivate  GtkRecentActionPrivate;/typedef struct _GtkRecentActionPrivate{} GtkRecentActionPrivate;/' final.h
sed -i 's/typedef struct _GtkStatusIconPrivate GtkStatusIconPrivate;/typedef struct _GtkStatusIconPrivate{} GtkStatusIconPrivate;/' final.h
sed -i 's/typedef struct _GtkThemeEngine GtkThemeEngine;/typedef struct _GtkThemeEngine{} GtkThemeEngine;/' final.h
sed -i 's/typedef struct _GtkTablePrivate       GtkTablePrivate;/typedef struct _GtkTablePrivate{} GtkTablePrivate;/' final.h
sed -i 's/typedef struct _GtkTearoffMenuItemPrivate       GtkTearoffMenuItemPrivate;/typedef struct _GtkTearoffMenuItemPrivate{} GtkTearoffMenuItemPrivate;/' final.h
sed -i 's/typedef struct _GtkUIManagerPrivate GtkUIManagerPrivate;/typedef struct _GtkUIManagerPrivate{} GtkUIManagerPrivate;/' final.h
sed -i 's/typedef struct _GtkPageSetupUnixDialogPrivate  GtkPageSetupUnixDialogPrivate;/typedef struct _GtkPageSetupUnixDialogPrivate{} GtkPageSetupUnixDialogPrivate;/' final.h
sed -i 's/typedef struct _GtkPrinterPrivate   GtkPrinterPrivate;/typedef struct _GtkPrinterPrivate{} GtkPrinterPrivate;/' final.h
sed -i 's/typedef struct _GtkPrintJobPrivate   GtkPrintJobPrivate;/typedef struct _GtkPrintJobPrivate{} GtkPrintJobPrivate;/' final.h
sed -i 's/typedef struct _GtkWidgetAccessiblePrivate GtkWidgetAccessiblePrivate;/typedef struct _GtkWidgetAccessiblePrivate{} GtkWidgetAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkArrowAccessiblePrivate GtkArrowAccessiblePrivate;/typedef struct _GtkArrowAccessiblePrivate{} GtkArrowAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkCellAccessiblePrivate GtkCellAccessiblePrivate;/typedef struct _GtkCellAccessiblePrivate{} GtkCellAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkRendererCellAccessiblePrivate GtkRendererCellAccessiblePrivate;/typedef struct _GtkRendererCellAccessiblePrivate{} GtkRendererCellAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkBooleanCellAccessiblePrivate GtkBooleanCellAccessiblePrivate;/typedef struct _GtkBooleanCellAccessiblePrivate{} GtkBooleanCellAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkContainerAccessiblePrivate GtkContainerAccessiblePrivate;/typedef struct _GtkContainerAccessiblePrivate{} GtkContainerAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkButtonAccessiblePrivate GtkButtonAccessiblePrivate;/typedef struct _GtkButtonAccessiblePrivate{} GtkButtonAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkCellAccessibleParent GtkCellAccessibleParent;/typedef struct _GtkCellAccessibleParent{} GtkCellAccessibleParent;/' final.h
sed -i 's/typedef struct _GtkMenuItemAccessiblePrivate GtkMenuItemAccessiblePrivate;/typedef struct _GtkMenuItemAccessiblePrivate{} GtkMenuItemAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkCheckMenuItemAccessiblePrivate GtkCheckMenuItemAccessiblePrivate;/typedef struct _GtkCheckMenuItemAccessiblePrivate{} GtkCheckMenuItemAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkComboBoxAccessiblePrivate GtkComboBoxAccessiblePrivate;/typedef struct _GtkComboBoxAccessiblePrivate{} GtkComboBoxAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkContainerCellAccessiblePrivate GtkContainerCellAccessiblePrivate;/typedef struct _GtkContainerCellAccessiblePrivate{} GtkContainerCellAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkEntryAccessiblePrivate GtkEntryAccessiblePrivate;/typedef struct _GtkEntryAccessiblePrivate{} GtkEntryAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkExpanderAccessiblePrivate GtkExpanderAccessiblePrivate;/typedef struct _GtkExpanderAccessiblePrivate{} GtkExpanderAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkFlowBoxAccessiblePrivate GtkFlowBoxAccessiblePrivate;/typedef struct _GtkFlowBoxAccessiblePrivate{} GtkFlowBoxAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkFrameAccessiblePrivate GtkFrameAccessiblePrivate;/typedef struct _GtkFrameAccessiblePrivate{} GtkFrameAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkIconViewAccessiblePrivate GtkIconViewAccessiblePrivate;/typedef struct _GtkIconViewAccessiblePrivate{} GtkIconViewAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkImageAccessiblePrivate GtkImageAccessiblePrivate;/typedef struct _GtkImageAccessiblePrivate{} GtkImageAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkImageCellAccessiblePrivate GtkImageCellAccessiblePrivate;/typedef struct _GtkImageCellAccessiblePrivate{} GtkImageCellAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkLabelAccessiblePrivate GtkLabelAccessiblePrivate;/typedef struct _GtkLabelAccessiblePrivate{} GtkLabelAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkLevelBarAccessiblePrivate GtkLevelBarAccessiblePrivate;/typedef struct _GtkLevelBarAccessiblePrivate{} GtkLevelBarAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkLinkButtonAccessiblePrivate GtkLinkButtonAccessiblePrivate;/typedef struct _GtkLinkButtonAccessiblePrivate{} GtkLinkButtonAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkListBoxAccessiblePrivate GtkListBoxAccessiblePrivate;/typedef struct _GtkListBoxAccessiblePrivate{} GtkListBoxAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkLockButtonAccessiblePrivate GtkLockButtonAccessiblePrivate;/typedef struct _GtkLockButtonAccessiblePrivate{} GtkLockButtonAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkMenuShellAccessiblePrivate GtkMenuShellAccessiblePrivate;/typedef struct _GtkMenuShellAccessiblePrivate{} GtkMenuShellAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkMenuAccessiblePrivate GtkMenuAccessiblePrivate;/typedef struct _GtkMenuAccessiblePrivate{} GtkMenuAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkToggleButtonAccessiblePrivate GtkToggleButtonAccessiblePrivate;/typedef struct _GtkToggleButtonAccessiblePrivate{} GtkToggleButtonAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkMenuButtonAccessiblePrivate GtkMenuButtonAccessiblePrivate;/typedef struct _GtkMenuButtonAccessiblePrivate{} GtkMenuButtonAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkNotebookAccessiblePrivate GtkNotebookAccessiblePrivate;/typedef struct _GtkNotebookAccessiblePrivate{} GtkNotebookAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkNotebookPageAccessiblePrivate GtkNotebookPageAccessiblePrivate;/typedef struct _GtkNotebookPageAccessiblePrivate{} GtkNotebookPageAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkPanedAccessiblePrivate GtkPanedAccessiblePrivate;/typedef struct _GtkPanedAccessiblePrivate{} GtkPanedAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkProgressBarAccessiblePrivate GtkProgressBarAccessiblePrivate;/typedef struct _GtkProgressBarAccessiblePrivate{} GtkProgressBarAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkRadioButtonAccessiblePrivate GtkRadioButtonAccessiblePrivate;/typedef struct _GtkRadioButtonAccessiblePrivate{} GtkRadioButtonAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkRadioMenuItemAccessiblePrivate GtkRadioMenuItemAccessiblePrivate;/typedef struct _GtkRadioMenuItemAccessiblePrivate{} GtkRadioMenuItemAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkRangeAccessiblePrivate GtkRangeAccessiblePrivate;/typedef struct _GtkRangeAccessiblePrivate{} GtkRangeAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkScaleAccessiblePrivate GtkScaleAccessiblePrivate;/typedef struct _GtkScaleAccessiblePrivate{} GtkScaleAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkScaleButtonAccessiblePrivate GtkScaleButtonAccessiblePrivate;/typedef struct _GtkScaleButtonAccessiblePrivate{} GtkScaleButtonAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkScrolledWindowAccessiblePrivate GtkScrolledWindowAccessiblePrivate;/typedef struct _GtkScrolledWindowAccessiblePrivate{} GtkScrolledWindowAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkSpinButtonAccessiblePrivate GtkSpinButtonAccessiblePrivate;/typedef struct _GtkSpinButtonAccessiblePrivate{} GtkSpinButtonAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkSpinnerAccessiblePrivate GtkSpinnerAccessiblePrivate;/typedef struct _GtkSpinnerAccessiblePrivate{} GtkSpinnerAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkStatusbarAccessiblePrivate GtkStatusbarAccessiblePrivate;/typedef struct _GtkStatusbarAccessiblePrivate{} GtkStatusbarAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkSwitchAccessiblePrivate GtkSwitchAccessiblePrivate;/typedef struct _GtkSwitchAccessiblePrivate{} GtkSwitchAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkTextCellAccessiblePrivate GtkTextCellAccessiblePrivate;/typedef struct _GtkTextCellAccessiblePrivate{} GtkTextCellAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkTextViewAccessiblePrivate GtkTextViewAccessiblePrivate;/typedef struct _GtkTextViewAccessiblePrivate{} GtkTextViewAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkToplevelAccessiblePrivate GtkToplevelAccessiblePrivate;/typedef struct _GtkToplevelAccessiblePrivate{} GtkToplevelAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkTreeViewAccessiblePrivate GtkTreeViewAccessiblePrivate;/typedef struct _GtkTreeViewAccessiblePrivate{} GtkTreeViewAccessiblePrivate;/' final.h
sed -i 's/typedef struct _GtkWindowAccessiblePrivate GtkWindowAccessiblePrivate;/typedef struct _GtkWindowAccessiblePrivate{} GtkWindowAccessiblePrivate;/' final.h
sed -i 's/typedef struct GtkThemingEnginePrivate GtkThemingEnginePrivate;/typedef struct _GtkThemingEnginePrivate{} GtkThemingEnginePrivate;/' final.h
sed -i 's/typedef struct GtkPrintUnixDialogPrivate   GtkPrintUnixDialogPrivate;/typedef struct _GtkPrintUnixDialogPrivate{} GtkPrintUnixDialogPrivate;/' final.h

# for now we expand these macros manually with gcc -E
i='G_DECLARE_DERIVABLE_TYPE (GtkNativeDialog, gtk_native_dialog, GTK, NATIVE_DIALOG, GObject)
'
j='GType gtk_native_dialog_get_type (void);

typedef struct _GtkNativeDialog GtkNativeDialog;

typedef struct _GtkNativeDialogClass GtkNativeDialogClass;

struct _GtkNativeDialog
{
	GObject parent_instance;
};

static inline GtkNativeDialogClass * GTK_NATIVE_DIALOG_CLASS (gpointer ptr) {
	return (G_TYPE_CHECK_CLASS_CAST(ptr, gtk_native_dialog_get_type (), GtkNativeDialogClass));
}

static inline gboolean GTK_IS_NATIVE_DIALOG (gpointer ptr) {
	return (G_TYPE_CHECK_INSTANCE_TYPE (ptr, gtk_native_dialog_get_type ()));
}

static inline gboolean GTK_IS_NATIVE_DIALOG_CLASS (gpointer ptr) {
return (G_TYPE_CHECK_CLASS_TYPE(ptr, gtk_native_dialog_get_type ()));
}

static inline GtkNativeDialogClass * GTK_NATIVE_DIALOG_GET_CLASS (gpointer ptr) {
	return (G_TYPE_INSTANCE_GET_CLASS(ptr, gtk_native_dialog_get_type (), GtkNativeDialogClass));
}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" $final

i='G_DECLARE_FINAL_TYPE (GtkFileChooserNative, gtk_file_chooser_native, GTK, FILE_CHOOSER_NATIVE, GtkNativeDialog)
'
j='typedef struct _GtkFileChooserNative{} GtkFileChooserNative;

struct GtkFileChooserNativeClass
{
	GtkNativeDialogClass parent_class;
};

GType gtk_file_chooser_native_get_type (void);

#define GTK_IS_FILE_CHOOSER_NATIVE(o)        (GTK_TYPE_CHECK_INSTANCE_TYPE ((o), GTK_TYPE_FILE_CHOOSER_NATIVE))
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

# avoid empty when: statement
i="\
#ifdef G_PLATFORM_WIN32
#include <gtk/gtkbox.h>
#include <gtk/gtkwindow.h>
#endif
"
perl -0777 -p -i -e "s%\Q$i\E%%s" final.h

i="\
#ifndef GDK_DISABLE_DEPRECATION_WARNINGS
#if GDK_VERSION_MIN_REQUIRED >= GDK_VERSION_3_10
G_DEPRECATED
#endif
#endif
"
perl -0777 -p -i -e "s%\Q$i\E%%s" final.h

# remove these macros for now
i="\
#define gtk_widget_class_bind_template_callback(widget_class, callback) \\
  gtk_widget_class_bind_template_callback_full (GTK_WIDGET_CLASS (widget_class), \\
                                                #callback, \\
                                                G_CALLBACK (callback))
"
perl -0777 -p -i -e "s/\Q$i\E//s" final.h

i="\
#define gtk_widget_class_bind_template_child(widget_class, TypeName, member_name) \\
  gtk_widget_class_bind_template_child_full (widget_class, \\
                                             #member_name, \\
                                             FALSE, \\
                                             G_STRUCT_OFFSET (TypeName, member_name))
"
perl -0777 -p -i -e "s/\Q$i\E//s" final.h

i="\
#define gtk_widget_class_bind_template_child_internal(widget_class, TypeName, member_name) \\
  gtk_widget_class_bind_template_child_full (widget_class, \\
                                             #member_name, \\
                                             TRUE, \\
                                             G_STRUCT_OFFSET (TypeName, member_name))
"
perl -0777 -p -i -e "s/\Q$i\E//s" final.h

i="\
#define gtk_widget_class_bind_template_child_private(widget_class, TypeName, member_name) \\
  gtk_widget_class_bind_template_child_full (widget_class, \\
                                             #member_name, \\
                                             FALSE, \\
                                             G_PRIVATE_OFFSET (TypeName, member_name))
"
perl -0777 -p -i -e "s/\Q$i\E//s" final.h

i="\
#define gtk_widget_class_bind_template_child_internal_private(widget_class, TypeName, member_name) \\
  gtk_widget_class_bind_template_child_full (widget_class, \\
                                             #member_name, \\
                                             TRUE, \\
                                             G_PRIVATE_OFFSET (TypeName, member_name))
"
perl -0777 -p -i -e "s/\Q$i\E//s" final.h

i="\
#ifdef G_ENABLE_DEBUG

#define GTK_NOTE(type,action)                G_STMT_START { \\
    if (gtk_get_debug_flags () & GTK_DEBUG_##type)		    \\
       { action; };                          } G_STMT_END

#else /* !G_ENABLE_DEBUG */

#define GTK_NOTE(type, action)

#endif /* G_ENABLE_DEBUG */
"
perl -0777 -p -i -e "s%\Q$i\E%%s" final.h

i="\
struct GtkTextAppearance
{
  /*< public >*/
  GdkColor bg_color; /* pixel is taken for underline color */
  GdkColor fg_color; /* pixel is taken for strikethrough color */

  /* super/subscript rise, can be negative */
  gint rise;

  guint underline : 4;          /* PangoUnderline */
  guint strikethrough : 1;

  /* Whether to use background-related values; this is irrelevant for
   * the values struct when in a tag, but is used for the composite
   * values struct; it's true if any of the tags being composited
   * had background stuff set.
   */
  guint draw_bg : 1;

  /* These are only used when we are actually laying out and rendering
   * a paragraph; not when a GtkTextAppearance is part of a
   * GtkTextAttributes.
   */
  guint inside_selection : 1;
  guint is_text : 1;

  /* For the sad story of this bit of code, see
   * https://bugzilla.gnome.org/show_bug.cgi?id=711158
   */
#ifdef __GI_SCANNER__
  /* The scanner should only see the transparent union, so that its
   * content does not vary across architectures.
   */
  union {
    GdkRGBA *rgba[2];
    /*< private >*/
    guint padding[4];
  };
#else
  GdkRGBA *rgba[2];
#if (defined(__SIZEOF_INT__) && defined(__SIZEOF_POINTER__)) && (__SIZEOF_INT__ == __SIZEOF_POINTER__)
  /* unusable, just for ABI compat */
  /*< private >*/
  guint padding[2];
#endif
#endif
};
"
j="\
struct GtkTextAppearance
{
  /*< public >*/
  GdkColor bg_color; /* pixel is taken for underline color */
  GdkColor fg_color; /* pixel is taken for strikethrough color */

  /* super/subscript rise, can be negative */
  gint rise;

  guint underline : 4;          /* PangoUnderline */
  guint strikethrough : 1;

  /* Whether to use background-related values; this is irrelevant for
   * the values struct when in a tag, but is used for the composite
   * values struct; it's true if any of the tags being composited
   * had background stuff set.
   */
  guint draw_bg : 1;

  /* These are only used when we are actually laying out and rendering
   * a paragraph; not when a GtkTextAppearance is part of a
   * GtkTextAttributes.
   */
  guint inside_selection : 1;
  guint is_text : 1;

  /* For the sad story of this bit of code, see
   * https://bugzilla.gnome.org/show_bug.cgi?id=711158
   */
  union {
    GdkRGBA *rgba[2];
    /*< private >*/
    guint padding[4];
  };
};
"
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.h

i='struct GtkTextAttributes
{
  /*< private >*/
  guint refcount;

  /*< public >*/
  GtkTextAppearance appearance;

  GtkJustification justification;
  GtkTextDirection direction;

  PangoFontDescription *font;

  gdouble font_scale;

  gint left_margin;
  gint right_margin;
  gint indent;

  gint pixels_above_lines;
  gint pixels_below_lines;
  gint pixels_inside_wrap;

  PangoTabArray *tabs;

  GtkWrapMode wrap_mode;

  PangoLanguage *language;

  /*< private >*/
  GdkColor *pg_bg_color;

  /*< public >*/
  guint invisible : 1;
  guint bg_full_height : 1;
  guint editable : 1;
  guint no_fallback: 1;

  /*< private >*/
  GdkRGBA *pg_bg_rgba;

  /*< public >*/
  gint letter_spacing;

#ifdef __GI_SCANNER__
  /* The scanner should only see the transparent union, so that its
   * content does not vary across architectures.
   */
  union {
    gchar *font_features;
    /*< private >*/
    guint padding[2];
  };
#else
  gchar *font_features;
#if (defined(__SIZEOF_INT__) && defined(__SIZEOF_POINTER__)) && (__SIZEOF_INT__ == __SIZEOF_POINTER__)
  /* unusable, just for ABI compat */
  /*< private >*/
  guint padding[1];
#endif
#endif
};
'
j='struct GtkTextAttributes
{
  /*< private >*/
  guint refcount;

  /*< public >*/
  GtkTextAppearance appearance;

  GtkJustification justification;
  GtkTextDirection direction;

  PangoFontDescription *font;

  gdouble font_scale;

  gint left_margin;
  gint right_margin;
  gint indent;

  gint pixels_above_lines;
  gint pixels_below_lines;
  gint pixels_inside_wrap;

  PangoTabArray *tabs;

  GtkWrapMode wrap_mode;

  PangoLanguage *language;

  /*< private >*/
  GdkColor *pg_bg_color;

  /*< public >*/
  guint invisible : 1;
  guint bg_full_height : 1;
  guint editable : 1;
  guint no_fallback: 1;

  /*< private >*/
  GdkRGBA *pg_bg_rgba;

  /*< public >*/
  gint letter_spacing;

  union {
    gchar *font_features;
    guint padding[2];
  };
};
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.h

i='
#ifdef G_ENABLE_DEBUG

#define GTK_DEBUG_CHECK(type) G_UNLIKELY (gtk_get_debug_flags () & GTK_DEBUG_##type)

#define GTK_NOTE(type,action)                G_STMT_START {     \
    if (GTK_DEBUG_CHECK (type))		                        \
       { action; };                          } G_STMT_END

#else /* !G_ENABLE_DEBUG */

#define GTK_DEBUG_CHECK(type) 0
#define GTK_NOTE(type, action)

#endif /* G_ENABLE_DEBUG */
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.h

sed -i 's/\bgchar\b/char/g' $final

sed -i 's/\(#define\sGTK_\w\+ERROR\)\(\s\+(\?\w\+error_quark\s*()\s*)\?\)/\1()\2/g' $final
sed -i 's/\(#define\sGTK_TYPE_\w\+\)\(\s\+(\?\w\+_get_g\?type\s*()\s*)\?\)/\1()\2/g' $final

# this is very slow
#ruby ../func_alias_reorder.rb final.h GTK
sed -i "s/struct GtkTextIter {/struct GtkTextIter\n{/g" final.h

i='typedef enum /*< flags >*/
{
  GTK_TOOL_PALETTE_DRAG_ITEMS = (1 << 0),
  GTK_TOOL_PALETTE_DRAG_GROUPS = (1 << 1)
}
GtkToolPaletteDragTargets;
'
j='typedef enum /*< flags >*/
{
  GTK_TOOL_PALETTE_DRAG_ITEMS = (1 << 0),
  GTK_TOOL_PALETTE_DRAG_GROUPS = (1 << 1)
} GtkToolPaletteDragTargets;
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" $final

#ruby ~/ngtk3/common/struct_reorder.rb final.h
ruby ../struct_reorder.rb final.h

exit # terminate here when started with an argument
fi;

cd tmp_gtk
final="final.h" # the input file for c2nim
c2nim --nep1 --skipcomments --skipinclude $final
sed -i 's/ {\.bycopy\.}//g' final.nim

sed -i "s/^\s*$//g" final.nim
echo -e "\n\n\n\n"  >> final.nim

sed -i "s/\bg_Maxushort\b/G_MAXUSHORT/g" final.nim

perl -0777 -p -i -e "s~([=:] proc \(.*?\)(?:: (?:ptr )?\w+)?)~\1 {.cdecl.}~sg" final.nim

# we use our own defined pragma
sed -i "s/\bdynlib: lib\b/libgtk/g" final.nim

i='const
  headerfilename* = '
perl -0777 -p -i -e "s~\Q$i\E~  ### ~sg" final.nim

i=' {.deadCodeElim: on.}'
j='{.deadCodeElim: on.}

when defined(windows):
  const LIB_GTK* = "libgtk-3-0.dll"
elif defined(gtk_quartz):
  const LIB_GTK* = "libgtk-3.0.dylib"
elif defined(macosx):
  const LIB_GTK* = "libgtk-x11-3.0.dylib"
else:
  const LIB_GTK* = "libgtk-3.so(|.0)"

{.pragma: libgtk, cdecl, dynlib: LIB_GTK.}

IMPORTLIST

const
  GDK_MULTIHEAD_SAFE = true
  GTK_DISABLE_DEPRECATED = false

'
perl -0777 -p -i -e "s~\Q$i\E~$j~s" final.nim
sed -i 's/\bTimeT\b/Time/g' final.nim

sed  -i 's/  GtkAllocation\* = GdkRectangle/  GtkAllocation* = object/' final.nim

# fix c2nim --nep1 mess. We need this before glib_fix_T.rb call!
sed -i 's/[(][(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/(\1/g' final.nim
sed -i 's/, [(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/, \1/g' final.nim
perl -0777 -p -i -e 's/(  \(.*,)\n/\1/g' final.nim
sed -i 's/\(, \) \+/\1/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Cast\)(\(`\?\w\+`\?, \)\(gtk_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Instance_Get_Interface\)(\(`\?\w\+`\?, \)\(gtk_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Check_Class_Cast\)(\(`\?\w\+`\?, \)\(gtk_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Instance_Get_Class\)(\(`\?\w\+`\?, \)\(gtk_Type_\w\+, \)\(\w\+\))/\1(\2\3\u\4)/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Type\)(\(`\?\w\+`\?, \)\(gtk_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Class_Type\)(\(`\?\w\+`\?, \)\(gtk_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Value_Type\)(\(`\?\w\+`\?, \)\(gtk_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(g_Type_Check_Instance_Fundamental_Type\)(\(`\?\w\+`\?, \)\(gtk_Type_\w\+\))/\1(\2\3)/g' final.nim
sed -i 's/\(gTypeIsA\)(\(`\?\w\+`\?, \)\(gtk_Type_\w\+\))/\1(\2\3)/g' final.nim

sed -i 's/\bgtk\([A-Z]\w\+GetType()\)/\l\1/g' final.nim

i='proc gtk_Native_Dialog_Class*(`ptr`: Gpointer): ptr GtkNativeDialogClass {.inline.} =
  return g_Type_Check_Class_Cast(`ptr`, nativeDialogGetType(),
                                gtkNativeDialogClass)

proc gtk_Is_Native_Dialog*(`ptr`: Gpointer): Gboolean {.inline.} =
  return g_Type_Check_Instance_Type(`ptr`, nativeDialogGetType())

proc gtk_Is_Native_Dialog_Class*(`ptr`: Gpointer): Gboolean {.inline.} =
  return g_Type_Check_Class_Type(`ptr`, nativeDialogGetType())

proc gtk_Native_Dialog_Get_Class*(`ptr`: Gpointer): ptr GtkNativeDialogClass {.inline.} =
  return g_Type_Instance_Get_Class(`ptr`, nativeDialogGetType(),
                                  gtkNativeDialogClass)
'
j='proc nativeDialogClass*(`ptr`: Gpointer): ptr GtkNativeDialogClass =
  return g_Type_Check_Class_Cast(`ptr`, nativeDialogGetType(),
                                GtkNativeDialogClass)

proc isNativeDialog*(`ptr`: Gpointer): Gboolean =
  return g_Type_Check_Instance_Type(`ptr`, nativeDialogGetType())

proc isNativeDialogClass*(`ptr`: Gpointer): Gboolean =
  return g_Type_Check_Class_Type(`ptr`, nativeDialogGetType())

proc nativeDialogGetClass*(`ptr`: Gpointer): ptr GtkNativeDialogClass =
  return g_Type_Instance_Get_Class(`ptr`, nativeDialogGetType(),
                                  GtkNativeDialogClass)
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

ruby ../glib_fix_T.rb final.nim gtk3 Gtk
# that fix_new.rb has the _ bug!
ruby ../fix_new.rb final.nim
ruby ../glib_fix_proc.rb final.nim gtk
sed -i 's/\bGTK_PRINT_CAPABILITY_/GTK_PRINT_CAPABILITIES_/g' final.nim
sed -i 's/\bGTK_INPUT_HINT_/GTK_INPUT_HINTS_/g' final.nim
ruby ../glib_fix_enum_prefix.rb final.nim
sed  -i 's/  GtkAllocationObj\* = object/  GtkAllocationObj\* = GdkRectangle/' final.nim

sed -i -f ../glib_sedlist final.nim
sed -i -f ../gobject_sedlist final.nim
sed -i -f ../cairo_sedlist final.nim
sed -i -f ../pango_sedlist final.nim
sed -i -f ../gdk_pixbuf_sedlist final.nim
sed -i -f ../gdk3_sedlist final.nim
sed -i -f ../gio_sedlist final.nim
sed -i -f ../atk_sedlist final.nim

ruby ../fix_object_of.rb final.nim

i='  GtkApplicationClass* =  ptr GtkApplicationClassObj
  GtkApplicationClassPtr* = ptr GtkApplicationClassObj
  GtkApplicationClassObj*{.final.} = object of gio.GApplicationClassObj
    windowAdded*: proc (application: GtkApplication; window: GtkWindow) {.cdecl.}
    windowRemoved*: proc (application: GtkApplication; window: GtkWindow) {.cdecl.}
    padding*: array[12, Gpointer]
'
j='  GtkApplicationClass* =  ptr GtkApplicationClassObj
  GtkApplicationClassPtr* = ptr GtkApplicationClassObj
  GtkApplicationClassObj*{.final.} = object of gio.GApplicationClassObj
    windowAdded*: proc (application: GtkApplication; window: GtkWindow) {.cdecl.}
    windowRemoved*: proc (application: GtkApplication; window: GtkWindow) {.cdecl.}
    padding0: array[12, Gpointer]
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkWidget* =  ptr GtkWidgetObj
  GtkWidgetPtr* = ptr GtkWidgetObj
  GtkWidgetObj* = object
    parentInstance*: gobject.GInitiallyUnownedObj
    priv*: ptr GtkWidgetPrivateObj
'
j='type
  GtkWidget* =  ptr GtkWidgetObj
  GtkWidgetPtr* = ptr GtkWidgetObj
  GtkWidgetObj* = object of gobject.GInitiallyUnownedObj
    priv*: ptr GtkWidgetPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

# do not export priv and reserved
sed -i "s/\( priv[0-9]\?[0-9]\?[0-9]\?\)\*: /\1: /g" final.nim
sed -i "s/\(reserved[0-9]\?[0-9]\?[0-9]\?\)\*: /\1: /g" final.nim

i='type
  GtkUnit* {.size: sizeof(cint), pure.} = enum
    NONE, POINTS, INCH, MM


const
  GTK_UNIT_PIXEL* = gtk_Unit_None
'
j='type
  GtkUnit* {.size: sizeof(cint), pure.} = enum
    NONE, POINTS, INCH, MM

const
  GTK_UNIT_PIXEL* = GtkUnit.NONE
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkJunctionSides* {.size: sizeof(cint), pure.} = enum
    NONE = 0, CORNER_TOPLEFT = 1 shl 0,
    CORNER_TOPRIGHT = 1 shl 1, CORNER_BOTTOMLEFT = 1 shl 2,
    CORNER_BOTTOMRIGHT = 1 shl 3, TOP = (
        gtk_Junction_Corner_Topleft or gtk_Junction_Corner_Topright), GTK_JUNCTION_BOTTOM = (
        gtk_Junction_Corner_Bottomleft or gtk_Junction_Corner_Bottomright), GTK_JUNCTION_LEFT = (
        gtk_Junction_Corner_Topleft or gtk_Junction_Corner_Bottomleft), GTK_JUNCTION_RIGHT = (
        gtk_Junction_Corner_Topright or gtk_Junction_Corner_Bottomright)
'
j='type
  GtkJunctionSides* {.size: sizeof(cint), pure.} = enum
    NONE = 0,
    CORNER_TOPLEFT = 1 shl 0,
    CORNER_TOPRIGHT = 1 shl 1,
    TOP = (GtkJunctionSides.CORNER_TOPLEFT.ord or GtkJunctionSides.CORNER_TOPRIGHT.ord),
    CORNER_BOTTOMLEFT = 1 shl 2,
    LEFT = (GtkJunctionSides.CORNER_TOPLEFT.ord or GtkJunctionSides.CORNER_BOTTOMLEFT.ord),
    CORNER_BOTTOMRIGHT = 1 shl 3,
    RIGHT = (GtkJunctionSides.CORNER_TOPRIGHT.ord or GtkJunctionSides.CORNER_BOTTOMRIGHT.ord),
    BOTTOM = (GtkJunctionSides.CORNER_BOTTOMLEFT.ord or GtkJunctionSides.CORNER_BOTTOMRIGHT.ord)
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

# these enums are not covered by gdk3_sedlist -- that is OK, because it are enums :-)
sed  -i "s/PangoDirection/pango.Direction/g" final.nim
sed  -i "s/PangoWrapMode/pango.WrapMode/g" final.nim
sed  -i "s/PangoEllipsizeMode/pango.EllipsizeMode/g" final.nim
sed  -i "s/GdkModifierType/gdk3.ModifierType/g" final.nim
sed  -i "s/GdkEventMask/gdk3.EventMask/g" final.nim
sed  -i "s/GdkModifierIntent/gdk3.ModifierIntent/g" final.nim
sed  -i "s/GdkWindowTypeHint/gdk3.WindowTypeHint/g" final.nim
sed  -i "s/GdkGravity/gdk3.Gravity/g" final.nim
sed  -i "s/GdkWindowHints/gdk3.WindowHints/g" final.nim
sed  -i "s/GdkWindowEdge/gdk3.WindowEdge/g" final.nim
sed  -i "s/GdkDragAction/gdk3.DragAction/g" final.nim
sed  -i "s/GdkDragProtocol/gdk3.DragProtocol/g" final.nim
sed  -i "s/GdkGLProfile/gdk3.GLProfile/g" final.nim
sed  -i "s/AtkRole/atk.Role/g" final.nim
sed  -i "s/AtkCoordType/atk.CoordType/g" final.nim

# and this Atom is a special pointer -- also not covered by sedlist
sed  -i "s/GdkAtom/gdk3.Atom/g" final.nim

sed -i 's/^proc ref\*(/proc `ref`\*(/g' final.nim

i='
type
  GtkRcFlags* {.size: sizeof(cint), pure.} = enum
    FG = 1 shl 0, BG = 1 shl 1, TEXT = 1 shl 2, BASE = 1 shl 3
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='
  GtkRcStyle* =  ptr GtkRcStyleObj
  GtkRcStylePtr* = ptr GtkRcStyleObj
  GtkRcStyleObj*{.final.} = object of gobject.GObjectObj
    name*: cstring
    bgPixmapName*: array[5, cstring]
    fontDesc*: pango.FontDescription
    colorFlags*: array[5, GtkRcFlags]
    fg*: array[5, gdk3.ColorObj]
    bg*: array[5, gdk3.ColorObj]
    text*: array[5, gdk3.ColorObj]
    base*: array[5, gdk3.ColorObj]
    xthickness*: Gint
    ythickness*: Gint
    rcProperties*: glib.GArray
    rcStyleLists*: glib.GSList
    iconFactories*: glib.GSList
    engineSpecified* {.bitsize: 1.}: Guint
'
perl -0777 -p -i -e "s%\Q$j\E%$i$j%s" final.nim

# fix non final objects
sed  -i "s/GtkWidgetObj\*{\.final\.} = object of/GtkWidgetObj = object of/" final.nim
sed  -i "s/GtkWidgetClassObj\*{\.final\.} = object of/GtkWidgetClassObj = object of/" final.nim
sed  -i "s/GtkContainerClassObj\*{\.final\.} = object of/GtkContainerClassObj = object of/" final.nim
sed  -i "s/GtkBinClassObj\*{\.final\.} = object of/GtkBinClassObj* = object of/" final.nim
sed  -i "s/GtkBoxClassObj\*{\.final\.} = object of/GtkBoxClassObj = object of/" final.nim
sed  -i "s/GtkWindowClassObj\*{\.final\.} = object of/GtkWindowClassObj* = object of/" final.nim
sed  -i "s/GtkDialogClassObj\*{\.final\.} = object of/GtkDialogClassObj = object of/" final.nim
sed  -i "s/GtkLabelClassObj\*{\.final\.} = object of/GtkLabelClassObj = object of/" final.nim
sed  -i "s/GtkMiscClassObj\*{\.final\.} = object of/GtkMiscClassObj = object of/" final.nim
sed  -i "s/GtkMenuShellClassObj\*{\.final\.} = object of/GtkMenuShellClassObj = object of/" final.nim
sed  -i "s/GtkComboBoxObj\*{\.final\.} = object of/GtkComboBoxObj = object of/" final.nim
sed  -i "s/GtkComboBoxClassObj\*{\.final\.} = object of/GtkComboBoxClassObj = object of/" final.nim
sed  -i "s/GtkFrameClassObj\*{\.final\.} = object of/GtkFrameClassObj = object of/" final.nim
sed  -i "s/GtkCellAreaObj\*{\.final\.} = object of/GtkCellAreaObj = object of/" final.nim
sed  -i "s/GtkCellAreaClassObj\*{\.final\.} = object of/GtkCellAreaClassObj = object of/" final.nim
sed  -i "s/GtkCellRendererObj\*{\.final\.} = object of/GtkCellRendererObj = object of/" final.nim
sed  -i "s/GtkCellRendererClassObj\*{\.final\.} = object of/GtkCellRendererClassObj = object of/" final.nim
sed  -i "s/GtkCellRendererTextObj\*{\.final\.} = object of/GtkCellRendererTextObj = object of/" final.nim
sed  -i "s/GtkCellRendererTextClassObj\*{\.final\.} = object of/GtkCellRendererTextClassObj = object of/" final.nim
sed  -i "s/GtkButtonClassObj\*{\.final\.} = object of/GtkButtonClassObj* = object of/" final.nim
sed  -i "s/GtkTextMarkObj\*{\.final\.} = object of/GtkTextMarkObj* = object of/" final.nim
sed  -i "s/GtkTextMarkClassObj\*{\.final\.} = object of/GtkTextMarkClassObj* = object of/" final.nim
sed  -i "s/GtkTextBufferClassObj\*{\.final\.} = object of/GtkTextBufferClassObj* = object of/" final.nim
sed  -i "s/GtkTextViewObj\*{\.final\.} = object of/GtkTextViewObj* = object of/" final.nim
sed  -i "s/GtkTextViewClassObj\*{\.final\.} = object of/GtkTextViewClassObj* = object of/" final.nim
sed  -i "s/GtkButtonBoxClassObj\*{\.final\.} = object of/GtkButtonBoxClassObj = object of/" final.nim
sed  -i "s/GtkPanedClassObj\*{\.final\.} = object of/GtkPanedClassObj = object of/" final.nim
sed  -i "s/GtkToggleButtonClassObj\*{\.final\.} = object of/GtkToggleButtonClassObj = object of/" final.nim
sed  -i "s/GtkScaleButtonObj\*{\.final\.} = object of/GtkScaleButtonObj = object of/" final.nim
sed  -i "s/GtkScaleButtonClassObj\*{\.final\.} = object of/GtkScaleButtonClassObj = object of/" final.nim
sed  -i "s/GtkScaleClassObj\*{\.final\.} = object of/GtkScaleClassObj = object of/" final.nim
sed  -i "s/GtkToggleToolButtonClassObj\*{\.final\.} = object of/GtkToggleToolButtonClassObj = object of/" final.nim
sed  -i "s/GtkToggleToolButtonObj\*{\.final\.} = object of/GtkToggleToolButtonObj = object of/" final.nim
sed  -i "s/GtkCheckButtonClassObj\*{\.final\.} = object of/GtkCheckButtonClassObj = object of/" final.nim
sed  -i "s/GtkMenuItemClassObj\*{\.final\.} = object of/GtkMenuItemClassObj = object of/" final.nim
sed  -i "s/GtkMenuClassObj\*{\.final\.} = object of/GtkMenuClassObj = object of/" final.nim
sed  -i "s/GtkCheckMenuItemClassObj\*{\.final\.} = object of/GtkCheckMenuItemClassObj = object of/" final.nim
sed  -i "s/GtkIMContextObj\*{\.final\.} = object of/GtkIMContextObj = object of/" final.nim
sed  -i "s/GtkIMContextClassObj\*{\.final\.} = object of/GtkIMContextClassObj = object of/" final.nim
sed  -i "s/GtkToolItemObj\*{\.final\.} = object of/GtkToolItemObj = object of/" final.nim
sed  -i "s/GtkToolItemClassObj\*{\.final\.} = object of/GtkToolItemClassObj = object of/" final.nim
sed  -i "s/GtkToolButtonObj\*{\.final\.} = object of/GtkToolButtonObj = object of/" final.nim
sed  -i "s/GtkToolButtonClassObj\*{\.final\.} = object of/GtkToolButtonClassObj = object of/" final.nim
sed  -i "s/GtkPopoverClassObj\*{\.final\.} = object of/GtkPopoverClassObj = object of/" final.nim
sed  -i "s/GtkRangeClassObj\*{\.final\.} = object of/GtkRangeClassObj = object of/" final.nim
sed  -i "s/GtkEntryObj\*{\.final\.} = object of/GtkEntryObj = object of/" final.nim
sed  -i "s/GtkEntryClassObj\*{\.final\.} = object of/GtkEntryClassObj = object of/" final.nim
sed  -i "s/GtkScrollbarClassObj\*{\.final\.} = object of/GtkScrollbarClassObj = object of/" final.nim
sed  -i "s/GtkSeparatorClassObj\*{\.final\.} = object of/GtkSeparatorClassObj = object of/" final.nim
sed  -i "s/GtkActionClassObj\*{\.final\.} = object of/GtkActionClassObj = object of/" final.nim
sed  -i "s/GtkToggleActionObj\*{\.final\.} = object of/GtkToggleActionObj = object of/" final.nim
sed  -i "s/GtkToggleActionClassObj\*{\.final\.} = object of/GtkToggleActionClassObj = object of/" final.nim
sed  -i "s/GtkAccessibleObj\*{\.final\.} = object of/GtkAccessibleObj = object of/" final.nim
sed  -i "s/GtkAccessibleClassObj\*{\.final\.} = object of/GtkAccessibleClassObj = object of/" final.nim
sed  -i "s/GtkWidgetAccessibleObj\*{\.final\.} = object of/GtkWidgetAccessibleObj = object of/" final.nim
sed  -i "s/GtkWidgetAccessibleClassObj\*{\.final\.} = object of/GtkWidgetAccessibleClassObj = object of/" final.nim
sed  -i "s/GtkCellAccessibleObj\*{\.final\.} = object of/GtkCellAccessibleObj = object of/" final.nim
sed  -i "s/GtkCellAccessibleClassObj\*{\.final\.} = object of/GtkCellAccessibleClassObj = object of/" final.nim
sed  -i "s/GtkRendererCellAccessibleObj\*{\.final\.} = object of/GtkRendererCellAccessibleObj = object of/" final.nim
sed  -i "s/GtkRendererCellAccessibleClassObj\*{\.final\.} = object of/GtkRendererCellAccessibleClassObj = object of/" final.nim
sed  -i "s/GtkContainerAccessibleObj\*{\.final\.} = object of/GtkContainerAccessibleObj = object of/" final.nim
sed  -i "s/GtkContainerAccessibleClassObj\*{\.final\.} = object of/GtkContainerAccessibleClassObj = object of/" final.nim
sed  -i "s/GtkMenuItemAccessibleObj\*{\.final\.} = object of/GtkMenuItemAccessibleObj = object of/" final.nim
sed  -i "s/GtkMenuItemAccessibleClassObj\*{\.final\.} = object of/GtkMenuItemAccessibleClassObj = object of/" final.nim
sed  -i "s/GtkCheckMenuItemAccessibleObj\*{\.final\.} = object of/GtkCheckMenuItemAccessibleObj = object of/" final.nim
sed  -i "s/GtkCheckMenuItemAccessibleClassObj\*{\.final\.} = object of/GtkCheckMenuItemAccessibleClassObj = object of/" final.nim
sed  -i "s/GtkButtonAccessibleClassObj\*{\.final\.} = object of/GtkButtonAccessibleClassObj = object of/" final.nim
sed  -i "s/GtkToggleButtonAccessibleObj\*{\.final\.} = object of/GtkToggleButtonAccessibleObj = object of/" final.nim
sed  -i "s/GtkToggleButtonAccessibleClassObj\*{\.final\.} = object of/GtkToggleButtonAccessibleClassObj = object of/" final.nim
sed  -i "s/GtkButtonAccessibleObj\*{\.final\.} = object of/GtkButtonAccessibleObj = object of/" final.nim
sed  -i "s/GtkMenuShellAccessibleObj\*{\.final\.} = object of/GtkMenuShellAccessibleObj = object of/" final.nim
sed  -i "s/GtkMenuShellAccessibleClassObj\*{\.final\.} = object of/GtkMenuShellAccessibleClassObj = object of/" final.nim
sed  -i "s/GtkRangeAccessibleObj\*{\.final\.} = object of/GtkRangeAccessibleObj = object of/" final.nim
sed  -i "s/GtkRangeAccessibleClassObj\*{\.final\.} = object of/GtkRangeAccessibleClassObj = object of/" final.nim
sed  -i "s/GtkEntryAccessibleObj\*{\.final\.} = object of/GtkEntryAccessibleObj = object of/" final.nim
sed  -i "s/GtkEntryAccessibleClassObj\*{\.final\.} = object of/GtkEntryAccessibleClassObj = object of/" final.nim
sed  -i "s/GtkMiscObj\*{\.final\.} = object of/GtkMiscObj = object of/" final.nim
sed  -i "s/GtkNativeDialogClassObj\*{\.final\.} = object of/GtkNativeDialogClassObj = object of/" final.nim

i='GtkWindow* =  ptr GtkWindowObj
  GtkWindowPtr* = ptr GtkWindowObj
  GtkWindowObj* = object
    bin*: GtkBinObj
    priv: ptr GtkWindowPrivateObj
'
j='GtkWindow* =  ptr GtkWindowObj
  GtkWindowPtr* = ptr GtkWindowObj
  GtkWindowObj* = object of GtkBinObj
    priv: ptr GtkWindowPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkDialog* =  ptr GtkDialogObj
  GtkDialogPtr* = ptr GtkDialogObj
  GtkDialogObj* = object
    window*: GtkWindowObj
    priv: ptr GtkDialogPrivateObj
'
j='type
  GtkDialog* =  ptr GtkDialogObj
  GtkDialogPtr* = ptr GtkDialogObj
  GtkDialogObj* = object of GtkWindowObj
    priv: ptr GtkDialogPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  GtkContainerPrivateObj = object

  GtkContainer* =  ptr GtkContainerObj
  GtkContainerPtr* = ptr GtkContainerObj
  GtkContainerObj* = object
    widget*: GtkWidgetObj
    priv: ptr GtkContainerPrivateObj

  GtkBinPrivateObj = object

  GtkBin* =  ptr GtkBinObj
  GtkBinPtr* = ptr GtkBinObj
  GtkBinObj* = object
    container*: GtkContainerObj
    priv: ptr GtkBinPrivateObj
'
j='
  GtkContainerPrivateObj = object

  GtkContainer* =  ptr GtkContainerObj
  GtkContainerPtr* = ptr GtkContainerObj
  GtkContainerObj* = object of GtkWidgetObj
    priv: ptr GtkContainerPrivateObj

  GtkBinPrivateObj = object

  GtkBin* =  ptr GtkBinObj
  GtkBinPtr* = ptr GtkBinObj
  GtkBinObj* = object of GtkContainerObj
    priv: ptr GtkBinPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  GtkMisc* =  ptr GtkMiscObj
  GtkMiscPtr* = ptr GtkMiscObj
  GtkMiscObj* = object
    widget*: GtkWidgetObj
    priv: ptr GtkMiscPrivateObj
'
j='
  GtkMisc* =  ptr GtkMiscObj
  GtkMiscPtr* = ptr GtkMiscObj
  GtkMiscObj* = object of GtkWidgetObj
    priv: ptr GtkMiscPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkCalendar* =  ptr GtkCalendarObj
  GtkCalendarPtr* = ptr GtkCalendarObj
  GtkCalendarObj* = object
    widget*: GtkWidgetObj
    priv: ptr GtkCalendarPrivateObj
'
j='type
  GtkCalendar* =  ptr GtkCalendarObj
  GtkCalendarPtr* = ptr GtkCalendarObj
  GtkCalendarObj*{.final.} = object of GtkWidgetObj
    priv: ptr GtkCalendarPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkDrawingArea* =  ptr GtkDrawingAreaObj
  GtkDrawingAreaPtr* = ptr GtkDrawingAreaObj
  GtkDrawingAreaObj* = object
    widget*: GtkWidgetObj
    dummy*: Gpointer
'
j='  GtkDrawingArea* =  ptr GtkDrawingAreaObj
  GtkDrawingAreaPtr* = ptr GtkDrawingAreaObj
  GtkDrawingAreaObj*{.final.} = object of GtkWidgetObj
    dummy*: Gpointer
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkInvisible* =  ptr GtkInvisibleObj
  GtkInvisiblePtr* = ptr GtkInvisibleObj
  GtkInvisibleObj* = object
    widget*: GtkWidgetObj
    priv: ptr GtkInvisiblePrivateObj
'
j='type
  GtkInvisible* =  ptr GtkInvisibleObj
  GtkInvisiblePtr* = ptr GtkInvisibleObj
  GtkInvisibleObj*{.final.} = object of GtkWidgetObj
    priv: ptr GtkInvisiblePrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  GtkRange* =  ptr GtkRangeObj
  GtkRangePtr* = ptr GtkRangeObj
  GtkRangeObj* = object
    widget*: GtkWidgetObj
    priv: ptr GtkRangePrivateObj
'
j='
  GtkRange* =  ptr GtkRangeObj
  GtkRangePtr* = ptr GtkRangeObj
  GtkRangeObj* = object of GtkWidgetObj
    priv: ptr GtkRangePrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  GtkSeparator* =  ptr GtkSeparatorObj
  GtkSeparatorPtr* = ptr GtkSeparatorObj
  GtkSeparatorObj* = object
    widget*: GtkWidgetObj
    priv: ptr GtkSeparatorPrivateObj
'
j='
  GtkSeparator* =  ptr GtkSeparatorObj
  GtkSeparatorPtr* = ptr GtkSeparatorObj
  GtkSeparatorObj* = object of GtkWidgetObj
    priv: ptr GtkSeparatorPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  GtkButtonBox* =  ptr GtkButtonBoxObj
  GtkButtonBoxPtr* = ptr GtkButtonBoxObj
  GtkButtonBoxObj* = object
    box*: GtkBoxObj
    priv: ptr GtkButtonBoxPrivateObj
'
j='
  GtkButtonBox* =  ptr GtkButtonBoxObj
  GtkButtonBoxPtr* = ptr GtkButtonBoxObj
  GtkButtonBoxObj* = object of GtkBoxObj
    priv: ptr GtkButtonBoxPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkStackSwitcher* =  ptr GtkStackSwitcherObj
  GtkStackSwitcherPtr* = ptr GtkStackSwitcherObj
  GtkStackSwitcherObj* = object
    widget*: GtkBoxObj
'
j='type
  GtkStackSwitcher* =  ptr GtkStackSwitcherObj
  GtkStackSwitcherPtr* = ptr GtkStackSwitcherObj
  GtkStackSwitcherObj*{.final.} = object of GtkBoxObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkStatusbar* =  ptr GtkStatusbarObj
  GtkStatusbarPtr* = ptr GtkStatusbarObj
  GtkStatusbarObj* = object
    parent_widget*: GtkBoxObj
    priv: ptr GtkStatusbarPrivateObj
'
j='type
  GtkStatusbar* =  ptr GtkStatusbarObj
  GtkStatusbarPtr* = ptr GtkStatusbarObj
  GtkStatusbarObj*{.final.} = object of GtkBoxObj
    priv: ptr GtkStatusbarPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkHBox* =  ptr GtkHBoxObj
  GtkHBoxPtr* = ptr GtkHBoxObj
  GtkHBoxObj* = object
    box*: GtkBoxObj
'
j='type
  GtkHBox* =  ptr GtkHBoxObj
  GtkHBoxPtr* = ptr GtkHBoxObj
  GtkHBoxObj*{.final.} = object of GtkBoxObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkVBox* =  ptr GtkVBoxObj
  GtkVBoxPtr* = ptr GtkVBoxObj
  GtkVBoxObj* = object
    box*: GtkBoxObj
'
j='type
  GtkVBox* =  ptr GtkVBoxObj
  GtkVBoxPtr* = ptr GtkVBoxObj
  GtkVBoxObj*{.final.} = object of GtkBoxObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  GtkBox* =  ptr GtkBoxObj
  GtkBoxPtr* = ptr GtkBoxObj
  GtkBoxObj* = object
    container*: GtkContainerObj
    priv: ptr GtkBoxPrivateObj
'
j='
  GtkBox* =  ptr GtkBoxObj
  GtkBoxPtr* = ptr GtkBoxObj
  GtkBoxObj* = object of GtkContainerObj
    priv: ptr GtkBoxPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

sed -i 's/    g_type_name(G_OBJECT_TYPE(obj)))/    gobject.name(G_OBJECT_TYPE(obj)))/' final.nim

i='
    gtkReserved1*: nil
    gtkReserved2*: nil
    gtkReserved3*: nil
    gtkReserved4*: nil
'
j='
    gtkReserved1*: proc () {.cdecl.}
    gtkReserved2*: proc () {.cdecl.}
    gtkReserved3*: proc () {.cdecl.}
    gtkReserved4*: proc () {.cdecl.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%sg" final.nim

i='type
  GtkIMContextSimple* =  ptr GtkIMContextSimpleObj
  GtkIMContextSimplePtr* = ptr GtkIMContextSimpleObj
  GtkIMContextSimpleObj* = object
    object*: GtkIMContextObj
    priv: ptr GtkIMContextSimplePrivateObj
'
j='type
  GtkIMContextSimple* =  ptr GtkIMContextSimpleObj
  GtkIMContextSimplePtr* = ptr GtkIMContextSimpleObj
  GtkIMContextSimpleObj*{.final.} = object of GtkIMContextObj
    priv: ptr GtkIMContextSimplePrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkIMMulticontext* =  ptr GtkIMMulticontextObj
  GtkIMMulticontextPtr* = ptr GtkIMMulticontextObj
  GtkIMMulticontextObj* = object
    object*: GtkIMContextObj
    priv: ptr GtkIMMulticontextPrivateObj
'
j='type
  GtkIMMulticontext* =  ptr GtkIMMulticontextObj
  GtkIMMulticontextPtr* = ptr GtkIMMulticontextObj
  GtkIMMulticontextObj*{.final.} = object of GtkIMContextObj
    priv: ptr GtkIMMulticontextPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkButton* =  ptr GtkButtonObj
  GtkButtonPtr* = ptr GtkButtonObj
  GtkButtonObj* = object
    bin*: GtkBinObj
    priv: ptr GtkButtonPrivateObj
'
j='type
  GtkButton* =  ptr GtkButtonObj
  GtkButtonPtr* = ptr GtkButtonObj
  GtkButtonObj* = object of GtkBinObj
    priv: ptr GtkButtonPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  GtkToggleButton* =  ptr GtkToggleButtonObj
  GtkToggleButtonPtr* = ptr GtkToggleButtonObj
  GtkToggleButtonObj* = object
    button*: GtkButtonObj
    priv: ptr GtkToggleButtonPrivateObj
'
j='
  GtkToggleButton* =  ptr GtkToggleButtonObj
  GtkToggleButtonPtr* = ptr GtkToggleButtonObj
  GtkToggleButtonObj* = object of GtkButtonObj
    priv: ptr GtkToggleButtonPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkColorButton* =  ptr GtkColorButtonObj
  GtkColorButtonPtr* = ptr GtkColorButtonObj
  GtkColorButtonObj* = object
    button*: GtkButtonObj
    priv: ptr GtkColorButtonPrivateObj
'
j='type
  GtkColorButton* =  ptr GtkColorButtonObj
  GtkColorButtonPtr* = ptr GtkColorButtonObj
  GtkColorButtonObj*{.final.} = object of GtkButtonObj
    priv: ptr GtkColorButtonPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  GtkPopoverMenuClass* =  ptr GtkPopoverMenuClassObj
  GtkPopoverMenuClassPtr* = ptr GtkPopoverMenuClassObj
  GtkPopoverMenuClassObj*{.final.} = object of GtkPopoverClassObj
    reserved: array[10, Gpointer]
'
j='
  GtkPopoverMenuClass* =  ptr GtkPopoverMenuClassObj
  GtkPopoverMenuClassPtr* = ptr GtkPopoverMenuClassObj
  GtkPopoverMenuClassObj*{.final.} = object of GtkPopoverClassObj
    reserved00: array[10, Gpointer]
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkRecentFilterFunc* = proc (filter_info: GtkRecentFilterInfo;
                               user_data: Gpointer): Gboolean {.cdecl.}
type
  GtkRecentFilterInfo* =  ptr GtkRecentFilterInfoObj
'
j='type
  GtkRecentFilterFunc* = proc (filter_info: GtkRecentFilterInfo;
                               user_data: Gpointer): Gboolean {.cdecl.}
#type
  GtkRecentFilterInfo* =  ptr GtkRecentFilterInfoObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  GtkMenuShell* =  ptr GtkMenuShellObj
  GtkMenuShellPtr* = ptr GtkMenuShellObj
  GtkMenuShellObj* = object
    container*: GtkContainerObj
    priv: ptr GtkMenuShellPrivateObj
'
j='
  GtkMenuShell* =  ptr GtkMenuShellObj
  GtkMenuShellPtr* = ptr GtkMenuShellObj
  GtkMenuShellObj* = object of GtkContainerObj
    priv: ptr GtkMenuShellPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

sed -i 's/\bGDK_PRIORITY_REDRAW\b/gdk3.PRIORITY_REDRAW/' final.nim

i='
  GtkAction* =  ptr GtkActionObj
  GtkActionPtr* = ptr GtkActionObj
  GtkActionObj* = object
    `object`*: gobject.GObjectObj
    private_data*: ptr GtkActionPrivateObj
'
j='
  GtkAction* =  ptr GtkActionObj
  GtkActionPtr* = ptr GtkActionObj
  GtkActionObj* = object of gobject.GObjectObj
    private_data00*: ptr GtkActionPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

sed -i 's/g_Token_Last/glib.GTokenType.LAST/' final.nim

i='
  GtkToggleAction* =  ptr GtkToggleActionObj
  GtkToggleActionPtr* = ptr GtkToggleActionObj
  GtkToggleActionObj = object of GtkActionObj
    private_data*: ptr GtkToggleActionPrivateObj
'
j='
  GtkToggleAction* =  ptr GtkToggleActionObj
  GtkToggleActionPtr* = ptr GtkToggleActionObj
  GtkToggleActionObj = object of GtkActionObj
    private_data01*: ptr GtkToggleActionPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
type
  GtkPrintJobCompleteFunc* = proc (printJob: GtkPrintJob; userData: Gpointer;
                                error: glib.GError) {.cdecl.}
  GtkPrinter* =  ptr GtkPrinterObj
  GtkPrinterPtr* = ptr GtkPrinterObj
  GtkPrinterObj* = object
'
j='
type
  GtkPrintJobCompleteFunc* = proc (printJob: GtkPrintJob; userData: Gpointer;
                                error: glib.GError) {.cdecl.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  GtkLabel* =  ptr GtkLabelObj
  GtkLabelPtr* = ptr GtkLabelObj
  GtkLabelObj* = object
    misc*: GtkMiscObj
    priv: ptr GtkLabelPrivateObj
'
j='
  GtkLabel* =  ptr GtkLabelObj
  GtkLabelPtr* = ptr GtkLabelObj
  GtkLabelObj* = object of GtkMiscObj
    priv: ptr GtkLabelPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkAccelLabel* =  ptr GtkAccelLabelObj
  GtkAccelLabelPtr* = ptr GtkAccelLabelObj
  GtkAccelLabelObj* = object
    label*: GtkLabelObj
    priv: ptr GtkAccelLabelPrivateObj
'
j='  GtkAccelLabel* =  ptr GtkAccelLabelObj
  GtkAccelLabelPtr* = ptr GtkAccelLabelObj
  GtkAccelLabelObj*{.final.} = object of GtkLabelObj
    priv: ptr GtkAccelLabelPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkActionableInterface* =  ptr GtkActionableInterfaceObj
  GtkActionableInterfacePtr* = ptr GtkActionableInterfaceObj
  GtkActionableInterfaceObj* = object
    gIface*: gobject.GTypeInterfaceObj
'
j='  GtkActionableInterface* =  ptr GtkActionableInterfaceObj
  GtkActionableInterfacePtr* = ptr GtkActionableInterfaceObj
  GtkActionableInterfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkTreeModelIface* =  ptr GtkTreeModelIfaceObj
  GtkTreeModelIfacePtr* = ptr GtkTreeModelIfaceObj
  GtkTreeModelIfaceObj* = object
    gIface*: gobject.GTypeInterfaceObj
'
j='type
  GtkTreeModelIface* =  ptr GtkTreeModelIfaceObj
  GtkTreeModelIfacePtr* = ptr GtkTreeModelIfaceObj
  GtkTreeModelIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkImageMenuItem* =  ptr GtkImageMenuItemObj
  GtkImageMenuItemPtr* = ptr GtkImageMenuItemObj
  GtkImageMenuItemObj* = object
    menuItem*: GtkMenuItemObj
    priv: ptr GtkImageMenuItemPrivateObj
'
j='type
  GtkImageMenuItem* =  ptr GtkImageMenuItemObj
  GtkImageMenuItemPtr* = ptr GtkImageMenuItemObj
  GtkImageMenuItemObj* = object of GtkMenuItemObj
    priv: ptr GtkImageMenuItemPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkActionBar* =  ptr GtkActionBarObj
  GtkActionBarPtr* = ptr GtkActionBarObj
  GtkActionBarObj* = object
    bin*: GtkBinObj
'
j='type
  GtkActionBar* =  ptr GtkActionBarObj
  GtkActionBarPtr* = ptr GtkActionBarObj
  GtkActionBarObj*{.final.} = object of GtkBinObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkCellEditableIface* =  ptr GtkCellEditableIfaceObj
  GtkCellEditableIfacePtr* = ptr GtkCellEditableIfaceObj
  GtkCellEditableIfaceObj* = object
    g_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkCellEditableIface* =  ptr GtkCellEditableIfaceObj
  GtkCellEditableIfacePtr* = ptr GtkCellEditableIfaceObj
  GtkCellEditableIfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkTreeSortableIface* =  ptr GtkTreeSortableIfaceObj
  GtkTreeSortableIfacePtr* = ptr GtkTreeSortableIfaceObj
  GtkTreeSortableIfaceObj* = object
    g_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkTreeSortableIface* =  ptr GtkTreeSortableIfaceObj
  GtkTreeSortableIfacePtr* = ptr GtkTreeSortableIfaceObj
  GtkTreeSortableIfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkEditableInterface* =  ptr GtkEditableInterfaceObj
  GtkEditableInterfacePtr* = ptr GtkEditableInterfaceObj
  GtkEditableInterfaceObj* = object
    base_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkEditableInterface* =  ptr GtkEditableInterfaceObj
  GtkEditableInterfacePtr* = ptr GtkEditableInterfaceObj
  GtkEditableInterfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkImageObj* = object
    misc*: GtkMiscObj
    priv: ptr GtkImagePrivateObj
'
j='  GtkImageObj*{.final.} = object of GtkMiscObj
    priv: ptr GtkImagePrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkFrame* =  ptr GtkFrameObj
  GtkFramePtr* = ptr GtkFrameObj
  GtkFrameObj* = object
    bin*: GtkBinObj
    priv: ptr GtkFramePrivateObj
'
j='type
  GtkFrame* =  ptr GtkFrameObj
  GtkFramePtr* = ptr GtkFrameObj
  GtkFrameObj* = object of GtkBinObj
    priv: ptr GtkFramePrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkAspectFrame* =  ptr GtkAspectFrameObj
  GtkAspectFramePtr* = ptr GtkAspectFrameObj
  GtkAspectFrameObj* = object
    frame*: GtkFrameObj
    priv: ptr GtkAspectFramePrivateObj
'
j='type
  GtkAspectFrame* =  ptr GtkAspectFrameObj
  GtkAspectFramePtr* = ptr GtkAspectFrameObj
  GtkAspectFrameObj*{.final.} = object of GtkFrameObj
    priv: ptr GtkAspectFramePrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkBuildableIface* =  ptr GtkBuildableIfaceObj
  GtkBuildableIfacePtr* = ptr GtkBuildableIfaceObj
  GtkBuildableIfaceObj* = object
    g_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkBuildableIface* =  ptr GtkBuildableIfaceObj
  GtkBuildableIfacePtr* = ptr GtkBuildableIfaceObj
  GtkBuildableIfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkCellLayoutIface* =  ptr GtkCellLayoutIfaceObj
  GtkCellLayoutIfacePtr* = ptr GtkCellLayoutIfaceObj
  GtkCellLayoutIfaceObj* = object
    g_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkCellLayoutIface* =  ptr GtkCellLayoutIfaceObj
  GtkCellLayoutIfacePtr* = ptr GtkCellLayoutIfaceObj
  GtkCellLayoutIfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkCheckButton* =  ptr GtkCheckButtonObj
  GtkCheckButtonPtr* = ptr GtkCheckButtonObj
  GtkCheckButtonObj* = object
    toggle_button*: GtkToggleButtonObj
'
j='type
  GtkCheckButton* =  ptr GtkCheckButtonObj
  GtkCheckButtonPtr* = ptr GtkCheckButtonObj
  GtkCheckButtonObj* = object of GtkToggleButtonObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkMenuItem* =  ptr GtkMenuItemObj
  GtkMenuItemPtr* = ptr GtkMenuItemObj
  GtkMenuItemObj* = object
    bin*: GtkBinObj
    priv: ptr GtkMenuItemPrivateObj
'
j='type
  GtkMenuItem* =  ptr GtkMenuItemObj
  GtkMenuItemPtr* = ptr GtkMenuItemObj
  GtkMenuItemObj* = object of GtkBinObj
    priv: ptr GtkMenuItemPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkCheckMenuItem* =  ptr GtkCheckMenuItemObj
  GtkCheckMenuItemPtr* = ptr GtkCheckMenuItemObj
  GtkCheckMenuItemObj* = object
    menu_item*: GtkMenuItemObj
    priv: ptr GtkCheckMenuItemPrivateObj
'
j='type
  GtkCheckMenuItem* =  ptr GtkCheckMenuItemObj
  GtkCheckMenuItemPtr* = ptr GtkCheckMenuItemObj
  GtkCheckMenuItemObj* = object of GtkMenuItemObj
    priv: ptr GtkCheckMenuItemPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkColorChooserInterface* =  ptr GtkColorChooserInterfaceObj
  GtkColorChooserInterfacePtr* = ptr GtkColorChooserInterfaceObj
  GtkColorChooserInterfaceObj* = object
    base_interface*: gobject.GTypeInterfaceObj
'
j='type
  GtkColorChooserInterface* =  ptr GtkColorChooserInterfaceObj
  GtkColorChooserInterfacePtr* = ptr GtkColorChooserInterfaceObj
  GtkColorChooserInterfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkEventBox* =  ptr GtkEventBoxObj
  GtkEventBoxPtr* = ptr GtkEventBoxObj
  GtkEventBoxObj* = object
    bin*: GtkBinObj
    priv: ptr GtkEventBoxPrivateObj
'
j='type
  GtkEventBox* =  ptr GtkEventBoxObj
  GtkEventBoxPtr* = ptr GtkEventBoxObj
  GtkEventBoxObj*{.final.} = object of GtkBinObj
    priv: ptr GtkEventBoxPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkExpander* =  ptr GtkExpanderObj
  GtkExpanderPtr* = ptr GtkExpanderObj
  GtkExpanderObj* = object
    bin*: GtkBinObj
    priv: ptr GtkExpanderPrivateObj
'
j='type
  GtkExpander* =  ptr GtkExpanderObj
  GtkExpanderPtr* = ptr GtkExpanderObj
  GtkExpanderObj*{.final.} = object of GtkBinObj
    priv: ptr GtkExpanderPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkFixed* =  ptr GtkFixedObj
  GtkFixedPtr* = ptr GtkFixedObj
  GtkFixedObj* = object
    container*: GtkContainerObj
    priv: ptr GtkFixedPrivateObj
'
j='type
  GtkFixed* =  ptr GtkFixedObj
  GtkFixedPtr* = ptr GtkFixedObj
  GtkFixedObj*{.final.} = object of GtkContainerObj
    priv: ptr GtkFixedPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkFlowBox* =  ptr GtkFlowBoxObj
  GtkFlowBoxPtr* = ptr GtkFlowBoxObj
  GtkFlowBoxObj* = object
    container*: GtkContainerObj
'
j='type
  GtkFlowBox* =  ptr GtkFlowBoxObj
  GtkFlowBoxPtr* = ptr GtkFlowBoxObj
  GtkFlowBoxObj*{.final.} = object of GtkContainerObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkFontButton* =  ptr GtkFontButtonObj
  GtkFontButtonPtr* = ptr GtkFontButtonObj
  GtkFontButtonObj* = object
    button*: GtkButtonObj
    priv: ptr GtkFontButtonPrivateObj
'
j='type
  GtkFontButton* =  ptr GtkFontButtonObj
  GtkFontButtonPtr* = ptr GtkFontButtonObj
  GtkFontButtonObj*{.final.} = object of GtkButtonObj
    priv: ptr GtkFontButtonPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkFontChooserIface* =  ptr GtkFontChooserIfaceObj
  GtkFontChooserIfacePtr* = ptr GtkFontChooserIfaceObj
  GtkFontChooserIfaceObj* = object
    base_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkFontChooserIface* =  ptr GtkFontChooserIfaceObj
  GtkFontChooserIfacePtr* = ptr GtkFontChooserIfaceObj
  GtkFontChooserIfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkGrid* =  ptr GtkGridObj
  GtkGridPtr* = ptr GtkGridObj
  GtkGridObj* = object
    container*: GtkContainerObj
    priv: ptr GtkGridPrivateObj
'
j='type
  GtkGrid* =  ptr GtkGridObj
  GtkGridPtr* = ptr GtkGridObj
  GtkGridObj*{.final.} = object of GtkContainerObj
    priv: ptr GtkGridPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkHeaderBar* =  ptr GtkHeaderBarObj
  GtkHeaderBarPtr* = ptr GtkHeaderBarObj
  GtkHeaderBarObj* = object
    container*: GtkContainerObj
'
j='type
  GtkHeaderBar* =  ptr GtkHeaderBarObj
  GtkHeaderBarPtr* = ptr GtkHeaderBarObj
  GtkHeaderBarObj*{.final.} = object of GtkContainerObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkStyleProviderIface* =  ptr GtkStyleProviderIfaceObj
  GtkStyleProviderIfacePtr* = ptr GtkStyleProviderIfaceObj
  GtkStyleProviderIfaceObj* = object
    g_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkStyleProviderIface* =  ptr GtkStyleProviderIfaceObj
  GtkStyleProviderIfacePtr* = ptr GtkStyleProviderIfaceObj
  GtkStyleProviderIfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkLayout* =  ptr GtkLayoutObj
  GtkLayoutPtr* = ptr GtkLayoutObj
  GtkLayoutObj* = object
    container*: GtkContainerObj
    priv: ptr GtkLayoutPrivateObj
'
j='type
  GtkLayout* =  ptr GtkLayoutObj
  GtkLayoutPtr* = ptr GtkLayoutObj
  GtkLayoutObj*{.final.} = object of GtkContainerObj
    priv: ptr GtkLayoutPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkMenuBar* =  ptr GtkMenuBarObj
  GtkMenuBarPtr* = ptr GtkMenuBarObj
  GtkMenuBarObj* = object
    menuShell*: GtkMenuShellObj
    priv: ptr GtkMenuBarPrivateObj
'
j='  GtkMenuBar* =  ptr GtkMenuBarObj
  GtkMenuBarPtr* = ptr GtkMenuBarObj
  GtkMenuBarObj* = object of GtkMenuShellObj
    priv: ptr GtkMenuBarPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkNotebook* =  ptr GtkNotebookObj
  GtkNotebookPtr* = ptr GtkNotebookObj
  GtkNotebookObj* = object
    container*: GtkContainerObj
    priv: ptr GtkNotebookPrivateObj
'
j='  GtkNotebook* =  ptr GtkNotebookObj
  GtkNotebookPtr* = ptr GtkNotebookObj
  GtkNotebookObj*{.final.} = object of GtkContainerObj
    priv: ptr GtkNotebookPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkOrientableIface* =  ptr GtkOrientableIfaceObj
  GtkOrientableIfacePtr* = ptr GtkOrientableIfaceObj
  GtkOrientableIfaceObj* = object
    base_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkOrientableIface* =  ptr GtkOrientableIfaceObj
  GtkOrientableIfacePtr* = ptr GtkOrientableIfaceObj
  GtkOrientableIfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  GtkPaned* =  ptr GtkPanedObj
  GtkPanedPtr* = ptr GtkPanedObj
  GtkPanedObj* = object
    container*: GtkContainerObj
    priv: ptr GtkPanedPrivateObj
'
j='
  GtkPaned* =  ptr GtkPanedObj
  GtkPanedPtr* = ptr GtkPanedObj
  GtkPanedObj* = object of GtkContainerObj
    priv: ptr GtkPanedPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkPrintOperationPreviewIface* =  ptr GtkPrintOperationPreviewIfaceObj
  GtkPrintOperationPreviewIfacePtr* = ptr GtkPrintOperationPreviewIfaceObj
  GtkPrintOperationPreviewIfaceObj* = object
    g_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkPrintOperationPreviewIface* =  ptr GtkPrintOperationPreviewIfaceObj
  GtkPrintOperationPreviewIfacePtr* = ptr GtkPrintOperationPreviewIfaceObj
  GtkPrintOperationPreviewIfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  GtkRadioButton* =  ptr GtkRadioButtonObj
  GtkRadioButtonPtr* = ptr GtkRadioButtonObj
  GtkRadioButtonObj* = object
    check_button*: GtkCheckButtonObj
    priv: ptr GtkRadioButtonPrivateObj
'
j='
  GtkRadioButton* =  ptr GtkRadioButtonObj
  GtkRadioButtonPtr* = ptr GtkRadioButtonObj
  GtkRadioButtonObj*{.final.} = object of GtkCheckButtonObj
    priv: ptr GtkRadioButtonPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkRadioMenuItem* =  ptr GtkRadioMenuItemObj
  GtkRadioMenuItemPtr* = ptr GtkRadioMenuItemObj
  GtkRadioMenuItemObj* = object
    check_menu_item*: GtkCheckMenuItemObj
    priv: ptr GtkRadioMenuItemPrivateObj
'
j='type
  GtkRadioMenuItem* =  ptr GtkRadioMenuItemObj
  GtkRadioMenuItemPtr* = ptr GtkRadioMenuItemObj
  GtkRadioMenuItemObj*{.final.} = object of GtkCheckMenuItemObj
    priv: ptr GtkRadioMenuItemPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkRecentChooserIface* =  ptr GtkRecentChooserIfaceObj
  GtkRecentChooserIfacePtr* = ptr GtkRecentChooserIfaceObj
  GtkRecentChooserIfaceObj* = object
    base_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkRecentChooserIface* =  ptr GtkRecentChooserIfaceObj
  GtkRecentChooserIfacePtr* = ptr GtkRecentChooserIfaceObj
  GtkRecentChooserIfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  GtkScale* =  ptr GtkScaleObj
  GtkScalePtr* = ptr GtkScaleObj
  GtkScaleObj* = object
    range*: GtkRangeObj
    priv: ptr GtkScalePrivateObj
'
j='
  GtkScale* =  ptr GtkScaleObj
  GtkScalePtr* = ptr GtkScaleObj
  GtkScaleObj* = object of GtkRangeObj
    priv: ptr GtkScalePrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkScrollableInterface* =  ptr GtkScrollableInterfaceObj
  GtkScrollableInterfacePtr* = ptr GtkScrollableInterfaceObj
  GtkScrollableInterfaceObj* = object
    base_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkScrollableInterface* =  ptr GtkScrollableInterfaceObj
  GtkScrollableInterfacePtr* = ptr GtkScrollableInterfaceObj
  GtkScrollableInterfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkScrollbar* =  ptr GtkScrollbarObj
  GtkScrollbarPtr* = ptr GtkScrollbarObj
  GtkScrollbarObj* = object
    range*: GtkRangeObj
'
j='  GtkScrollbar* =  ptr GtkScrollbarObj
  GtkScrollbarPtr* = ptr GtkScrollbarObj
  GtkScrollbarObj* = object of GtkRangeObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkScrolledWindow* =  ptr GtkScrolledWindowObj
  GtkScrolledWindowPtr* = ptr GtkScrolledWindowObj
  GtkScrolledWindowObj* = object
    container*: GtkBinObj
    priv: ptr GtkScrolledWindowPrivateObj
'
j='  GtkScrolledWindow* =  ptr GtkScrolledWindowObj
  GtkScrolledWindowPtr* = ptr GtkScrolledWindowObj
  GtkScrolledWindowObj* = object of GtkBinObj
    priv: ptr GtkScrolledWindowPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkSeparatorMenuItem* =  ptr GtkSeparatorMenuItemObj
  GtkSeparatorMenuItemPtr* = ptr GtkSeparatorMenuItemObj
  GtkSeparatorMenuItemObj* = object
    menu_item*: GtkMenuItemObj
'
j='type
  GtkSeparatorMenuItem* =  ptr GtkSeparatorMenuItemObj
  GtkSeparatorMenuItemPtr* = ptr GtkSeparatorMenuItemObj
  GtkSeparatorMenuItemObj*{.final.} = object of GtkMenuItemObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkSpinButton* =  ptr GtkSpinButtonObj
  GtkSpinButtonPtr* = ptr GtkSpinButtonObj
  GtkSpinButtonObj* = object
    entry*: GtkEntryObj
    priv: ptr GtkSpinButtonPrivateObj
'
j='type
  GtkSpinButton* =  ptr GtkSpinButtonObj
  GtkSpinButtonPtr* = ptr GtkSpinButtonObj
  GtkSpinButtonObj*{.final.} = object of GtkEntryObj
    priv: ptr GtkSpinButtonPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkToolbar* =  ptr GtkToolbarObj
  GtkToolbarPtr* = ptr GtkToolbarObj
  GtkToolbarObj* = object
    container*: GtkContainerObj
    priv: ptr GtkToolbarPrivateObj
'
j='type
  GtkToolbar* =  ptr GtkToolbarObj
  GtkToolbarPtr* = ptr GtkToolbarObj
  GtkToolbarObj*{.final.} = object of GtkContainerObj
    priv: ptr GtkToolbarPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkToolShellIface* =  ptr GtkToolShellIfaceObj
  GtkToolShellIfacePtr* = ptr GtkToolShellIfaceObj
  GtkToolShellIfaceObj* = object
    g_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkToolShellIface* =  ptr GtkToolShellIfaceObj
  GtkToolShellIfacePtr* = ptr GtkToolShellIfaceObj
  GtkToolShellIfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkTreeDragSourceIface* =  ptr GtkTreeDragSourceIfaceObj
  GtkTreeDragSourceIfacePtr* = ptr GtkTreeDragSourceIfaceObj
  GtkTreeDragSourceIfaceObj* = object
    g_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkTreeDragSourceIface* =  ptr GtkTreeDragSourceIfaceObj
  GtkTreeDragSourceIfacePtr* = ptr GtkTreeDragSourceIfaceObj
  GtkTreeDragSourceIfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkTreeDragDestIface* =  ptr GtkTreeDragDestIfaceObj
  GtkTreeDragDestIfacePtr* = ptr GtkTreeDragDestIfaceObj
  GtkTreeDragDestIfaceObj* = object
    g_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkTreeDragDestIface* =  ptr GtkTreeDragDestIfaceObj
  GtkTreeDragDestIfacePtr* = ptr GtkTreeDragDestIfaceObj
  GtkTreeDragDestIfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkViewport* =  ptr GtkViewportObj
  GtkViewportPtr* = ptr GtkViewportObj
  GtkViewportObj* = object
    bin*: GtkBinObj
    priv: ptr GtkViewportPrivateObj
'
j='type
  GtkViewport* =  ptr GtkViewportObj
  GtkViewportPtr* = ptr GtkViewportObj
  GtkViewportObj*{.final.} = object of GtkBinObj
    priv: ptr GtkViewportPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkArrow* =  ptr GtkArrowObj
  GtkArrowPtr* = ptr GtkArrowObj
  GtkArrowObj* = object
    misc*: GtkMiscObj
    priv: ptr GtkArrowPrivateObj
'
j='type
  GtkArrow* =  ptr GtkArrowObj
  GtkArrowPtr* = ptr GtkArrowObj
  GtkArrowObj*{.final.} = object of GtkMiscObj
    priv: ptr GtkArrowPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkActivatableIface* =  ptr GtkActivatableIfaceObj
  GtkActivatableIfacePtr* = ptr GtkActivatableIfaceObj
  GtkActivatableIfaceObj* = object
    g_iface*: gobject.GTypeInterfaceObj
'
j='type
  GtkActivatableIface* =  ptr GtkActivatableIfaceObj
  GtkActivatableIfacePtr* = ptr GtkActivatableIfaceObj
  GtkActivatableIfaceObj*{.final.} = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkAlignment* =  ptr GtkAlignmentObj
  GtkAlignmentPtr* = ptr GtkAlignmentObj
  GtkAlignmentObj* = object
    bin*: GtkBinObj
    priv: ptr GtkAlignmentPrivateObj
'
j='type
  GtkAlignment* =  ptr GtkAlignmentObj
  GtkAlignmentPtr* = ptr GtkAlignmentObj
  GtkAlignmentObj*{.final.} = object of GtkBinObj
    priv: ptr GtkAlignmentPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkHandleBox* =  ptr GtkHandleBoxObj
  GtkHandleBoxPtr* = ptr GtkHandleBoxObj
  GtkHandleBoxObj* = object
    bin*: GtkBinObj
    priv: ptr GtkHandleBoxPrivateObj
'
j='type
  GtkHandleBox* =  ptr GtkHandleBoxObj
  GtkHandleBoxPtr* = ptr GtkHandleBoxObj
  GtkHandleBoxObj*{.final.} = object of GtkBinObj
    priv: ptr GtkHandleBoxPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkHButtonBox* =  ptr GtkHButtonBoxObj
  GtkHButtonBoxPtr* = ptr GtkHButtonBoxObj
  GtkHButtonBoxObj* = object
    button_box*: GtkButtonBoxObj
'
j='type
  GtkHButtonBox* =  ptr GtkHButtonBoxObj
  GtkHButtonBoxPtr* = ptr GtkHButtonBoxObj
  GtkHButtonBoxObj*{.final.} = object of GtkButtonBoxObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkHPaned* =  ptr GtkHPanedObj
  GtkHPanedPtr* = ptr GtkHPanedObj
  GtkHPanedObj* = object
    paned*: GtkPanedObj
'
j='  GtkHPaned* =  ptr GtkHPanedObj
  GtkHPanedPtr* = ptr GtkHPanedObj
  GtkHPanedObj*{.final.} = object of GtkPanedObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkHScale* =  ptr GtkHScaleObj
  GtkHScalePtr* = ptr GtkHScaleObj
  GtkHScaleObj* = object
    scale*: GtkScaleObj
'
j='type
  GtkHScale* =  ptr GtkHScaleObj
  GtkHScalePtr* = ptr GtkHScaleObj
  GtkHScaleObj*{.final.} = object of GtkScaleObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  GtkHScrollbar* =  ptr GtkHScrollbarObj
  GtkHScrollbarPtr* = ptr GtkHScrollbarObj
  GtkHScrollbarObj* = object
    scrollbar*: GtkScrollbarObj
'
j='  GtkHScrollbar* =  ptr GtkHScrollbarObj
  GtkHScrollbarPtr* = ptr GtkHScrollbarObj
  GtkHScrollbarObj*{.final.} = object of GtkScrollbarObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkHSeparator* =  ptr GtkHSeparatorObj
  GtkHSeparatorPtr* = ptr GtkHSeparatorObj
  GtkHSeparatorObj* = object
    separator*: GtkSeparatorObj
'
j='type
  GtkHSeparator* =  ptr GtkHSeparatorObj
  GtkHSeparatorPtr* = ptr GtkHSeparatorObj
  GtkHSeparatorObj*{.final.} = object of GtkSeparatorObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkTable* =  ptr GtkTableObj
  GtkTablePtr* = ptr GtkTableObj
  GtkTableObj* = object
    container*: GtkContainerObj
    priv: ptr GtkTablePrivateObj
'
j='type
  GtkTable* =  ptr GtkTableObj
  GtkTablePtr* = ptr GtkTableObj
  GtkTableObj*{.final.} = object of GtkContainerObj
    priv: ptr GtkTablePrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkTearoffMenuItem* =  ptr GtkTearoffMenuItemObj
  GtkTearoffMenuItemPtr* = ptr GtkTearoffMenuItemObj
  GtkTearoffMenuItemObj* = object
    menu_item*: GtkMenuItemObj
    priv: ptr GtkTearoffMenuItemPrivateObj
'
j='type
  GtkTearoffMenuItem* =  ptr GtkTearoffMenuItemObj
  GtkTearoffMenuItemPtr* = ptr GtkTearoffMenuItemObj
  GtkTearoffMenuItemObj*{.final.} = object of GtkMenuItemObj
    priv: ptr GtkTearoffMenuItemPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkVButtonBox* =  ptr GtkVButtonBoxObj
  GtkVButtonBoxPtr* = ptr GtkVButtonBoxObj
  GtkVButtonBoxObj* = object
    button_box*: GtkButtonBoxObj
'
j='type
  GtkVButtonBox* =  ptr GtkVButtonBoxObj
  GtkVButtonBoxPtr* = ptr GtkVButtonBoxObj
  GtkVButtonBoxObj*{.final.} = object of GtkButtonBoxObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkVPaned* =  ptr GtkVPanedObj
  GtkVPanedPtr* = ptr GtkVPanedObj
  GtkVPanedObj* = object
    paned*: GtkPanedObj
'
j='type
  GtkVPaned* =  ptr GtkVPanedObj
  GtkVPanedPtr* = ptr GtkVPanedObj
  GtkVPanedObj*{.final.} = object of GtkPanedObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkVScale* =  ptr GtkVScaleObj
  GtkVScalePtr* = ptr GtkVScaleObj
  GtkVScaleObj* = object
    scale*: GtkScaleObj
'
j='type
  GtkVScale* =  ptr GtkVScaleObj
  GtkVScalePtr* = ptr GtkVScaleObj
  GtkVScaleObj*{.final.} = object of GtkScaleObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkVScrollbar* =  ptr GtkVScrollbarObj
  GtkVScrollbarPtr* = ptr GtkVScrollbarObj
  GtkVScrollbarObj* = object
    scrollbar*: GtkScrollbarObj
'
j='type
  GtkVScrollbar* =  ptr GtkVScrollbarObj
  GtkVScrollbarPtr* = ptr GtkVScrollbarObj
  GtkVScrollbarObj*{.final.} = object of GtkScrollbarObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  GtkVSeparator* =  ptr GtkVSeparatorObj
  GtkVSeparatorPtr* = ptr GtkVSeparatorObj
  GtkVSeparatorObj* = object
    separator*: GtkSeparatorObj
'
j='type
  GtkVSeparator* =  ptr GtkVSeparatorObj
  GtkVSeparatorPtr* = ptr GtkVSeparatorObj
  GtkVSeparatorObj*{.final.} = object of GtkSeparatorObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

perl -p -i -e '$/ = "proc "; s/^\w+\*.*VaList.*}/discard """"$&"""\n/s' final.nim
perl -p -i -e '$/ = "proc "; s/^\w+\*.*_gtk[^}]*}/discard """"$&"""\n/s' final.nim
sed -i 's/^proc discard """/\ndiscard """ proc /g' final.nim

sed -i 's/when not defined(GDK_MULTIHEAD_SAFE):/when not GDK_MULTIHEAD_SAFE:/g'  final.nim
sed -i 's/when defined(G_OS_WIN32):/when defined(windows):/g'  final.nim
sed -i 's/when not defined(GTK_DISABLE_DEPRECATED):/when not GTK_DISABLE_DEPRECATED:/g'  final.nim

i='when defined(ENABLE_NLS):
  template p*(string: untyped): untyped =
    gDgettext(gettext_Package, "-properties", string)

else:
  template p*(string: untyped): untyped =
    (string)


template i*(string: untyped): untyped =
  gInternStaticString(string)
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim

sed -i 's/(cast\[GtkStock\](\(".*"\)))/\1/g'  final.nim

sed -i 's/\(dummy[0-9]\{0,2\}\)\*/\1/g' final.nim
sed -i 's/\(reserved[0-9]\{0,2\}\)\*/\1/g' final.nim

sed -i 's/[(][(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/(\1/g' final.nim
sed -i 's/, [(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/, \1/g' final.nim

sed -i 's/\([,=(<>] \{0,1\}\)[(]\(`\{0,1\}\w\+`\{0,1\}\)[)]/\1\2/g' final.nim
sed -i '/^ \? \?#type $/d' final.nim
sed -i 's/\bgobject\.GObjectObj\b/GObjectObj/g' final.nim
sed -i 's/\bgobject\.GObject\b/GObject/g' final.nim
sed -i 's/\bgobject\.GObjectClassObj\b/GObjectClassObj/g' final.nim

perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( GtkSortType)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( GtkIconSize)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(`?\w+=?`?\*)?([(])([^)]* )(ptr)( GtkTreeViewDropPosition)/\1\2\3\4var\6/sg' final.nim

# the gobject lower case templates
sed -i 's/\bg_Type_Check_Instance_Cast\b/gTypeCheckInstanceCast/g' final.nim
sed -i 's/\bg_Type_Check_Instance_Type\b/gTypeCheckInstanceType/g' final.nim
sed -i 's/\bg_Type_Instance_Get_Interface\b/gTypeInstanceGetInterface/g' final.nim
sed -i 's/\bg_Type_Check_Class_Cast\b/gTypeCheckClassCast/g' final.nim
sed -i 's/\bg_Type_Check_Class_Type\b/gTypeCheckClassType/g' final.nim
sed -i 's/\bg_Type_Instance_Get_Class\b/gTypeInstanceGetClass/g' final.nim
sed -i 's/\bgTypeIsA\b/isA/g' final.nim

perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gu?int\d?\d?)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gdouble)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gdouble)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gfloat)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gfloat)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( cint)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( cint)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( GdkModifierType)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gboolean)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( GdkDragProtocol)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( GdkScrollDirection)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( cstring)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Guchar)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( Gpointer)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( GdkAtom)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( GdkWMDecoration)/\1\2\3\4var\6/sg' final.nim
perl -0777 -p -i -e 's/(proc )(\w+\*)?([(])([^)]* )(ptr)( GdkVisualType)/\1\2\3\4var\6/sg' final.nim

sed -i 's/: ptr var /: var ptr /g' final.nim
sed -i 's/\(0x\)0*\([0123456789ABCDEF]\)/\1\2/g' final.nim

sed -i 's/gdk3\.Window/gdk3Window/g' final.nim
ruby ../mangler.rb final.nim Gtk
sed -i 's/gdk3Window/gdk3.Window/g' final.nim

ruby ../mangler.rb final.nim GTK_

i='  const
    STOCK_DIALOG_AUTHENTICATION* = (
      cast[Stock]("gtk-dialog-authentication"))
'
j='  const STOCK_DIALOG_AUTHENTICATION* = "gtk-dialog-authentication"
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  const
    STOCK_ORIENTATION_LANDSCAPE* = (
      cast[Stock]("gtk-orientation-landscape"))
  const
    STOCK_ORIENTATION_REVERSE_LANDSCAPE* = (
      cast[Stock]("gtk-orientation-reverse-landscape"))
  const
    STOCK_ORIENTATION_REVERSE_PORTRAIT* = (
      cast[Stock]("gtk-orientation-reverse-portrait"))
'
j='
  const
    STOCK_ORIENTATION_LANDSCAPE* = "gtk-orientation-nnlandscape"
  const
    STOCK_ORIENTATION_REVERSE_LANDSCAPE* = "gtk-orientation-reverse-landscape"
  const
    STOCK_ORIENTATION_REVERSE_PORTRAIT* = "gtk-orientation-reverse-portrait"
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='from gdk3 import Window

from glib import Gboolean, Gpointer, GQuark, GDestroyNotify, Gsize, Gssize, Gunichar,
  GTokenType, G_PRIORITY_HIGH_IDLE, G_MAXUSHORT, Time

from gobject import GClosure, GObjectClassObj, GObjectObj, GObject, GType, GConnectFlags, GCallback,
  gTypeCheckInstanceCast, gTypeCheckInstanceType, gTypeInstanceGetInterface, gTypeCheckClassCast, gTypeCheckClassType, gTypeInstanceGetClass, isA

from gdk_pixbuf import GdkPixbuf

from cairo import Pattern, Context, Region

from pango import FontDescription, Layout, AttrList, Context, EllipsizeMode, WrapMode, Direction

from gio import GFile, GMenu, GMenuModel, GActionGroup, GAppInfo, GApplication, GApplicationClass, GMountOperation, GAsyncReadyCallback,
  GMountOperationClass, GEmblemedIcon, GEmblemedIconClass, GIcon, GPermission, GAsyncResult, GCancellable, GApplicationFlags

from atk import Object, ObjectClass, RelationSet, Role, CoordType

'
perl -0777 -p -i -e "s%IMPORTLIST%$i%s" final.nim

# fix a few enums manually
i='type
  DirectionType* {.size: sizeof(cint), pure.} = enum
    DIR_TAB_FORWARD, DIR_TAB_BACKWARD, DIR_UP, DIR_DOWN,
    DIR_LEFT, DIR_RIGHT
'
j='type
  DirectionType* {.size: sizeof(cint), pure.} = enum
    TAB_FORWARD, TAB_BACKWARD, UP, DOWN,
    LEFT, RIGHT
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  TextDirection* {.size: sizeof(cint), pure.} = enum
    DIR_NONE, DIR_LTR, DIR_RTL
'
j='type
  TextDirection* {.size: sizeof(cint), pure.} = enum
    NONE, LTR, RTL
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  Justification* {.size: sizeof(cint), pure.} = enum
    JUSTIFY_LEFT, JUSTIFY_RIGHT, JUSTIFY_CENTER, JUSTIFY_FILL
'
j='type
  Justification* {.size: sizeof(cint), pure.} = enum
    LEFT, RIGHT, CENTER, FILL
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  MenuDirectionType* {.size: sizeof(cint), pure.} = enum
    DIR_PARENT, DIR_CHILD, DIR_NEXT,
    DIR_PREV
'
j='type
  MenuDirectionType* {.size: sizeof(cint), pure.} = enum
    PARENT, CHILD, NEXT,
    PREV
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  PositionType* {.size: sizeof(cint), pure.} = enum
    POS_LEFT, POS_RIGHT, POS_TOP, POS_BOTTOM
'
j='type
  PositionType* {.size: sizeof(cint), pure.} = enum
    LEFT, RIGHT, TOP, BOTTOM
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  TreeViewGridLines* {.size: sizeof(cint), pure.} = enum
    LINES_NONE, LINES_HORIZONTAL,
    LINES_VERTICAL, LINES_BOTH
'
j='type
  TreeViewGridLines* {.size: sizeof(cint), pure.} = enum
    NONE, HORIZONTAL,
    VERTICAL, BOTH
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  StateFlags* {.size: sizeof(cint), pure.} = enum
    FLAG_NORMAL = 0, FLAG_ACTIVE = 1 shl 0,
    FLAG_PRELIGHT = 1 shl 1, FLAG_SELECTED = 1 shl 2,
    FLAG_INSENSITIVE = 1 shl 3,
    FLAG_INCONSISTENT = 1 shl 4, FLAG_FOCUSED = 1 shl 5,
    FLAG_BACKDROP = 1 shl 6, FLAG_DIR_LTR = 1 shl 7,
    FLAG_DIR_RTL = 1 shl 8, FLAG_LINK = 1 shl 9,
    FLAG_VISITED = 1 shl 10, FLAG_CHECKED = 1 shl 11
'
j='type
  StateFlags* {.size: sizeof(cint), pure.} = enum
    NORMAL = 0, ACTIVE = 1 shl 0,
    PRELIGHT = 1 shl 1, SELECTED = 1 shl 2,
    INSENSITIVE = 1 shl 3,
    INCONSISTENT = 1 shl 4, FOCUSED = 1 shl 5,
    BACKDROP = 1 shl 6, DIR_LTR = 1 shl 7,
    DIR_RTL = 1 shl 8, LINK = 1 shl 9,
    VISITED = 1 shl 10, CHECKED = 1 shl 11
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  PropagationPhase* {.size: sizeof(cint), pure.} = enum
    PHASE_NONE, PHASE_CAPTURE, PHASE_BUBBLE, PHASE_TARGET
'
j='type
  PropagationPhase* {.size: sizeof(cint), pure.} = enum
    NONE, CAPTURE, BUBBLE, TARGET
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  WindowPosition* {.size: sizeof(cint), pure.} = enum
    WIN_POS_NONE, WIN_POS_CENTER, WIN_POS_MOUSE,
    WIN_POS_CENTER_ALWAYS, WIN_POS_CENTER_ON_PARENT
'
j='type
  WindowPosition* {.size: sizeof(cint), pure.} = enum
    NONE, CENTER, MOUSE,
    CENTER_ALWAYS, CENTER_ON_PARENT
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  ArrowPlacement* {.size: sizeof(cint), pure.} = enum
    ARROWS_BOTH, ARROWS_START, ARROWS_END
'
j='type
  ArrowPlacement* {.size: sizeof(cint), pure.} = enum
    BOTH, START, END
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  CellRendererState* {.size: sizeof(cint), pure.} = enum
    SELECTED = 1 shl 0, PRELIT = 1 shl
        1, CELL_RENDERER_INSENSITIVE = 1 shl 2,
    CELL_RENDERER_SORTED = 1 shl 3, CELL_RENDERER_FOCUSED = 1 shl 4,
    CELL_RENDERER_EXPANDABLE = 1 shl 5,
    CELL_RENDERER_EXPANDED = 1 shl 6
'
j='type
  CellRendererState* {.size: sizeof(cint), pure.} = enum
    SELECTED = 1 shl 0, PRELIT = 1 shl
        1, INSENSITIVE = 1 shl 2,
    SORTED = 1 shl 3, FOCUSED = 1 shl 4,
    EXPANDABLE = 1 shl 5,
    EXPANDED = 1 shl 6
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  DestDefaults* {.size: sizeof(cint), pure.} = enum
    DEFAULT_MOTION = 1 shl 0, DEFAULT_HIGHLIGHT = 1 shl 1,
    DEFAULT_DROP = 1 shl 2, DEFAULT_ALL = 0x7
'
j='type
  DestDefaults* {.size: sizeof(cint), pure.} = enum
    MOTION = 1 shl 0, HIGHLIGHT = 1 shl 1,
    DROP = 1 shl 2, ALL = 0x7
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  ButtonBoxStyle* {.size: sizeof(cint), pure.} = enum
    BUTTONBOX_SPREAD = 1, BUTTONBOX_EDGE, BUTTONBOX_START,
    BUTTONBOX_END, BUTTONBOX_CENTER, BUTTONBOX_EXPAND
'
j='type
  ButtonBoxStyle* {.size: sizeof(cint), pure.} = enum
    SPREAD = 1, EDGE, START,
    END, CENTER, EXPAND
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='  IconViewDropPosition* {.size: sizeof(cint), pure.} = enum
    NO_DROP, DROP_INTO, DROP_LEFT,
    DROP_RIGHT, DROP_ABOVE,
    DROP_BELOW
'
j='  IconViewDropPosition* {.size: sizeof(cint), pure.} = enum
    NO_DROP, INTO, LEFT,
    RIGHT, ABOVE,
    BELOW
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  SpinButtonUpdatePolicy* {.size: sizeof(cint), pure.} = enum
    UPDATE_ALWAYS, UPDATE_IF_VALID
'
j='type
  SpinButtonUpdatePolicy* {.size: sizeof(cint), pure.} = enum
    ALWAYS, IF_VALID
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  TextBufferTargetInfo* {.size: sizeof(cint), pure.} = enum
    INFO_TEXT = - 3,
    INFO_RICH_TEXT = - 2,
    INFO_BUFFER_CONTENTS = - 1
'
j='type
  TextBufferTargetInfo* {.size: sizeof(cint), pure.} = enum
    TEXT = - 3,
    RICH_TEXT = - 2,
    BUFFER_CONTENTS = - 1
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='type
  Allocation* =  ptr AllocationObj
  AllocationPtr* = ptr AllocationObj
  AllocationObj* = gdk3.RectangleObj
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='  WidgetClassPrivateObj = object
'
perl -0777 -p -i -e "s%\Q$j\E%$j$i%s" final.nim

i='  TreeModelFlags* {.size: sizeof(cint), pure.} = enum
    ITERS_PERSIST = 1 shl 0, LIST_ONLY = 1 shl 1
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='  TreeModelIface* =  ptr TreeModelIfaceObj
  TreeModelIfacePtr* = ptr TreeModelIfaceObj
  TreeModelIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$j\E%$i$j%s" final.nim

i='type
  TreeIterCompareFunc* = proc (model: TreeModel; a: TreeIter;
                               b: TreeIter; userData: Gpointer): Gint {.cdecl.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='type
  TreeSortable* =  ptr TreeSortableObj
  TreeSortablePtr* = ptr TreeSortableObj
  TreeSortableObj* = object
'
perl -0777 -p -i -e "s%\Q$j\E%$j$i%s" final.nim

i='type
  CellCallback* = proc (renderer: CellRenderer; data: Gpointer): Gboolean {.cdecl.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='  CellAreaContextObj*{.final.} = object of GObjectObj
    priv: ptr CellAreaContextPrivateObj
'
perl -0777 -p -i -e "s%\Q$j\E%$j$i%s" final.nim

i='type
  CellAllocCallback* = proc (renderer: CellRenderer;
                             cellArea: gdk3.Rectangle;
                             cellBackground: gdk3.Rectangle; data: Gpointer): Gboolean {.cdecl.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim

perl -0777 -p -i -e "s%\Q$j\E%$j$i%s" final.nim

i='type
  CellLayoutDataFunc* = proc (cellLayout: CellLayout;
                              cell: CellRenderer;
                              treeModel: TreeModel; iter: TreeIter;
                              data: Gpointer) {.cdecl.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='type
  CellLayout* =  ptr CellLayoutObj
  CellLayoutPtr* = ptr CellLayoutObj
  CellLayoutObj* = object
'
perl -0777 -p -i -e "s%\Q$j\E%$j$i%s" final.nim

i='type
  FontFilterFunc* = proc (family: pango.FontFamily; face: pango.FontFace;
                          data: Gpointer): Gboolean {.cdecl.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='  FontChooser* =  ptr FontChooserObj
  FontChooserPtr* = ptr FontChooserObj
  FontChooserObj* = object
'
perl -0777 -p -i -e "s%\Q$j\E%$j$i%s" final.nim

i='type
  NotebookTab* {.size: sizeof(cint), pure.} = enum
    FIRST, LAST
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='type
  NotebookClass* =  ptr NotebookClassObj
  NotebookClassPtr* = ptr NotebookClassObj
  NotebookClassObj*{.final.} = object of ContainerClassObj
'
perl -0777 -p -i -e "s%\Q$j\E%$i$j%s" final.nim

i='type
  PrintOperationResult* {.size: sizeof(cint), pure.} = enum
    ERROR, APPLY,
    CANCEL, IN_PROGRESS
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='type
  PrintOperation* =  ptr PrintOperationObj
  PrintOperationPtr* = ptr PrintOperationObj
  PrintOperationObj*{.final.} = object of GObjectObj
'
perl -0777 -p -i -e "s%\Q$j\E%$i$j%s" final.nim

i='type
  RecentSortType* {.size: sizeof(cint), pure.} = enum
    NONE = 0, MRU, LRU,
    CUSTOM
  RecentSortFunc* = proc (a: RecentInfo; b: RecentInfo;
                          userData: Gpointer): Gint {.cdecl.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='type
  RecentChooserIface* =  ptr RecentChooserIfaceObj
  RecentChooserIfacePtr* = ptr RecentChooserIfaceObj
  RecentChooserIfaceObj* = object
'
perl -0777 -p -i -e "s%\Q$j\E%$i$j%s" final.nim

i='type
  TextViewLayer* {.size: sizeof(cint), pure.} = enum
    BELOW, ABOVE,
    BELOW_TEXT, ABOVE_TEXT
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='type
  TextView* =  ptr TextViewObj
  TextViewPtr* = ptr TextViewObj
  TextViewObj* = object of ContainerObj
'
perl -0777 -p -i -e "s%\Q$j\E%$i$j%s" final.nim

i='type
  TextExtendSelection* {.size: sizeof(cint), pure.} = enum
    WORD, LINE
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='type
  TextView* =  ptr TextViewObj
  TextViewPtr* = ptr TextViewObj
  TextViewObj* = object of ContainerObj
'
perl -0777 -p -i -e "s%\Q$j\E%$i$j%s" final.nim

i='  ExpanderStyle* {.size: sizeof(cint), pure.} = enum
    COLLAPSED, SEMI_COLLAPSED,
    SEMI_EXPANDED, EXPANDED
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
j='type
  StyleClass* =  ptr StyleClassObj
  StyleClassPtr* = ptr StyleClassObj
  StyleClassObj*{.final.} = object of GObjectClassObj
'
perl -0777 -p -i -e "s%\Q$j\E%\ntype\n$i$j%s" final.nim

sed -i '/### "gtk/d' final.nim

sed -i 's/proc true\*/proc gtkTrue*/g' final.nim
sed -i 's/proc false\*/proc gtkFalse*/g' final.nim

i='
const
  PRIORITY_RESIZE* = (g_Priority_High_Idle + 10)
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim

i='
const
  TEXT_VIEW_PRIORITY_VALIDATE* = (gdk_Priority_Redraw + 5)
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim

i='
const
  gtkMajorVersion* = gtkGetMajorVersion()
  gtkMinorVersion* = gtkGetMinorVersion()
  gtkMicroVersion* = gtkGetMicroVersion()
  gtkBinaryAge* = gtkGetBinaryAge()
  gtkInterfaceAge* = gtkGetInterfaceAge()
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim

i='
  ActionBarObj* = object
    bin*: BinObj
'
j='
  ActionBarObj* = object of BinObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  CellEditableIfaceObj* = object
    gIface*: gobject.GTypeInterfaceObj
'
j='
  CellEditableIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  TreeSortableIfaceObj* = object
    gIface*: gobject.GTypeInterfaceObj
'
j='
  TreeSortableIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  EditableInterfaceObj* = object
    baseIface*: gobject.GTypeInterfaceObj
'
j='
  EditableInterfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  SpinButtonObj* = object
    entry*: EntryObj
'
j='
  SpinButtonObj* = object of EntryObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  ShortcutsWindowObj* = object
    window*: WindowObj
'
j='
  ShortcutsWindowObj* = object of WindowObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  FrameObj* = object
    bin*: BinObj
'
j='
  FrameObj* = object of BinObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  AspectFrameObj* = object
    frame*: FrameObj
'
j='
  AspectFrameObj* = object of FrameObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  BuildableIfaceObj* = object
    gIface*: gobject.GTypeInterfaceObj
'
j='
  BuildableIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  ButtonObj* = object
    bin*: BinObj
'
j='
  ButtonObj* = object of BinObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  CellLayoutIfaceObj* = object
    gIface*: gobject.GTypeInterfaceObj
'
j='
  CellLayoutIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  CheckButtonObj* = object
    toggleButton*: ToggleButtonObj
'
j='
  CheckButtonObj* = object of ToggleButtonObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  MenuObj* = object
    menuShell*: MenuShellObj
'
j='
  MenuObj* = object of MenuShellObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  MenuItemObj* = object
    bin*: BinObj
'
j='
  MenuItemObj* = object of BinObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  CheckMenuItemObj* = object
    menuItem*: MenuItemObj
'
j='
  CheckMenuItemObj* = object of MenuItemObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  ColorButtonObj* = object
    button*: ButtonObj
'
j='
  ColorButtonObj* = object of ButtonObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  ColorChooserInterfaceObj* = object
    baseInterface*: gobject.GTypeInterfaceObj
'
j='
  ColorChooserInterfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  EventBoxObj* = object
    bin*: BinObj
'
j='
  EventBoxObj* = object of BinObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  ExpanderObj* = object
    bin*: BinObj
'
j='
  ExpanderObj* = object of BinObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  FixedObj* = object
    container*: ContainerObj
'
j='
  FixedObj* = object of ContainerObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  FontButtonObj* = object
    button*: ButtonObj
'
j='
  FontButtonObj* = object of ButtonObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  FontChooserIfaceObj* = object
    baseIface*: gobject.GTypeInterfaceObj
'
j='
  FontChooserIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  GridObj* = object
    container*: ContainerObj
'
j='
  GridObj* = object of ContainerObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  HeaderBarObj* = object
    container*: ContainerObj
'
j='
  HeaderBarObj* = object of ContainerObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  StyleProviderIfaceObj* = object
    gIface*: gobject.GTypeInterfaceObj
'
j='
  StyleProviderIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  IMContextSimpleObj* = object
    `object`*: IMContextObj
'
j='
  IMContextSimpleObj* = object of IMContextObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  IMMulticontextObj* = object
    `object`*: IMContextObj
'
j='
  IMMulticontextObj* = object of IMContextObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  InvisibleObj* = object
    widget*: WidgetObj
'
j='
  InvisibleObj* = object of WidgetObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  LayoutObj* = object
    container*: ContainerObj
'
j='
  LayoutObj* = object of ContainerObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  OrientableIfaceObj* = object
    baseIface*: gobject.GTypeInterfaceObj
'
j='
  OrientableIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  PrintOperationPreviewIfaceObj* = object
    gIface*: gobject.GTypeInterfaceObj
'
j='
  PrintOperationPreviewIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  RadioButtonObj* = object
    checkButton*: CheckButtonObj
'
j='
  RadioButtonObj* = object of CheckButtonObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  RadioMenuItemObj* = object
    checkMenuItem*: CheckMenuItemObj
'
j='
  RadioMenuItemObj* = object of CheckMenuItemObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  RecentChooserIfaceObj* = object
    baseIface*: gobject.GTypeInterfaceObj
'
j='
  RecentChooserIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  ScrollableInterfaceObj* = object
    baseIface*: gobject.GTypeInterfaceObj
'
j='
  ScrollableInterfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  SeparatorMenuItemObj* = object
    menuItem*: MenuItemObj
'
j='
  SeparatorMenuItemObj* = object of MenuItemObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  StatusbarObj* = object
    parentWidget*: BoxObj
'
j='
  StatusbarObj* = object of BoxObj
'

perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  ToolShellIfaceObj* = object
    gIface*: gobject.GTypeInterfaceObj
'
j='
  ToolShellIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  TreeDragSourceIfaceObj* = object
    gIface*: gobject.GTypeInterfaceObj
'
j='
  TreeDragSourceIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  TreeDragDestIfaceObj* = object
    gIface*: gobject.GTypeInterfaceObj
'
j='
  TreeDragDestIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  ViewportObj* = object
    bin*: BinObj
'
j='
  ViewportObj* = object of BinObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  ArrowObj* = object
    misc*: MiscObj
'
j='
  ArrowObj* = object of MiscObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  ActionObj* = object
    `object`*: GObjectObj
'
j='
  ActionObj* = object of GObjectObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  ActivatableIfaceObj* = object
    gIface*: gobject.GTypeInterfaceObj
'
j='
  ActivatableIfaceObj* = object of gobject.GTypeInterfaceObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  AlignmentObj* = object
    bin*: BinObj
'
j='
  AlignmentObj* = object of BinObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  HandleBoxObj* = object
    bin*: BinObj
'
j='
  HandleBoxObj* = object of BinObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  HButtonBoxObj* = object
    buttonBox*: ButtonBoxObj
'
j='
  HButtonBoxObj* = object of ButtonBoxObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  ImageMenuItemObj* = object
    menuItem*: MenuItemObj
'
j='
  ImageMenuItemObj* = object of MenuItemObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  TableObj* = object
    container*: ContainerObj
'
j='
  TableObj* = object of ContainerObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  TearoffMenuItemObj* = object
    menuItem*: MenuItemObj
'
j='
  TearoffMenuItemObj* = object of MenuItemObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  VButtonBoxObj* = object
    buttonBox*: ButtonBoxObj
'
j='
  VButtonBoxObj* = object of ButtonBoxObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  ActionObj* = object of GObjectObj
    privateData*: ptr ActionPrivateObj
'
j='
  ActionObj* = object of GObjectObj
    privateData2: ptr ActionPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='
  ToggleActionObj = object of ActionObj
    privateData*: ptr ToggleActionPrivateObj
'
j='
  ToggleActionObj = object of ActionObj
    privateData3: ptr ToggleActionPrivateObj
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

ruby ../fix_reserved.rb final.nim

for i in ApplicationObj ApplicationClassObj DialogObj DialogClassObj ApplicationWindowObj ApplicationWindowClassObj ; do
  perl -0777 -p -i -e "s%\Q$i*{.final.} = object of \E%$i* = object of %s" final.nim
  perl -0777 -p -i -e "s%\Q$i{.final.} = object of \E%$i* = object of %s" final.nim
  perl -0777 -p -i -e "s%\Q$i = object of \E%$i* = object of %s" final.nim
done

for i in TextBufferObj TextTagClassObj TextTagObj ; do
  perl -0777 -p -i -e "s%\Q$i*{.final.} = object of \E%$i* = object of %s" final.nim
done

sed -i 's/\(: ptr \)\w\+PrivateObj/: pointer/g' final.nim
sed -i '/  \w\+PrivateObj = object$/d' final.nim

sed -i 's/\s\+$//g' final.nim

perl -0777 -p -i -e "s%\ntype\n{2,}%\ntype\n%sg" final.nim
perl -0777 -p -i -e "s%\n(type\n){2,}%\ntype\n%sg" final.nim
perl -0777 -p -i -e "s%\ntype\ntemplate%\ntemplate%sg" final.nim
perl -0777 -p -i -e "s%\ntype\nproc%\nproc%sg" final.nim
sed -i '/#type$/d' final.nim

for i in uint8 uint16 uint32 uint64 int8 int16 int32 int64 ; do
  sed -i "s/\bG${i}\b/${i}/g" final.nim
done

sed -i "s/ $//g" final.nim
sed -i 's/\* = gtk\([A-Z]\)/* = \L\1/g' final.nim

ruby ../fix_template.rb final.nim gtk

sed -i "s/\bGint\b/cint/g" final.nim
sed -i "s/\bGuint\b/cuint/g" final.nim
sed -i "s/\bGfloat\b/cfloat/g" final.nim
sed -i "s/\bGdouble\b/cdouble/g" final.nim
sed -i "s/\bGshort\b/cshort/g" final.nim
sed -i "s/\bGushort\b/cushort/g" final.nim
sed -i "s/\bGlong\b/clong/g" final.nim
sed -i "s/\bGulong\b/culong/g" final.nim
sed -i "s/\bGuchar\b/cuchar/g" final.nim

sed -i 's/= (1 shl \([0-9]\)),/= 1 shl \1,/g' final.nim
sed -i 's/= (1 shl \([0-9]\))$/= 1 shl \1/g' final.nim

bash ../fix_gtk3_ret_types.sh final.nim

sed -i 's/\(proc \w\+New\)[A-Z]\w\+/\1/g' final.nim
sed -i 's/proc \(\w\+\)New\*/proc new\u\1*/g' final.nim

i='proc newTreePath*(): TreePath {.importc: "gtk_tree_path_new_first",
    libgtk.}
'
j='proc newTreePathFirst*(): TreePath {.importc: "gtk_tree_path_new_first", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newFileChooserButton*(title: cstring; action: FileChooserAction): FileChooserButton {.
    importc: "gtk_file_chooser_button_new", libgtk.}
proc newFileChooserButton*(dialog: Widget): Widget {.
    importc: "gtk_file_chooser_button_new_with_dialog", libgtk.}
'
j='proc newFileChooserButton*(title: cstring; action: FileChooserAction): FileChooserButton {.
    importc: "gtk_file_chooser_button_new", libgtk.}
proc newFileChooserButton*(dialog: Widget): FileChooserButton {.
    importc: "gtk_file_chooser_button_new_with_dialog", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newFileChooserDialog*(title: cstring; parent: Window;
                             action: FileChooserAction;
                             firstButtonText: cstring): Widget {.varargs,
    importc: "gtk_file_chooser_dialog_new", libgtk.}
'
j='proc newFileChooserDialog*(title: cstring; parent: Window;
                             action: FileChooserAction;
                             firstButtonText: cstring): FileChooserDialog {.varargs,
    importc: "gtk_file_chooser_dialog_new", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newFontButton*(): FontButton {.importc: "gtk_font_button_new", libgtk.}
proc newFontButton*(fontname: cstring): Widget {.
    importc: "gtk_font_button_new_with_font", libgtk.}
'
j='proc newFontButton*(): FontButton {.importc: "gtk_font_button_new", libgtk.}
proc newFontButton*(fontname: cstring): FontButton {.
    importc: "gtk_font_button_new_with_font", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newIconView*(): IconView {.importc: "gtk_icon_view_new", libgtk.}
proc newIconView*(area: CellArea): Widget {.
    importc: "gtk_icon_view_new_with_area", libgtk.}
proc newIconView*(model: TreeModel): Widget {.
    importc: "gtk_icon_view_new_with_model", libgtk.}
'
j='proc newIconView*(): IconView {.importc: "gtk_icon_view_new", libgtk.}
proc newIconView*(area: CellArea): IconView {.
    importc: "gtk_icon_view_new_with_area", libgtk.}
proc newIconView*(model: TreeModel): IconView {.
    importc: "gtk_icon_view_new_with_model", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newInfoBar*(): InfoBar {.importc: "gtk_info_bar_new", libgtk.}
proc newInfoBar*(firstButtonText: cstring): Widget {.varargs,
    importc: "gtk_info_bar_new_with_buttons", libgtk.}
'
j='proc newInfoBar*(): InfoBar {.importc: "gtk_info_bar_new", libgtk.}
proc newInfoBar*(firstButtonText: cstring): InfoBar {.varargs,
    importc: "gtk_info_bar_new_with_buttons", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newInvisible*(): Invisible {.importc: "gtk_invisible_new", libgtk.}
proc newInvisible*(screen: gdk3.Screen): Widget {.
    importc: "gtk_invisible_new_for_screen", libgtk.}
'
j='proc newInvisible*(): Invisible {.importc: "gtk_invisible_new", libgtk.}
proc newInvisible*(screen: gdk3.Screen): Invisible {.
    importc: "gtk_invisible_new_for_screen", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newLevelBar*(): LevelBar {.importc: "gtk_level_bar_new", libgtk.}
proc newLevelBar*(minValue: cdouble; maxValue: cdouble): Widget {.
    importc: "gtk_level_bar_new_for_interval", libgtk.}
'
j='proc newLevelBar*(): LevelBar {.importc: "gtk_level_bar_new", libgtk.}
proc newLevelBar*(minValue: cdouble; maxValue: cdouble): LevelBar {.
    importc: "gtk_level_bar_new_for_interval", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newLinkButton*(uri: cstring): LinkButton {.importc: "gtk_link_button_new",
    libgtk.}
proc newLinkButton*(uri: cstring; label: cstring): Widget {.
    importc: "gtk_link_button_new_with_label", libgtk.}
'
j='proc newLinkButton*(uri: cstring): LinkButton {.importc: "gtk_link_button_new",
    libgtk.}
proc newLinkButton*(uri: cstring; label: cstring): LinkButton {.
    importc: "gtk_link_button_new_with_label", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newMenuBar*(): MenuBar {.importc: "gtk_menu_bar_new", libgtk.}
proc newMenuBar*(model: gio.GMenuModel): Widget {.
    importc: "gtk_menu_bar_new_from_model", libgtk.}
'
j='proc newMenuBar*(): MenuBar {.importc: "gtk_menu_bar_new", libgtk.}
proc newMenuBar*(model: gio.GMenuModel): MenuBar {.
    importc: "gtk_menu_bar_new_from_model", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newPopover*(relativeTo: Widget): Popover {.
    importc: "gtk_popover_new", libgtk.}
proc newPopover*(relativeTo: Widget; model: gio.GMenuModel): Widget {.
    importc: "gtk_popover_new_from_model", libgtk.}
'
j='proc newPopover*(relativeTo: Widget): Popover {.
    importc: "gtk_popover_new", libgtk.}
proc newPopover*(relativeTo: Widget; model: gio.GMenuModel): Popover {.
    importc: "gtk_popover_new_from_model", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newRecentChooserDialog*(title: cstring; parent: Window;
                               firstButtonText: cstring): RecentChooserDialog {.varargs,
    importc: "gtk_recent_chooser_dialog_new", libgtk.}
proc newRecentChooserDialog*(title: cstring; parent: Window;
    manager: RecentManager; firstButtonText: cstring): Widget {.varargs,
    importc: "gtk_recent_chooser_dialog_new_for_manager", libgtk.}
'
j='proc newRecentChooserDialog*(title: cstring; parent: Window;
                               firstButtonText: cstring): RecentChooserDialog {.varargs,
    importc: "gtk_recent_chooser_dialog_new", libgtk.}
proc newRecentChooserDialog*(title: cstring; parent: Window;
    manager: RecentManager; firstButtonText: cstring): RecentChooserDialog {.varargs,
    importc: "gtk_recent_chooser_dialog_new_for_manager", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newRecentChooserMenu*(): RecentChooserMenu {.
    importc: "gtk_recent_chooser_menu_new", libgtk.}
proc newRecentChooserMenu*(manager: RecentManager): Widget {.
    importc: "gtk_recent_chooser_menu_new_for_manager", libgtk.}
'
j='proc newRecentChooserMenu*(): RecentChooserMenu {.
    importc: "gtk_recent_chooser_menu_new", libgtk.}
proc newRecentChooserMenu*(manager: RecentManager): RecentChooserMenu {.
    importc: "gtk_recent_chooser_menu_new_for_manager", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newRecentChooserWidget*(): RecentChooserWidget {.
    importc: "gtk_recent_chooser_widget_new", libgtk.}
proc newRecentChooserWidget*(manager: RecentManager): Widget {.
    importc: "gtk_recent_chooser_widget_new_for_manager", libgtk.}
'
j='proc newRecentChooserWidget*(): RecentChooserWidget {.
    importc: "gtk_recent_chooser_widget_new", libgtk.}
proc newRecentChooserWidget*(manager: RecentManager): RecentChooserWidget {.
    importc: "gtk_recent_chooser_widget_new_for_manager", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newScale*(orientation: Orientation; adjustment: Adjustment): Scale {.
    importc: "gtk_scale_new", libgtk.}
proc newScale*(orientation: Orientation; min: cdouble; max: cdouble;
                          step: cdouble): Widget {.
    importc: "gtk_scale_new_with_range", libgtk.}
'
j='proc newScale*(orientation: Orientation; adjustment: Adjustment): Scale {.
    importc: "gtk_scale_new", libgtk.}
proc newScale*(orientation: Orientation; min: cdouble; max: cdouble;
                          step: cdouble): Scale {.
    importc: "gtk_scale_new_with_range", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newSpinButton*(adjustment: Adjustment; climbRate: cdouble;
                      digits: cuint): SpinButton {.
    importc: "gtk_spin_button_new", libgtk.}
proc newSpinButton*(min: cdouble; max: cdouble; step: cdouble): Widget {.
    importc: "gtk_spin_button_new_with_range", libgtk.}
'
j='proc newSpinButton*(adjustment: Adjustment; climbRate: cdouble;
                      digits: cuint): SpinButton {.
    importc: "gtk_spin_button_new", libgtk.}
proc newSpinButton*(min: cdouble; max: cdouble; step: cdouble): SpinButton {.
    importc: "gtk_spin_button_new_with_range", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newTextView*(): TextView {.importc: "gtk_text_view_new", libgtk.}
proc newTextView*(buffer: TextBuffer): Widget {.
    importc: "gtk_text_view_new_with_buffer", libgtk.}
'
j='proc newTextView*(): TextView {.importc: "gtk_text_view_new", libgtk.}
proc newTextView*(buffer: TextBuffer): TextView {.
    importc: "gtk_text_view_new_with_buffer", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newHscale*(adjustment: Adjustment): Hscale {.
    importc: "gtk_hscale_new", libgtk.}
proc newHscale*(min: cdouble; max: cdouble; step: cdouble): Widget {.
    importc: "gtk_hscale_new_with_range", libgtk.}
'
j='proc newHscale*(adjustment: Adjustment): Hscale {.
    importc: "gtk_hscale_new", libgtk.}
proc newHscale*(min: cdouble; max: cdouble; step: cdouble): Hscale {.
    importc: "gtk_hscale_new_with_range", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newStatusIcon*(): StatusIcon {.importc: "gtk_status_icon_new",
    libgtk.}
proc newStatusIcon*(pixbuf: ptr GdkPixbuf): StatusIcon {.
    importc: "gtk_status_icon_new_from_pixbuf", libgtk.}
proc newStatusIcon*(filename: cstring): StatusIcon {.
    importc: "gtk_status_icon_new_from_file", libgtk.}
proc newStatusIcon*(stockId: cstring): StatusIcon {.
    importc: "gtk_status_icon_new_from_stock", libgtk.}
proc newStatusIcon*(iconName: cstring): StatusIcon {.
    importc: "gtk_status_icon_new_from_icon_name", libgtk.}
proc newStatusIcon*(icon: gio.GIcon): StatusIcon {.
    importc: "gtk_status_icon_new_from_gicon", libgtk.}
'
j='proc newStatusIcon*(): StatusIcon {.importc: "gtk_status_icon_new",
    libgtk.}
proc newStatusIcon*(pixbuf: ptr GdkPixbuf): StatusIcon {.
    importc: "gtk_status_icon_new_from_pixbuf", libgtk.}
proc newStatusIcon*(filename: cstring): StatusIcon {.
    importc: "gtk_status_icon_new_from_file", libgtk.}
proc newStatusIconFromStock*(stockId: cstring): StatusIcon {.
    importc: "gtk_status_icon_new_from_stock", libgtk.}
proc newStatusIcon*(iconName: cstring): StatusIcon {.
    importc: "gtk_status_icon_new_from_icon_name", libgtk.}
proc newStatusIcon*(icon: gio.GIcon): StatusIcon {.
    importc: "gtk_status_icon_new_from_gicon", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newVscale*(adjustment: Adjustment): Vscale {.
    importc: "gtk_vscale_new", libgtk.}
proc newVscale*(min: cdouble; max: cdouble; step: cdouble): Widget {.
    importc: "gtk_vscale_new_with_range", libgtk.}
'
j='proc newVscale*(adjustment: Adjustment): Vscale {.
    importc: "gtk_vscale_new", libgtk.}
proc newVscale*(min: cdouble; max: cdouble; step: cdouble): Vscale {.
    importc: "gtk_vscale_new_with_range", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newComboBox*(area: CellArea): ComboBox {.
    importc: "gtk_combo_box_new_with_area", libgtk.}

proc newComboBox*(area: CellArea): ComboBox {.
    importc: "gtk_combo_box_new_with_area_and_entry", libgtk.}

proc newComboBox*(): ComboBox {.
    importc: "gtk_combo_box_new_with_entry", libgtk.}

proc newComboBox*(model: TreeModel): ComboBox {.
    importc: "gtk_combo_box_new_with_model", libgtk.}

proc newComboBox*(model: TreeModel): ComboBox {.
    importc: "gtk_combo_box_new_with_model_and_entry", libgtk.}
'
j='proc newComboBox*(area: CellArea): ComboBox {.
    importc: "gtk_combo_box_new_with_area", libgtk.}

proc newComboBoxWithEntry*(area: CellArea): ComboBox {.
    importc: "gtk_combo_box_new_with_area_and_entry", libgtk.}

proc newComboBoxWithEntry*(): ComboBox {.
    importc: "gtk_combo_box_new_with_entry", libgtk.}

proc newComboBox*(model: TreeModel): ComboBox {.
    importc: "gtk_combo_box_new_with_model", libgtk.}

proc newComboBoxWithEntry*(model: TreeModel): ComboBox {.
    importc: "gtk_combo_box_new_with_model_and_entry", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newButton*(label: cstring): Button {.
    importc: "gtk_button_new_with_label", libgtk.}

proc newButton*(iconName: cstring; size: IconSize): Button {.
    importc: "gtk_button_new_from_icon_name", libgtk.}

proc newButton*(stockId: cstring): Button {.
    importc: "gtk_button_new_from_stock", libgtk.}

proc newButton*(label: cstring): Button {.
    importc: "gtk_button_new_with_mnemonic", libgtk.}
'
j='proc newButtonWithLabel*(label: cstring): Button {.
    importc: "gtk_button_new_with_label", libgtk.}

proc newButton*(iconName: cstring; size: IconSize): Button {.
    importc: "gtk_button_new_from_icon_name", libgtk.}

proc newButtonFromStock*(stockId: cstring): Button {.
    importc: "gtk_button_new_from_stock", libgtk.}

proc newButton*(label: cstring): Button {.
    importc: "gtk_button_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newToggleButton*(label: cstring): ToggleButton {.
    importc: "gtk_toggle_button_new_with_label", libgtk.}

proc newToggleButton*(label: cstring): ToggleButton {.
    importc: "gtk_toggle_button_new_with_mnemonic", libgtk.}
'
j='proc newToggleButtonWithLabel*(label: cstring): ToggleButton {.
    importc: "gtk_toggle_button_new_with_label", libgtk.}

proc newToggleButton*(label: cstring): ToggleButton {.
    importc: "gtk_toggle_button_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newCheckButton*(label: cstring): CheckButton {.
    importc: "gtk_check_button_new_with_label", libgtk.}

proc newCheckButton*(label: cstring): CheckButton {.
    importc: "gtk_check_button_new_with_mnemonic", libgtk.}
'
j='proc newCheckButtonWithLabel*(label: cstring): CheckButton {.
    importc: "gtk_check_button_new_with_label", libgtk.}

proc newCheckButton*(label: cstring): CheckButton {.
    importc: "gtk_check_button_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newMenuItem*(label: cstring): MenuItem {.
    importc: "gtk_menu_item_new_with_label", libgtk.}

proc newMenuItem*(label: cstring): MenuItem {.
    importc: "gtk_menu_item_new_with_mnemonic", libgtk.}
'
j='proc newMenuItemWithLabel*(label: cstring): MenuItem {.
    importc: "gtk_menu_item_new_with_label", libgtk.}

proc newMenuItem*(label: cstring): MenuItem {.
    importc: "gtk_menu_item_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newCheckMenuItem*(label: cstring): CheckMenuItem {.
    importc: "gtk_check_menu_item_new_with_label", libgtk.}

proc newCheckMenuItem*(label: cstring): CheckMenuItem {.
    importc: "gtk_check_menu_item_new_with_mnemonic", libgtk.}
'
j='proc newCheckMenuItemWithLabel*(label: cstring): CheckMenuItem {.
    importc: "gtk_check_menu_item_new_with_label", libgtk.}

proc newCheckMenuItem*(label: cstring): CheckMenuItem {.
    importc: "gtk_check_menu_item_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newComboBoxText*(): ComboBoxText {.
    importc: "gtk_combo_box_text_new_with_entry", libgtk.}
'
j='proc newComboBoxTextWithEntry*(): ComboBoxText {.
    importc: "gtk_combo_box_text_new_with_entry", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newExpander*(label: cstring): Expander {.
    importc: "gtk_expander_new_with_mnemonic", libgtk.}
'
j='proc newExpanderWithMnemonic*(label: cstring): Expander {.
    importc: "gtk_expander_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newMessageDialog*(parent: Window; flags: DialogFlags;
                         `type`: MessageType; buttons: ButtonsType;
                         messageFormat: cstring): MessageDialog {.varargs,
    importc: "gtk_message_dialog_new", libgtk.}

proc newMessageDialog*(parent: Window; flags: DialogFlags;
                                   `type`: MessageType;
                                   buttons: ButtonsType; messageFormat: cstring): MessageDialog {.
    varargs, importc: "gtk_message_dialog_new_with_markup", libgtk.}
'
j='proc newMessageDialog*(parent: Window; flags: DialogFlags;
                         `type`: MessageType; buttons: ButtonsType;
                         messageFormat: cstring): MessageDialog {.varargs,
    importc: "gtk_message_dialog_new", libgtk.}

proc newMessageDialogWithMarkup*(parent: Window; flags: DialogFlags;
                                   `type`: MessageType;
                                   buttons: ButtonsType; messageFormat: cstring): MessageDialog {.
    varargs, importc: "gtk_message_dialog_new_with_markup", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newRadioButton*(group: glib.GSList; label: cstring): RadioButton {.
    importc: "gtk_radio_button_new_with_label", libgtk.}
'
j='proc newRadioButtonWithLabel*(group: glib.GSList; label: cstring): RadioButton {.
    importc: "gtk_radio_button_new_with_label", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newRadioMenuItem*(group: glib.GSList; label: cstring): RadioMenuItem {.
    importc: "gtk_radio_menu_item_new_with_label", libgtk.}
'
j='proc newRadioMenuItemWithLabel*(group: glib.GSList; label: cstring): RadioMenuItem {.
    importc: "gtk_radio_menu_item_new_with_label", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newImageMenuItem*(label: cstring): ImageMenuItem {.
    importc: "gtk_image_menu_item_new_with_label", libgtk.}
'
j='proc newImageMenuItemWithLabel*(label: cstring): ImageMenuItem {.
    importc: "gtk_image_menu_item_new_with_label", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newDialog*(title: cstring; parent: Window;
                             flags: DialogFlags; firstButtonText: cstring): Widget {.
    varargs, importc: "gtk_dialog_new_with_buttons", libgtk.}
'
j='proc newDialog*(title: cstring; parent: Window;
                             flags: DialogFlags; firstButtonText: cstring): Dialog {.
    varargs, importc: "gtk_dialog_new_with_buttons", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

# some procs with get prefix do not return something but need var objects instead of pointers:
# vim search term for candidates:
# proc get[^)]*)[^:}]*{
i='proc getAllocation*(widget: Widget; allocation: Allocation) {.
    importc: "gtk_widget_get_allocation", libgtk.}
'
j='proc getAllocation*(widget: Widget; allocation: var AllocationObj) {.
    importc: "gtk_widget_get_allocation", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc getClip*(widget: Widget; clip: Allocation) {.
    importc: "gtk_widget_get_clip", libgtk.}
'
j='proc getClip*(widget: Widget; clip: var AllocationObj) {.
    importc: "gtk_widget_get_clip", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc getRequisition*(widget: Widget; requisition: Requisition) {.
    importc: "gtk_widget_get_requisition", libgtk.}
'
j='proc getRequisition*(widget: Widget; requisition: var RequisitionObj) {.
    importc: "gtk_widget_get_requisition", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc get*(treeModel: TreeModel; iter: TreeIter) {.varargs,
    importc: "gtk_tree_model_get", libgtk.}
'
j='proc get*(treeModel: TreeModel; iter: var TreeIterObj) {.varargs,
    importc: "gtk_tree_model_get", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc getTextArea*(entry: Entry; textArea: gdk3.Rectangle) {.
    importc: "gtk_entry_get_text_area", libgtk.}
'
j='proc getTextArea*(entry: Entry; textArea: var gdk3.RectangleObj) {.
    importc: "gtk_entry_get_text_area", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc getColor*(button: ColorButton; color: gdk3.Color) {.
    importc: "gtk_color_button_get_color", libgtk.}
'
j='proc getColor*(button: ColorButton; color: var gdk3.ColorObj) {.
    importc: "gtk_color_button_get_color", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc getRgba*(button: ColorButton; rgba: gdk3.RGBA) {.
    importc: "gtk_color_button_get_rgba", libgtk.}
'
j='proc getRgba*(button: ColorButton; rgba: var gdk3.RGBAObj) {.
    importc: "gtk_color_button_get_rgba", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc getRgba*(chooser: ColorChooser; color: gdk3.RGBA) {.
    importc: "gtk_color_chooser_get_rgba", libgtk.}
'
j='proc getRgba*(chooser: ColorChooser; color: var gdk3.RGBAObj) {.
    importc: "gtk_color_chooser_get_rgba", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc getRangeRect*(range: Range; rangeRect: gdk3.Rectangle) {.
    importc: "gtk_range_get_range_rect", libgtk.}
'
j='proc getRangeRect*(range: Range; rangeRect: var gdk3.RectangleObj) {.
    importc: "gtk_range_get_range_rect", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc getStartIter*(buffer: TextBuffer; iter: TextIter) {.
    importc: "gtk_text_buffer_get_start_iter", libgtk.}
'
j='proc getStartIter*(buffer: TextBuffer; iter: var TextIterObj) {.
    importc: "gtk_text_buffer_get_start_iter", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc getEndIter*(buffer: TextBuffer; iter: TextIter) {.
    importc: "gtk_text_buffer_get_end_iter", libgtk.}
'
j='proc getEndIter*(buffer: TextBuffer; iter: var TextIterObj) {.
    importc: "gtk_text_buffer_get_end_iter", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc getWindow*(widget: Widget): gdk3.Window {.
    importc: "gtk_widget_get_window", libgtk.}
'
j='proc getGdkWindow*(widget: Widget): gdk3.Window {.
    importc: "gtk_widget_get_window", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='proc newLabel*(str: cstring): Widget {.
    importc: "gtk_label_new_with_mnemonic", libgtk.}
'
j='proc newLabelWithMnemonic*(str: cstring): Label {.
    importc: "gtk_label_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='template typeWindow*(): untyped =
  (windowGetType())
'
j='template typeWindow*(): untyped =
  gtk3.windowGetType()
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

i='template typeApplication*(): untyped =
  (applicationGetType())
'
j='template typeApplication*(): untyped =
  gtk3.applicationGetType()
'
perl -0777 -p -i -e "s%\Q$i\E%$j%s" final.nim

# generate procs without get_ and set_ prefix
perl -0777 -p -i -e "s/(\n\s*)(proc set)([A-Z]\w+)(\*\([^}]*\) \{[^}]*})/\$&\1proc \`\l\3=\`\4/sg" final.nim
perl -0777 -p -i -e "s/(\n\s*)(proc get)([A-Z]\w+)(\*\([^}]*\): \w[^}]*})/\$&\1proc \l\3\4/sg" final.nim
sed -i 's/^proc object\*(/proc `object`\*(/g' final.nim

sed -i 's/gdk_pixbuf\.GdkPixbuf/GdkPixbuf/g' final.nim

# these proc names generate trouble
for i in bool int uint string enum boolean double flags integer int64 uint64 ; do
  perl -0777 -p -i -e "s/(\n\s*)(proc ${i})(\*\([^}]*\): \w[^}]*})//sg" final.nim
  perl -0777 -p -i -e "s/(\n\s*)(proc \`?${i}=?\`?)(\*\([^}]*\): \w[^}]*})//sg" final.nim
  perl -0777 -p -i -e "s/(\n\s*)(proc \`?${i}=?\`?)(\*\([^}]*\) \{[^}]*})//sg" final.nim
done

#bash ../nim_gtk3_tuning.sh

cat ../gtk3_extensions.nim >> final.nim

cat -s final.nim > gtk3.nim

#cleanup
#rm final.h final.nim proc_dep_list dep.txt dep1.txt list.txt
#rm -r gtk

exit

