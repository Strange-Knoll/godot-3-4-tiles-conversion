@tool
extends EditorContextMenuPlugin

var file_dialogue:EditorFileDialog
var selected_tileset:TileSet

func create_file_dialogue() -> void:
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
	if EditorInterface.get_base_control().get_node_or_null("TileSetConverterFileDialogue") == null:
		create_file_dialogue()
	file_dialogue.popup_file_dialog()

func _on_file_selected(path:String):
	var data:Dictionary = load_data_from_file(path)
	var tileset:TileSet = create_tileset_from_data(data)
	var swap_path = selected_tileset.resource_path
	var swap_name = swap_path.get_file()
	var old = load(swap_path)
	var rid = old.get_rid()
	print("old rid: ", rid)
	old.take_over_path("res://conversion_dump/"+swap_name)
	#var err = ResourceSaver.save(old, "res://conversion_dump/"+swap_name)
	#printerr("move old: ", err)
	
	#_move_old_res_to_dump(swap_path)
	ResourceSaver.save(tileset, swap_path)
	ResourceSaver.set_uid(swap_path, rid.get_id())

func _move_old_res_to_dump(old:String):
	print("_move_old_res_to_dump( ", old, " )")
	var old_path = old
	# Open a DirAccess at the project root
	var dir := DirAccess.open("res://")
	# Ensure destination folder exists
	var target_folder = "res://conversion_dump/"
	if not dir.dir_exists(target_folder):
		print("creating dump folder")
		var err = dir.make_dir("conversion_dump")
		if err != OK:
			push_error("Failed to create folder: " + str(err))
			return
	# Move the file
	var new_path = target_folder + old_path.get_file()
	print("file dumped to: ", new_path)
	var err = dir.rename(old_path, new_path)
	if err == OK: print("Moved successfully!")
	else: push_error("Failed to move: " + str(err))

func load_data_from_file(file_path:String) -> Dictionary:
	#print("load_data_from_file")
	var text := FileAccess.get_file_as_string(file_path)
	if text.is_empty():
		push_error("JSON file was empty")
		return {}
	var result:Dictionary = JSON.parse_string(text)
	if result == null:
		push_error("Invalid JSON format")
		return {}
	return result

func create_tileset_from_data(data:Dictionary) -> TileSet:
	var out := TileSet.new()
	out.add_navigation_layer(0)
	out.add_occlusion_layer(0)
	out.add_physics_layer(0)
	out.tile_size = Vector2i(64,64)
	
	var groups:Dictionary[String, Array] # {"path":["tile_data"]}
	for tile_data in data["tile_data"]:
		var texture_path = tile_data["tile"]["texture"]
		groups.get_or_add(texture_path, []).append(tile_data)
		#if not groups.keys().has(texture_path):
			#print("new tex found: ", texture_path)
			#groups.merge({texture_path:[]})
			##groups[texture_path] = []
		#groups[texture_path].append(tile_data)
	
	print("groups: ", groups.keys())
	for path in groups.keys():
		var source := TileSetAtlasSource.new()
		out.add_source(source)
		
		print("path: ", path, 
			"\nsources: ", out.get_source_count(), 
			"\nsource: ", source, "\n")
		source.texture = load(path)
		var sep:float = groups[path][0]["autotile"]["spacing"]
		source.separation = Vector2(sep,sep)
		if groups[path].size() < 2: # if size is 1 then this is an atlas
			source.texture_region_size = source.texture.get_size()
		else: # if there are more than 1 elements this is a group of single tiles
			var size = Vector2(
				groups[path][0]["tile"]["region"][2], 
				groups[path][0]["tile"]["region"][3])
			source.texture_region_size = size
			out.tile_size = size

		for tile in groups[path]:
			var pos = Vector2i(
				tile["coord"]["x"] / tile["tile"]["region"][2], 
				tile["coord"]["y"] / tile["tile"]["region"][3]
			)
			#print("tile id: ", tile["id"])
			#print("sources: ", out.get_source_count()) 
			#print("source:", source, "\n")
			source.create_tile(pos)
			var tile_data:TileData = source.get_tile_data(pos, 0)
			for indx in tile["tile"]["shapes"].size()-1:
				var shape = tile["tile"]["shapes"][indx]
				var packed_string:String
				_create_collisions(tile_data, shape, indx)
			if tile["tile"]["nav_polygon"] != null:
				for indx in tile["tile"]["nav_polygon"].size()-1:
					var nav_poly := NavigationPolygon.new()
					nav_poly.add_outline(_string_to_v2_arr(tile["tile"]["nav_polygon"][indx]))
					tile_data.set_navigation_polygon(0, nav_poly)
			if tile["tile"]["light_occluder"] != null:
				#print("occluder: ", tile["tile"]["light_occluder"])
				var occ_poly := OccluderPolygon2D.new()
				occ_poly.polygon = _string_to_v2_arr(tile["tile"]["light_occluder"]["pool"])
				occ_poly.cull_mode = tile["tile"]["light_occluder"]["mode"]
				occ_poly.closed = tile["tile"]["light_occluder"]["closed"]
				tile_data.add_occluder_polygon(0)
				var occ_indx = tile_data.get_occluder_polygons_count(0)-1
				tile_data.set_occluder_polygon(0, occ_indx, occ_poly)
	
	return out

func _string_to_v2_arr(string:String) -> PackedVector2Array:
	var out: PackedVector2Array
	var strip = string.lstrip("[(").rstrip(")]").remove_chars("(").remove_chars(")").remove_chars(" ")
	var split:PackedStringArray = strip.split(",")
	var indx = 0
	while indx < split.size():
		out.append(
			Vector2(split[indx].to_float(), 
			split[indx+1].to_float()))
		indx+=2
	return out

func _create_collisions(tile_data:TileData, shape:Dictionary, indx:int, ):
	var packed_string:String
	if shape["shape"].keys()[0] == "Convex":
		packed_string = shape["shape"]["Convex"]
	elif shape["shape"].keys()[0] == "Concave":
		packed_string = shape["shape"]["Concave"]
	var packed_vec = _string_to_v2_arr(packed_string)
	tile_data.set_collision_polygon_points(0, indx, packed_vec)
	tile_data.set_collision_polygon_one_way(0, indx, shape["one_way"])
	tile_data.set_collision_polygon_one_way_margin(0, indx, shape["one_way_margin"])
				
