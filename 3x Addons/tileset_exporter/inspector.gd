tool
extends EditorInspectorPlugin
class_name TileSetExporterInspectorPlugin

var _plugin:EditorPlugin
var _selected_tileset:TileSet
var file_dialog:EditorFileDialog
var exporter:TileSetExp

func set_plugin(p:EditorPlugin) -> void:
	#print("set_plugin( ", p, " )")
	if not _plugin: _plugin = p
	#print("_plugin == ", _plugin)
	if not exporter: 
		exporter = TileSetExp.new()
	#print("exporter == ", exporter)
	
	
func can_handle(object) -> bool:
	return object is TileSet

func parse_begin(object):
	_selected_tileset = object
	var btn = Button.new()
	btn.name = "TileSetExportButton"
	btn.text = "Export TileSet"
	btn.align = Button.ALIGN_CENTER
	btn.connect("button_up", self, "_export_btn_pressed")
	add_custom_control(btn)

func _export_btn_pressed():
	print("_export_btn_pressed()")
	var popup:EditorFileDialog = _get_file_dialogue()
	popup.popup_centered(Vector2(800,600))

func _get_file_dialogue() -> EditorFileDialog:
	#print("_get_file_dialogue()")
	#print("self.file_dialog == ", file_dialog)
	if not self.file_dialog:
		file_dialog = EditorFileDialog.new()
		file_dialog.name = "TileSetExporterFileDialog"
		file_dialog.window_title = "Save TileSet JSON Data"
		file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
		file_dialog.display_mode = EditorFileDialog.DISPLAY_LIST
		file_dialog.mode = EditorFileDialog.MODE_SAVE_FILE
		file_dialog.show_on_top = true
		file_dialog.dialog_hide_on_ok = true
		file_dialog.add_filter("*.json; JSON")
		file_dialog.connect("file_selected", self, "_export")
		#print("_plugin == ", _plugin)
		var base = _plugin.get_editor_interface().get_base_control()
		base.add_child(file_dialog)
		base.move_child(file_dialog, 0)
	#print("self.file_dialog == ", file_dialog)
	return file_dialog

func _export(path:String):
	#print("_export( ", path, " )")
	var data = exporter.process_tileset(_selected_tileset)
	var json = JSON.print(data, "\t")
	
	#print("path.get_file() == ", path.get_file())
	var file_name_no_ext = path.get_file().get_slice(".json", 0)
	#print("file_name_no_ext == ", file_name_no_ext)
	
	var file = File.new()
	var file_path:String
	var error
	## determine of the user entered a name or not
	if file_name_no_ext == "":
		## if no, build the path with the resource name
		var constructed_path = path.get_slice(".json",0) 
		constructed_path += _selected_tileset.resource_path.get_file().get_slice(".tres",0)
		constructed_path += ".json"
		#print("constructed_path == ", constructed_path)
		file_path = constructed_path
	else: 
		# if yes, just save that
		file_path = path
	
	error = file.open(file_path, File.WRITE)
	if error == OK:
		file.store_string(json)
		file.close()
		print("File saved to:", file_path)
	else:
		push_error("Could not open file for writing!")


