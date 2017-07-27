
i='proc addButton*(dialog: Dialog; buttonText: cstring; responseId: cint): Widget {.
    importc: "gtk_dialog_add_button", libgtk.}
'
j='proc addButton*(dialog: Dialog; buttonText: cstring; responseId: cint): Button {.
    importc: "gtk_dialog_add_button", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getHeaderBar*(dialog: Dialog): Widget {.
    importc: "gtk_dialog_get_header_bar", libgtk.}
'
j='proc getHeaderBar*(dialog: Dialog): HeaderBar {.
    importc: "gtk_dialog_get_header_bar", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getSelectedItem*(menuShell: MenuShell): Widget {.
    importc: "gtk_menu_shell_get_selected_item", libgtk.}
'
j='proc getSelectedItem*(menuShell: MenuShell): MenuItem {.
    importc: "gtk_menu_shell_get_selected_item", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getParentShell*(menuShell: MenuShell): Widget {.
    importc: "gtk_menu_shell_get_parent_shell", libgtk.}
'
j='proc getParentShell*(menuShell: MenuShell): MenuShell {.
    importc: "gtk_menu_shell_get_parent_shell", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc menuNewFromModel*(model: gio.GMenuModel): Widget {.
    importc: "gtk_menu_new_from_model", libgtk.}
'
j='proc menuNewFromModel*(model: gio.GMenuModel): Menu {.
    importc: "gtk_menu_new_from_model", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc appChooserDialogNewForContentType*(parent: Window;
    flags: DialogFlags; contentType: cstring): Widget {.
    importc: "gtk_app_chooser_dialog_new_for_content_type", libgtk.}
'
j='proc appChooserDialogNewForContentType*(parent: Window;
    flags: DialogFlags; contentType: cstring): Dialog {.
    importc: "gtk_app_chooser_dialog_new_for_content_type", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getTreeView*(treeColumn: TreeViewColumn): Widget {.
    importc: "gtk_tree_view_column_get_tree_view", libgtk.}
'
j='proc getTreeView*(treeColumn: TreeViewColumn): TreeView {.
    importc: "gtk_tree_view_column_get_tree_view", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getButton*(treeColumn: TreeViewColumn): Widget {.
    importc: "gtk_tree_view_column_get_button", libgtk.}
'
j='proc getButton*(treeColumn: TreeViewColumn): Button {.
    importc: "gtk_tree_view_column_get_button", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getEntry*(completion: EntryCompletion): Widget {.
    importc: "gtk_entry_completion_get_entry", libgtk.}
'
j='proc getEntry*(completion: EntryCompletion): Entry {.
    importc: "gtk_entry_completion_get_entry", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc imageNewFromFile*(filename: cstring): Widget {.
    importc: "gtk_image_new_from_file", libgtk.}
'
j='proc imageNewFromFile*(filename: cstring): Image {.
    importc: "gtk_image_new_from_file", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc imageNewFromResource*(resourcePath: cstring): Widget {.
    importc: "gtk_image_new_from_resource", libgtk.}
'
j='proc imageNewFromResource*(resourcePath: cstring): Image {.
    importc: "gtk_image_new_from_resource", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc imageNewFromPixbuf*(pixbuf: ptr GdkPixbuf): Widget {.
    importc: "gtk_image_new_from_pixbuf", libgtk.}
'
j='proc imageNewFromPixbuf*(pixbuf: ptr GdkPixbuf): Image {.
    importc: "gtk_image_new_from_pixbuf", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc imageNewFromStock*(stockId: cstring; size: IconSize): Widget {.
    importc: "gtk_image_new_from_stock", libgtk.}
'
j='proc imageNewFromStock*(stockId: cstring; size: IconSize): Image {.
    importc: "gtk_image_new_from_stock", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc imageNewFromIconSet*(iconSet: IconSet; size: IconSize): Widget {.
    importc: "gtk_image_new_from_icon_set", libgtk.}
'
j='proc imageNewFromIconSet*(iconSet: IconSet; size: IconSize): Image {.
    importc: "gtk_image_new_from_icon_set", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc imageNewFromAnimation*(animation: gdk_pixbuf.Animation): Widget {.
    importc: "gtk_image_new_from_animation", libgtk.}
'
j='proc imageNewFromAnimation*(animation: gdk_pixbuf.Animation): Image {.
    importc: "gtk_image_new_from_animation", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc imageNewFromIconName*(iconName: cstring; size: IconSize): Widget {.
    importc: "gtk_image_new_from_icon_name", libgtk.}
'
j='proc imageNewFromIconName*(iconName: cstring; size: IconSize): Image {.
    importc: "gtk_image_new_from_icon_name", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc imageNewFromGicon*(icon: gio.GIcon; size: IconSize): Widget {.
    importc: "gtk_image_new_from_gicon", libgtk.}
'
j='proc imageNewFromGicon*(icon: gio.GIcon; size: IconSize): Image {.
    importc: "gtk_image_new_from_gicon", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc imageNewFromSurface*(surface: cairo.Surface): Widget {.
    importc: "gtk_image_new_from_surface", libgtk.}
'
j='proc imageNewFromSurface*(surface: cairo.Surface): Image {.
    importc: "gtk_image_new_from_surface", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc entryNewWithBuffer*(buffer: EntryBuffer): Widget {.
    importc: "gtk_entry_new_with_buffer", libgtk.}
'
j='proc entryNewWithBuffer*(buffer: EntryBuffer): Entry {.
    importc: "gtk_entry_new_with_buffer", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc treeViewNewWithModel*(model: TreeModel): Widget {.
    importc: "gtk_tree_view_new_with_model", libgtk.}
'
j='proc treeViewNewWithModel*(model: TreeModel): TreeView {.
    importc: "gtk_tree_view_new_with_model", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc comboBoxNewWithArea*(area: CellArea): Widget {.
    importc: "gtk_combo_box_new_with_area", libgtk.}
'
j='proc comboBoxNewWithArea*(area: CellArea): ComboBox {.
    importc: "gtk_combo_box_new_with_area", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc comboBoxNewWithAreaAndEntry*(area: CellArea): Widget {.
    importc: "gtk_combo_box_new_with_area_and_entry", libgtk.}
'
j='proc comboBoxNewWithAreaAndEntry*(area: CellArea): ComboBox {.
    importc: "gtk_combo_box_new_with_area_and_entry", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc comboBoxNewWithEntry*(): Widget {.
    importc: "gtk_combo_box_new_with_entry", libgtk.}
'
j='proc comboBoxNewWithEntry*(): ComboBox {.
    importc: "gtk_combo_box_new_with_entry", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc comboBoxNewWithModel*(model: TreeModel): Widget {.
    importc: "gtk_combo_box_new_with_model", libgtk.}
'
j='proc comboBoxNewWithModel*(model: TreeModel): ComboBox {.
    importc: "gtk_combo_box_new_with_model", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc comboBoxNewWithModelAndEntry*(model: TreeModel): Widget {.
    importc: "gtk_combo_box_new_with_model_and_entry", libgtk.}
'
j='proc comboBoxNewWithModelAndEntry*(model: TreeModel): ComboBox {.
    importc: "gtk_combo_box_new_with_model_and_entry", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc buttonNewWithLabel*(label: cstring): Widget {.
    importc: "gtk_button_new_with_label", libgtk.}
'
j='proc buttonNewWithLabel*(label: cstring): Button {.
    importc: "gtk_button_new_with_label", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc buttonNewFromIconName*(iconName: cstring; size: IconSize): Widget {.
    importc: "gtk_button_new_from_icon_name", libgtk.}
'
j='proc buttonNewFromIconName*(iconName: cstring; size: IconSize): Button {.
    importc: "gtk_button_new_from_icon_name", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc buttonNewFromStock*(stockId: cstring): Widget {.
    importc: "gtk_button_new_from_stock", libgtk.}
'
j='proc buttonNewFromStock*(stockId: cstring): Button {.
    importc: "gtk_button_new_from_stock", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc buttonNewWithMnemonic*(label: cstring): Widget {.
    importc: "gtk_button_new_with_mnemonic", libgtk.}
'
j='proc buttonNewWithMnemonic*(label: cstring): Button {.
    importc: "gtk_button_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getImage*(button: Button): Widget {.
    importc: "gtk_button_get_image", libgtk.}
'
j='proc getImage*(button: Button): Image {.
    importc: "gtk_button_get_image", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc cellViewNewWithContext*(area: CellArea;
                               context: CellAreaContext): Widget {.
    importc: "gtk_cell_view_new_with_context", libgtk.}
'
j='proc cellViewNewWithContext*(area: CellArea;
                               context: CellAreaContext): CellView {.
    importc: "gtk_cell_view_new_with_context", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc cellViewNewWithText*(text: cstring): Widget {.
    importc: "gtk_cell_view_new_with_text", libgtk.}
'
j='proc cellViewNewWithText*(text: cstring): CellView {.
    importc: "gtk_cell_view_new_with_text", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc cellViewNewWithMarkup*(markup: cstring): Widget {.
    importc: "gtk_cell_view_new_with_markup", libgtk.}
'
j='proc cellViewNewWithMarkup*(markup: cstring): CellView {.
    importc: "gtk_cell_view_new_with_markup", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc cellViewNewWithPixbuf*(pixbuf: ptr GdkPixbuf): Widget {.
    importc: "gtk_cell_view_new_with_pixbuf", libgtk.}
'
j='proc cellViewNewWithPixbuf*(pixbuf: ptr GdkPixbuf): CellView {.
    importc: "gtk_cell_view_new_with_pixbuf", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc toggleButtonNewWithLabel*(label: cstring): Widget {.
    importc: "gtk_toggle_button_new_with_label", libgtk.}
'
j='proc toggleButtonNewWithLabel*(label: cstring): ToggleButton {.
    importc: "gtk_toggle_button_new_with_label", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc toggleButtonNewWithMnemonic*(label: cstring): Widget {.
    importc: "gtk_toggle_button_new_with_mnemonic", libgtk.}
'
j='proc toggleButtonNewWithMnemonic*(label: cstring): ToggleButton {.
    importc: "gtk_toggle_button_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc checkButtonNewWithLabel*(label: cstring): Widget {.
    importc: "gtk_check_button_new_with_label", libgtk.}
'
j='proc checkButtonNewWithLabel*(label: cstring): CheckButton {.
    importc: "gtk_check_button_new_with_label", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc checkButtonNewWithMnemonic*(label: cstring): Widget {.
    importc: "gtk_check_button_new_with_mnemonic", libgtk.}
'
j='proc checkButtonNewWithMnemonic*(label: cstring): CheckButton {.
    importc: "gtk_check_button_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc menuItemNewWithLabel*(label: cstring): Widget {.
    importc: "gtk_menu_item_new_with_label", libgtk.}
'
j='proc menuItemNewWithLabel*(label: cstring): MenuItem {.
    importc: "gtk_menu_item_new_with_label", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc menuItemNewWithMnemonic*(label: cstring): Widget {.
    importc: "gtk_menu_item_new_with_mnemonic", libgtk.}
'
j='proc menuItemNewWithMnemonic*(label: cstring): MenuItem {.
    importc: "gtk_menu_item_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc checkMenuItemNewWithLabel*(label: cstring): Widget {.
    importc: "gtk_check_menu_item_new_with_label", libgtk.}
'
j='proc checkMenuItemNewWithLabel*(label: cstring): CheckMenuItem {.
    importc: "gtk_check_menu_item_new_with_label", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc checkMenuItemNewWithMnemonic*(label: cstring): Widget {.
    importc: "gtk_check_menu_item_new_with_mnemonic", libgtk.}
'
j='proc checkMenuItemNewWithMnemonic*(label: cstring): CheckMenuItem {.
    importc: "gtk_check_menu_item_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc colorButtonNewWithRgba*(rgba: gdk3.RGBA): Widget {.
    importc: "gtk_color_button_new_with_rgba", libgtk.}
'
j='proc colorButtonNewWithRgba*(rgba: gdk3.RGBA): ColorButton {.
    importc: "gtk_color_button_new_with_rgba", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc colorButtonNewWithColor*(color: gdk3.Color): Widget {.
    importc: "gtk_color_button_new_with_color", libgtk.}
'
j='proc colorButtonNewWithColor*(color: gdk3.Color): ColorButton {.
    importc: "gtk_color_button_new_with_color", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc comboBoxTextNewWithEntry*(): Widget {.
    importc: "gtk_combo_box_text_new_with_entry", libgtk.}
'
j='proc comboBoxTextNewWithEntry*(): ComboBoxText {.
    importc: "gtk_combo_box_text_new_with_entry", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc expanderNewWithMnemonic*(label: cstring): Widget {.
    importc: "gtk_expander_new_with_mnemonic", libgtk.}
'
j='proc expanderNewWithMnemonic*(label: cstring): Expander {.
    importc: "gtk_expander_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc fileChooserButtonNewWithDialog*(dialog: Widget): Widget {.
    importc: "gtk_file_chooser_button_new_with_dialog", libgtk.}
'
j='proc fileChooserButtonNewWithDialog*(dialog: Widget): FileChooserButton {.
    importc: "gtk_file_chooser_button_new_with_dialog", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc fileChooserDialogNew*(title: cstring; parent: Window;
                             action: FileChooserAction;
                             firstButtonText: cstring): Widget {.varargs,
    importc: "gtk_file_chooser_dialog_new", libgtk.}
'
j='proc fileChooserDialogNew*(title: cstring; parent: Window;
                             action: FileChooserAction;
                             firstButtonText: cstring): FileChooserDialog {.varargs,
    importc: "gtk_file_chooser_dialog_new", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc fontButtonNewWithFont*(fontname: cstring): Widget {.
    importc: "gtk_font_button_new_with_font", libgtk.}
'
j='proc fontButtonNewWithFont*(fontname: cstring): FontButton {.
    importc: "gtk_font_button_new_with_font", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc iconViewNewWithArea*(area: CellArea): Widget {.
    importc: "gtk_icon_view_new_with_area", libgtk.}
'
j='proc iconViewNewWithArea*(area: CellArea): IconView {.
    importc: "gtk_icon_view_new_with_area", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc iconViewNewWithModel*(model: TreeModel): Widget {.
    importc: "gtk_icon_view_new_with_model", libgtk.}
'
j='proc iconViewNewWithModel*(model: TreeModel): IconView {.
    importc: "gtk_icon_view_new_with_model", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc infoBarNewWithButtons*(firstButtonText: cstring): Widget {.varargs,
    importc: "gtk_info_bar_new_with_buttons", libgtk.}
'
j='proc infoBarNewWithButtons*(firstButtonText: cstring): InfoBar {.varargs,
    importc: "gtk_info_bar_new_with_buttons", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc addButton*(infoBar: InfoBar; buttonText: cstring;
                         responseId: cint): Widget {.
    importc: "gtk_info_bar_add_button", libgtk.}
'
j='proc addButton*(infoBar: InfoBar; buttonText: cstring;
                         responseId: cint): Button {.
    importc: "gtk_info_bar_add_button", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc levelBarNewForInterval*(minValue: cdouble; maxValue: cdouble): Widget {.
    importc: "gtk_level_bar_new_for_interval", libgtk.}
'
j='proc levelBarNewForInterval*(minValue: cdouble; maxValue: cdouble): LevelBar {.
    importc: "gtk_level_bar_new_for_interval", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc linkButtonNewWithLabel*(uri: cstring; label: cstring): Widget {.
    importc: "gtk_link_button_new_with_label", libgtk.}
'
j='proc linkButtonNewWithLabel*(uri: cstring; label: cstring): LinkButton {.
    importc: "gtk_link_button_new_with_label", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc menuBarNewFromModel*(model: gio.GMenuModel): Widget {.
    importc: "gtk_menu_bar_new_from_model", libgtk.}
'
j='proc menuBarNewFromModel*(model: gio.GMenuModel): MenuBar {.
    importc: "gtk_menu_bar_new_from_model", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc popoverNewFromModel*(relativeTo: Widget; model: gio.GMenuModel): Widget {.
    importc: "gtk_popover_new_from_model", libgtk.}
'
j='proc popoverNewFromModel*(relativeTo: Widget; model: gio.GMenuModel): Popover {.
    importc: "gtk_popover_new_from_model", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc retrieveProxyMenuItem*(toolItem: ToolItem): Widget {.
    importc: "gtk_tool_item_retrieve_proxy_menu_item", libgtk.}
'
j='proc retrieveProxyMenuItem*(toolItem: ToolItem): MenuItem {.
    importc: "gtk_tool_item_retrieve_proxy_menu_item", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getProxyMenuItem*(toolItem: ToolItem; menuItemId: cstring): Widget {.
    importc: "gtk_tool_item_get_proxy_menu_item", libgtk.}
'
j='proc getProxyMenuItem*(toolItem: ToolItem; menuItemId: cstring): MenuItem {.
    importc: "gtk_tool_item_get_proxy_menu_item", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getLabelWidget*(button: ToolButton): Widget {.
    importc: "gtk_tool_button_get_label_widget", libgtk.}
'
j='proc getLabelWidget*(button: ToolButton): Label {.
    importc: "gtk_tool_button_get_label_widget", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getMenu*(button: MenuToolButton): Widget {.
    importc: "gtk_menu_tool_button_get_menu", libgtk.}
'
j='proc getMenu*(button: MenuToolButton): Menu {.
    importc: "gtk_menu_tool_button_get_menu", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc messageDialogNew*(parent: Window; flags: DialogFlags;
                         `type`: MessageType; buttons: ButtonsType;
                         messageFormat: cstring): Widget {.varargs,
    importc: "gtk_message_dialog_new", libgtk.}
'
j='proc messageDialogNew*(parent: Window; flags: DialogFlags;
                         `type`: MessageType; buttons: ButtonsType;
                         messageFormat: cstring): MessageDialog {.varargs,
    importc: "gtk_message_dialog_new", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc messageDialogNewWithMarkup*(parent: Window; flags: DialogFlags;
                                   `type`: MessageType;
                                   buttons: ButtonsType; messageFormat: cstring): Widget {.
    varargs, importc: "gtk_message_dialog_new_with_markup", libgtk.}
'
j='proc messageDialogNewWithMarkup*(parent: Window; flags: DialogFlags;
                                   `type`: MessageType;
                                   buttons: ButtonsType; messageFormat: cstring): MessageDialog {.
    varargs, importc: "gtk_message_dialog_new_with_markup", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getImage*(dialog: MessageDialog): Widget {.
    importc: "gtk_message_dialog_get_image", libgtk.}
'
j='proc getImage*(dialog: MessageDialog): Image {.
    importc: "gtk_message_dialog_get_image", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc newFromWidget*(radioGroupMember: RadioButton): Widget {.
    importc: "gtk_radio_button_new_from_widget", libgtk.}
'
j='proc newFromWidget*(radioGroupMember: RadioButton): RadioButton {.
    importc: "gtk_radio_button_new_from_widget", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc radioButtonNewWithLabel*(group: glib.GSList; label: cstring): Widget {.
    importc: "gtk_radio_button_new_with_label", libgtk.}
'
j='proc radioButtonNewWithLabel*(group: glib.GSList; label: cstring): RadioButton {.
    importc: "gtk_radio_button_new_with_label", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc newWithLabelFromWidget*(radioGroupMember: RadioButton;
    label: cstring): Widget {.importc: "gtk_radio_button_new_with_label_from_widget",
                                 libgtk.}
'
j='proc newWithLabelFromWidget*(radioGroupMember: RadioButton;
    label: cstring): RadioButton {.importc: "gtk_radio_button_new_with_label_from_widget",
                                 libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc radioButtonNewWithMnemonic*(group: glib.GSList; label: cstring): Widget {.
    importc: "gtk_radio_button_new_with_mnemonic", libgtk.}
'
j='proc radioButtonNewWithMnemonic*(group: glib.GSList; label: cstring): RadioButton {.
    importc: "gtk_radio_button_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc newWithMnemonicFromWidget*(
    radioGroupMember: RadioButton; label: cstring): Widget {.
    importc: "gtk_radio_button_new_with_mnemonic_from_widget", libgtk.}
'
j='proc newWithMnemonicFromWidget*(
    radioGroupMember: RadioButton; label: cstring): RadioButton {.
    importc: "gtk_radio_button_new_with_mnemonic_from_widget", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc radioMenuItemNewWithLabel*(group: glib.GSList; label: cstring): Widget {.
    importc: "gtk_radio_menu_item_new_with_label", libgtk.}
'
j='proc radioMenuItemNewWithLabel*(group: glib.GSList; label: cstring): RadioMenuItem {.
    importc: "gtk_radio_menu_item_new_with_label", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc radioMenuItemNewWithMnemonic*(group: glib.GSList; label: cstring): Widget {.
    importc: "gtk_radio_menu_item_new_with_mnemonic", libgtk.}
'
j='proc radioMenuItemNewWithMnemonic*(group: glib.GSList; label: cstring): RadioMenuItem {.
    importc: "gtk_radio_menu_item_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc newFromWidget*(group: RadioMenuItem): Widget {.
    importc: "gtk_radio_menu_item_new_from_widget", libgtk.}
'
j='proc newFromWidget*(group: RadioMenuItem): RadioMenuItem {.
    importc: "gtk_radio_menu_item_new_from_widget", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc newWithMnemonicFromWidget*(group: RadioMenuItem;
    label: cstring): Widget {.importc: "gtk_radio_menu_item_new_with_mnemonic_from_widget",
                                 libgtk.}
'
j='proc newWithMnemonicFromWidget*(group: RadioMenuItem;
    label: cstring): RadioMenuItem {.importc: "gtk_radio_menu_item_new_with_mnemonic_from_widget",
                                 libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc newWithLabelFromWidget*(group: RadioMenuItem;
    label: cstring): Widget {.importc: "gtk_radio_menu_item_new_with_label_from_widget",
                                 libgtk.}
'
j='proc newWithLabelFromWidget*(group: RadioMenuItem;
    label: cstring): RadioMenuItem {.importc: "gtk_radio_menu_item_new_with_label_from_widget",
                                 libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc scaleNewWithRange*(orientation: Orientation; min: cdouble; max: cdouble;
                          step: cdouble): Widget {.
    importc: "gtk_scale_new_with_range", libgtk.}
'
j='proc scaleNewWithRange*(orientation: Orientation; min: cdouble; max: cdouble;
                          step: cdouble): Scale {.
    importc: "gtk_scale_new_with_range", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getHscrollbar*(scrolledWindow: ScrolledWindow): Widget {.
    importc: "gtk_scrolled_window_get_hscrollbar", libgtk.}
'
j='proc getHscrollbar*(scrolledWindow: ScrolledWindow): HScrollbar {.
    importc: "gtk_scrolled_window_get_hscrollbar", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getVscrollbar*(scrolledWindow: ScrolledWindow): Widget {.
    importc: "gtk_scrolled_window_get_vscrollbar", libgtk.}
'
j='proc getVscrollbar*(scrolledWindow: ScrolledWindow): VScrollbar {.
    importc: "gtk_scrolled_window_get_vscrollbar", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc spinButtonNewWithRange*(min: cdouble; max: cdouble; step: cdouble): Widget {.
    importc: "gtk_spin_button_new_with_range", libgtk.}
'
j='proc spinButtonNewWithRange*(min: cdouble; max: cdouble; step: cdouble): SpinButton {.
    importc: "gtk_spin_button_new_with_range", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc textViewNewWithBuffer*(buffer: TextBuffer): Widget {.
    importc: "gtk_text_view_new_with_buffer", libgtk.}
'
j='proc textViewNewWithBuffer*(buffer: TextBuffer): TextView {.
    importc: "gtk_text_view_new_with_buffer", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc createMenuItem*(action: Action): Widget {.
    importc: "gtk_action_create_menu_item", libgtk.}
'
j='proc createMenuItem*(action: Action): MenuItem {.
    importc: "gtk_action_create_menu_item", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc createToolItem*(action: Action): Widget {.
    importc: "gtk_action_create_tool_item", libgtk.}
'
j='proc createToolItem*(action: Action): ToolItem {.
    importc: "gtk_action_create_tool_item", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc createMenu*(action: Action): Widget {.
    importc: "gtk_action_create_menu", libgtk.}
'
j='proc createMenu*(action: Action): Menu {.
    importc: "gtk_action_create_menu", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getColorSelection*(
    colorsel: ColorSelectionDialog): Widget {.
    importc: "gtk_color_selection_dialog_get_color_selection", libgtk.}
'
j='proc getColorSelection*(
    colorsel: ColorSelectionDialog): ColorSelection {.
    importc: "gtk_color_selection_dialog_get_color_selection", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getOkButton*(fsd: FontSelectionDialog): Widget {.
    importc: "gtk_font_selection_dialog_get_ok_button", libgtk.}
'
j='proc getOkButton*(fsd: FontSelectionDialog): Button {.
    importc: "gtk_font_selection_dialog_get_ok_button", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getCancelButton*(fsd: FontSelectionDialog): Widget {.
    importc: "gtk_font_selection_dialog_get_cancel_button", libgtk.}
'
j='proc getCancelButton*(fsd: FontSelectionDialog): Button {.
    importc: "gtk_font_selection_dialog_get_cancel_button", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc hscaleNewWithRange*(min: cdouble; max: cdouble; step: cdouble): Widget {.
    importc: "gtk_hscale_new_with_range", libgtk.}
'
j='proc hscaleNewWithRange*(min: cdouble; max: cdouble; step: cdouble): HScale {.
    importc: "gtk_hscale_new_with_range", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc imageMenuItemNewWithLabel*(label: cstring): Widget {.
    importc: "gtk_image_menu_item_new_with_label", libgtk.}
'
j='proc imageMenuItemNewWithLabel*(label: cstring): ImageMenuItem {.
    importc: "gtk_image_menu_item_new_with_label", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc imageMenuItemNewWithMnemonic*(label: cstring): Widget {.
    importc: "gtk_image_menu_item_new_with_mnemonic", libgtk.}
'
j='proc imageMenuItemNewWithMnemonic*(label: cstring): ImageMenuItem {.
    importc: "gtk_image_menu_item_new_with_mnemonic", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc imageMenuItemNewFromStock*(stockId: cstring; accelGroup: AccelGroup): Widget {.
    importc: "gtk_image_menu_item_new_from_stock", libgtk.}
'
j='proc imageMenuItemNewFromStock*(stockId: cstring; accelGroup: AccelGroup): ImageMenuItem {.
    importc: "gtk_image_menu_item_new_from_stock", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc getImage*(imageMenuItem: ImageMenuItem): Widget {.
    importc: "gtk_image_menu_item_get_image", libgtk.}
'
j='proc getImage*(imageMenuItem: ImageMenuItem): Image {.
    importc: "gtk_image_menu_item_get_image", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
i='proc vscaleNewWithRange*(min: cdouble; max: cdouble; step: cdouble): Widget {.
    importc: "gtk_vscale_new_with_range", libgtk.}
'
j='proc vscaleNewWithRange*(min: cdouble; max: cdouble; step: cdouble): VScale {.
    importc: "gtk_vscale_new_with_range", libgtk.}
'
perl -0777 -p -i -e "s%\Q$i\E%%s" final.nim
echo "$j" >> final.nim
