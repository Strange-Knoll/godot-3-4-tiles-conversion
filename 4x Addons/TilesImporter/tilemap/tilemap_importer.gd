@tool
extends RefCounted

func create_better_layer(data:Dictionary) -> TileMapLayer:
	print_rich("\n<<<<< [color=green][b]Create Better Layer[/b][/color] >>>>>")
	print("\t", data["name"],"\n")
	if data["cells"].size() == 0: 
		print_rich("[color=red]no cells in data[/color]")
		return null
	var out := TileMapLayer.new()
	var tileset:TileSet = load(data["tileset_path"]).duplicate()
	tileset.set_tile_size(_v2iarr(data["cell_size"]))
	print("TileSet ref from loaded resource: ", tileset)
	out.name = data["name"]
	out.collision_enabled = true
	out.navigation_enabled = true
	out.occlusion_enabled = true
	out.tile_set = tileset
	print("TileSet ref from out tile_set: ", out.tile_set)
	out.tile_set.set_tile_size(_v2iarr(data["cell_size"]))
	print("\tout.tile_set.tile_size == ", out.tile_set.tile_size)
	out.rendering_quadrant_size = data["cell_quadrant_size"]
	out.physics_quadrant_size = data["cell_quadrant_size"]
	out.collision_visibility_mode = _show_collision(data["show_collision"])
	out.y_sort_enabled = data["cell_y_sort"]
	out.y_sort_origin = _y_sort(data["cell_y_sort"])
	
	for cell in data["cells"]:
		var source_id := _get_source(tileset, cell["source"])
		var coords := _v2iarr(cell["position"])
		var x_flipped = cell["x_flipped"]
		var y_flipped = cell["y_flipped"]
		var transposed = cell["transposed"]
		var alt_tile:int = 0
		alt_tile |= TileSetAtlasSource.TRANSFORM_FLIP_H if x_flipped else 0
		alt_tile |= TileSetAtlasSource.TRANSFORM_FLIP_V if y_flipped else 0
		alt_tile |= TileSetAtlasSource.TRANSFORM_TRANSPOSE if transposed else 0
		var tile_mode = cell["tile_mode"]
		var atlas_coords:Vector2i
		var index := _v2iarr(cell["index"])
		var terrain_cell_coords:Array[Vector2i] = []
		
		if tile_mode == TileMode.Single:
			atlas_coords = index
			print("Single Tile atlas_coords", atlas_coords)
		if tile_mode == TileMode.Auto:
			var auto_index := _v2iarr(cell["autotile_index"])
			atlas_coords = index+auto_index
			terrain_cell_coords.append(coords)
			print("Auto Tile atlas_coords", atlas_coords)
		if tile_mode == TileMode.Atlas:
			var atlas_index := _v2iarr(cell["atlas_index"])
			atlas_coords = atlas_index
			print("Atlas Tile atlas_coords", atlas_coords)
		print_rich("[color=green][b]Attempting set_cell with data ...[/b][/color]")
		print("\tcoords: ", coords)
		print("\tsource_id: ", source_id)
		print("\tatlas_coords: ", atlas_coords)
		print("\talt_tile: ", alt_tile)
		out.set_cell(coords, source_id, atlas_coords, alt_tile)
		if tile_mode == TileMode.Auto:
			print_rich("[color=yellow]Attempting set_cells_terrain_connect with data ...[/color]")
			print("\tterrain_cell_coords: ", terrain_cell_coords)
			out.set_cells_terrain_connect(terrain_cell_coords, 0, 0)
	return out

func _get_source(tileset:TileSet, path:String) -> int:
	print_rich("[color=yellow]... _get_source() ...[/color]")
	var out:int = -1
	print("\tget_source_count() == ", tileset.get_source_count())
	for indx in tileset.get_source_count():
		var source_id = tileset.get_source_id(indx)
		var test:TileSetAtlasSource = tileset.get_source(source_id)
		print("\tpath == ", path)
		print("\tresource_path == ", test.texture.resource_path)
		if test.texture.resource_path == path: 
			out = source_id
	return out

func _y_sort(b:bool) -> int:
	if b: return 1
	else: return 0

func _show_collision(b:bool) -> TileMapLayer.DebugVisibilityMode:
	if b: return TileMapLayer.DEBUG_VISIBILITY_MODE_FORCE_SHOW
	else: return TileMapLayer.DEBUG_VISIBILITY_MODE_DEFAULT

func _v2iarr(arr:Array) -> Vector2i:
	return Vector2i(arr[0], arr[1])

enum TileMode {
	Single = 0,
	Auto = 1,
	Atlas = 2
}

func replace_tilemap(old:TileMap, new:TileMapLayer):
	new.name = old.name
	var parent = old.get_parent()
	var index = old.get_index()
	parent.remove_child(old)
	old.queue_free()
	parent.add_child(new)
	if parent.owner == null: new.owner = parent
	else: new.owner = parent.owner
	parent.move_child(new, index)

func overwrite_save(old_scene_path:String, new_scene:PackedScene):
	ResourceSaver.save(new_scene, old_scene_path)

func backup_and_save(old_scene_path:String, new_scene:PackedScene):
	var swap_path = old_scene_path
	var swap_name = swap_path.get_file()
	var old = load(swap_path)
	var rid = old.get_rid()
	print("old rid: ", rid)
	var backup_dir = _create_dir("res://", "converted_scenes_backup")
	old.take_over_path(backup_dir+swap_name)
	ResourceSaver.save(old)
	ResourceSaver.save(new_scene, swap_path)
	ResourceSaver.set_uid(swap_path, rid.get_id())

func load_data_from_file(file_path:String) -> Dictionary:
	print("load_data_from_file: ", file_path)
	var text := FileAccess.get_file_as_string(file_path)
	if text.is_empty():
		push_error("JSON file was empty")
		return {}
	var result:Dictionary = JSON.to_native(JSON.parse_string(text), true)
	if result == null:
		push_error("Invalid JSON format")
		return {}
	return result

func create_layer_from_data(node:TileMap, data:Dictionary) -> TileMapLayer:
	print("create_layer_from_data")
	print("converting ", node.name)
	if data["cells"].size() == 0: 
		return null
	var out:TileMapLayer = TileMapLayer.new()
	var tileset_path = data["tileset_path"]
	var tileset:TileSet = load(tileset_path)
	print("loaded tileset: ", tileset.resource_path)
	out.tile_set = tileset
	out.rendering_quadrant_size = data["cell_quadrant_size"]
	out.physics_quadrant_size = data["cell_quadrant_size"]
	if data["show_collision"] == true:
		out.collision_visibility_mode = TileMapLayer.DEBUG_VISIBILITY_MODE_FORCE_SHOW
	else:
		out.collision_visibility_mode = TileMapLayer.DEBUG_VISIBILITY_MODE_DEFAULT
	
	
	for cell in data["cells"]:
		var coord = Vector2i(cell["x"], cell["y"])
		var atlas_size = cell["atlas_size"]
		if coord.x > atlas_size[0] or coord.y > atlas_size[1]:
			continue
		var atlas_coord = Vector2i(cell["atlas_coord"][0], cell["atlas_coord"][1])
		# the source_id is super wrong
		var source:int
		for indx in tileset.get_source_count():
			if tileset.get_source(indx).texture.resource_path == cell["atlas"]:
				source = indx
		var transposed = cell["transposed"]
		var x_flipped = cell["x_flipped"]
		var y_flipped = cell["y_flipped"]
		
		var alternate_id:int = 0
		alternate_id |= TileSetAtlasSource.TRANSFORM_FLIP_H if x_flipped else 0
		alternate_id |= TileSetAtlasSource.TRANSFORM_FLIP_V if y_flipped else 0
		alternate_id |= TileSetAtlasSource.TRANSFORM_TRANSPOSE if transposed else 0
		out.set_cell(coord, tileset.get_source_id(source), atlas_coord, alternate_id)
	
	return out

func _create_dir(path:String, dir_name:String) -> String:
	var full_path = path+"/"+dir_name
	var dir := DirAccess.open(path)
	if not dir.dir_exists(full_path):
		dir.make_dir(full_path)
	return full_path+"/"
