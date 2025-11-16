@tool
extends RefCounted

func overwrite_save(old_tileset_path:String, new_tileset:TileSet):
	ResourceSaver.save(new_tileset, old_tileset_path)

func backup_and_save(old_tileset_path:String, new_tileset:TileSet):
	var swap_path = old_tileset_path
	var swap_name = swap_path.get_file()
	var old = load(swap_path)
	var rid = old.get_rid()
	print("old rid: ", rid)
	var backup_dir = _create_dir("res://", "converted_tileset_backup")
	old.take_over_path(backup_dir+swap_name)
	ResourceSaver.save(old)
	ResourceSaver.save(new_tileset, swap_path)
	ResourceSaver.set_uid(swap_path, rid.get_id())

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
			var pos_check = Vector2i(
				# 64 / 32 = 2
				tile["coord"]["x"] + tile["tile"]["region"][2], 
				tile["coord"]["y"] + tile["tile"]["region"][3]
			)
			var size = source.texture.get_size()
			if pos_check.x > size.x or pos_check.y > size.y:
				continue
			
			var pos = Vector2i(
				# 64 / 32 = 2
				tile["coord"]["x"] / tile["tile"]["region"][2], 
				tile["coord"]["y"] / tile["tile"]["region"][3]
			)
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
				
func _create_dir(path:String, dir_name:String) -> String:
	var full_path = path+"/"+dir_name
	var dir := DirAccess.open(path)
	if not dir.dir_exists(full_path):
		dir.make_dir(full_path)
	return full_path+"/"
