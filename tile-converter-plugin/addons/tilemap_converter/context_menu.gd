@tool
extends EditorContextMenuPlugin

var file_dialogue:EditorFileDialog
var selected_tilemap:TileMap


func _create_file_dialogue() -> EditorFileDialog:
	var file_dialogue:EditorFileDialog = EditorFileDialog.new()
	file_dialogue.name = "TileMapConverterFileDialogue"
	file_dialogue.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialogue.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialogue.filters = ["*.json"]
	file_dialogue.title = "Select TileMap Conversion Data"
	file_dialogue.file_selected.connect(_on_file_selected)
	EditorInterface.get_base_control().add_child(file_dialogue)
	return file_dialogue

func _notification(what: int) -> void:
	var dialogue = EditorInterface.get_base_control().get_node_or_null("TileMapConverterFileDialogue")
	if what == NOTIFICATION_EXTENSION_RELOADED and dialogue == null:
		file_dialogue = _create_file_dialogue()
		

func _popup_menu(node_paths: PackedStringArray) -> void:
	var scene_root = EditorInterface.get_edited_scene_root() 
	var node = scene_root.get_node_or_null(node_paths[0])
	if node == null or node is not TileMap: return
	selected_tilemap = node
	add_context_menu_item("Convert TileMap", open_conversion_data_file)
	print(node_paths)
	
func open_conversion_data_file(node_paths: PackedStringArray):
	file_dialogue.popup_file_dialog()

func _on_file_selected(file_path:String):
	var data = load_resource_from_path(file_path)
	var layer = create_layer_from_data(selected_tilemap, data)

func load_resource_from_path(file_path:String) -> Dictionary:
	var text := FileAccess.get_file_as_string(file_path)
	if text.is_empty():
		push_error("JSON file was empty")
		return {}
	var result:Dictionary = JSON.parse_string(text)
	if result == null:
		push_error("Invalid JSON format")
		return {}
	return result

func create_layer_from_data(node:TileMap, data:Dictionary) -> TileMapLayer:
	var out:TileMapLayer = TileMapLayer.new()
	
	return out
