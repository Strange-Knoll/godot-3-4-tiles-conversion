tool
extends EditorInspectorPlugin

const TileMapExp = preload("tilemap_exporter.gd")

var exporter:TileMapExp

var _plugin:EditorPlugin
var _selected_tilemap:TileMap
var file_dialog:EditorFileDialog

func set_plugin(p:EditorPlugin) -> void:
	#print("set_plugin( ", p, " )")
	if not _plugin: _plugin = p
	#print("_plugin == ", _plugin)
	if not exporter: 
		exporter = TileMapExp.new()
	#print("exporter == ", exporter)
	
	
func can_handle(object) -> bool:
	return object is TileMap

func parse_begin(object):
	_selected_tilemap = object
	var btn = Button.new()
	btn.name = "TileMapExportButton"
	btn.text = "Export TileMap"
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
		file_dialog.name = "TileMapExporterFileDialog"
		file_dialog.window_title = "Save TileMap JSON Data"
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
	var data = exporter.process_tilemap(_selected_tilemap)
	
	## TODO: add resource path to data ... somehow
	
	var json = JSON.print(data, "\t")
	
	#print("path.get_file() == ", path.get_file())
	var file_name_no_ext = path.get_file().get_slice(".json", 0)
	#print("file_name_no_ext == ", file_name_no_ext)
	
	var file = File.new()
	var file_path:String
	var error
	## determine of the user entered a name or not
	if file_name_no_ext == "":
		var node_path_string:String = ""
		var node_path = _find_scene_root(_selected_tilemap).get_path_to(_selected_tilemap)
		for indx in node_path.get_name_count():
			node_path_string += node_path.get_name(indx)+"%"
		## if no, build the path with the resource name
		var constructed_path = path.get_slice(".json",0) 
		constructed_path += node_path_string.rstrip("%")
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

func _find_scene_root(start:Node) -> Node:
	var test:Node = start
	while test.owner != null:
		test = test.get_parent()
	return test
