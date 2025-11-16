tool
extends EditorInspectorPlugin

const TileMapExp = preload("tilemap_exporter.gd")
var exporter:TileMapExp

var _plugin:EditorPlugin
var _file_dialog:EditorFileDialog

func set_plugin(p:EditorPlugin) -> void:
	if not _plugin: _plugin = p
	if not exporter: exporter = TileMapExp.new()

func can_handle(object) -> bool:
	return object is TileMap

func parse_begin(object):
	object = object as TileMap
	var btn = Button.new()
	btn.name = "TileMapExportButton"
	btn.text = "Export TileMap"
	btn.align = Button.ALIGN_CENTER
	btn.connect("button_up", self, "_export_btn_pressed", [object])
	add_custom_control(btn)

func _export_btn_pressed(ref:TileMap):
	var popup:EditorFileDialog = _get_file_dialogue()
	popup.current_file = ref.name
	if not popup.is_connected("file_selected", exporter, "export_tilemap"):
		popup.connect("file_selected", exporter, "export_tilemap", [ref])
	popup.popup_centered(Vector2(800,600))

func _get_file_dialogue() -> EditorFileDialog:
	if not self._file_dialog:
		_file_dialog = EditorFileDialog.new()
		_file_dialog.name = "TileMapExporterFileDialog"
		_file_dialog.window_title = "Save TileMap JSON Data"
		_file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
		_file_dialog.display_mode = EditorFileDialog.DISPLAY_LIST
		_file_dialog.mode = EditorFileDialog.MODE_SAVE_FILE
		_file_dialog.show_on_top = true
		_file_dialog.dialog_hide_on_ok = true
		_file_dialog.disable_overwrite_warning = false
		_file_dialog.add_filter("*.json; JSON")
		var base = _plugin.get_editor_interface().get_base_control()
		base.add_child(_file_dialog)
		base.move_child(_file_dialog, 0)
	return _file_dialog
