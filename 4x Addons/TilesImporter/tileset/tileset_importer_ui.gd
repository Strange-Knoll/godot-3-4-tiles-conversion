@tool
extends EditorContextMenuPlugin

const TileSetImporter:Script = preload("tileset_importer.gd")
var file_dialogue:EditorFileDialog
var selected_tileset:TileSet

func _create_file_dialogue() -> void:
	print("create_file_dialogue")
	var dialogue:EditorFileDialog = EditorFileDialog.new()
	dialogue.name = "TileSetConverterFileDialogue"
	dialogue.access = EditorFileDialog.ACCESS_FILESYSTEM
	dialogue.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialogue.filters = ["*.json"]
	dialogue.title = "Select TileSet Conversion Data"
	dialogue.file_selected.connect(_on_file_selected)
	file_dialogue = dialogue
	EditorInterface.get_base_control().add_child(file_dialogue)
	
func _popup_menu(resource_paths: PackedStringArray) -> void:
	var res = load(resource_paths[0])
	if not res is TileSet: return
	selected_tileset = res
	add_context_menu_item("Convert Tileset", _on_click)
	#print(resource_paths)

func _on_click(_res_path:PackedStringArray):
	var base_control := EditorInterface.get_base_control()
	if base_control.get_node_or_null("TileSetConverterFileDialogue") == null:
		_create_file_dialogue()
	file_dialogue.popup_file_dialog()

func _on_file_selected(path:String):
	var importer = TileSetImporter.new()
	var data:Dictionary = importer.load_data_from_file(path)
	var tileset:TileSet = importer.create_tileset_from_data(data)
	importer.backup_and_save(selected_tileset.resource_path, tileset)
	
	
	
	
