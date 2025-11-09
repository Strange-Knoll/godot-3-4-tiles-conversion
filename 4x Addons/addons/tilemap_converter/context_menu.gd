@tool
extends EditorContextMenuPlugin

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
	add_context_menu_item("Convert TileMap", open_conversion_data_file)
	print(node_paths)
	
func open_conversion_data_file(node_paths: PackedStringArray):
	print("open_conversion_data_file")
	var dialogue = EditorInterface.get_base_control().get_node_or_null("TileMapConverterFileDialogue")
	if dialogue == null:
		print("dialogue == null")
		create_file_dialogue()
	file_dialogue.popup_file_dialog()

func _on_file_selected(file_path:String):
	print("_on_file_selected")
	var data = load_data_from_file(file_path)
	var layer = create_layer_from_data(selected_tilemap, data)
	layer.name = selected_tilemap.name
	var parent = selected_tilemap.get_parent()
	var index = selected_tilemap.get_index()
	parent.remove_child(selected_tilemap)
	selected_tilemap.queue_free()
	parent.add_child(layer)
	if parent.owner == null: layer.owner = parent
	else: layer.owner = parent.owner
	parent.move_child(layer, index)

func load_data_from_file(file_path:String) -> Dictionary:
	print("load_data_from_file")
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
	print("create_layer_from_data")
	var out:TileMapLayer = TileMapLayer.new()
	var tileset_path = data["tileset_path"]
	var tileset:TileSet = load(tileset_path)
	out.tile_set = tileset
	out.rendering_quadrant_size = data["cell_quadrant_size"]
	out.physics_quadrant_size = data["cell_quadrant_size"]
	if data["show_collision"] == true:
		out.collision_visibility_mode = TileMapLayer.DEBUG_VISIBILITY_MODE_FORCE_SHOW
	else:
		out.collision_visibility_mode = TileMapLayer.DEBUG_VISIBILITY_MODE_DEFAULT
	
	
	for cell in data["cells"]:
		var coord = Vector2i(cell["x"], cell["y"])
		var atlas_coord = Vector2i(cell["atlas_coord"][0], cell["atlas_coord"][1])
		# the source_id is super wrong
		var source:int
		for indx in tileset.get_source_count():
			if tileset.get_source(indx).texture.resource_path == cell["atlas"]:
				source = indx
		out.set_cell(coord, tileset.get_source_id(source), atlas_coord)
		var tile_data:TileData = out.get_cell_tile_data(coord)
		tile_data.flip_h = cell["x_flipped"]
		tile_data.flip_v = cell["y_flipped"]
		tile_data.transpose = cell["transposed"]
		#out._tile_data_runtime_update(coord, tile_data)
	
	return out
