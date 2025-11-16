@tool
extends EditorContextMenuPlugin

const TileMapImporter:Script = preload("tilemap_importer.gd")

var file_dialogue:EditorFileDialog
var selected_tilemap:TileMap


func create_file_dialogue() -> void:
	print("create_file_dialogue")
	var dialogue:EditorFileDialog = EditorFileDialog.new()
	dialogue.name = "TileMapConverterFileDialogue"
	dialogue.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialogue.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialogue.filters = ["*.json"]
	dialogue.title = "Select TileMap Conversion Data"
	dialogue.file_selected.connect(_on_file_selected)
	file_dialogue = dialogue
	EditorInterface.get_base_control().add_child(file_dialogue)
		

func _popup_menu(node_paths: PackedStringArray) -> void:
	print("_popup_menu")
	var scene_root = EditorInterface.get_edited_scene_root() 
	var node = scene_root.get_node_or_null(node_paths[0])
	if node == null or node is not TileMap: return
	selected_tilemap = node
	add_context_menu_item("Convert TileMap", _open_conversion_data_file)
	print(node_paths)
	
func _open_conversion_data_file(node_paths: PackedStringArray):
	print("open_conversion_data_file")
	var dialogue = EditorInterface.get_base_control().get_node_or_null("TileMapConverterFileDialogue")
	if dialogue == null:
		print("dialogue == null")
		create_file_dialogue()
	file_dialogue.popup_file_dialog()

func _on_file_selected(file_path:String):
	print("_on_file_selected")
	var importer = TileMapImporter.new()
	var data = importer.load_data_from_file(file_path)
	var layer = importer.create_layer_from_data(selected_tilemap, data)
	importer.replace_tilemap(selected_tilemap, layer)
