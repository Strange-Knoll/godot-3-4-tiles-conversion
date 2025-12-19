extends Reference

func better_process(tilemap:TileMap) -> Dictionary:
	tilemap.fix_invalid_tiles()
	var tileset:TileSet
	var tileset_path := ""
	if tilemap.tile_set != null:
		tileset = tilemap.tile_set
		tileset_path = tileset.resource_path
	
	var out:Dictionary = {
		"name":tilemap.name,
		"node_path":null,
		"tileset_path":tileset_path,
		"sources":[],
		"cell_size":_v2arr(tilemap.cell_size),
		"cell_quadrant_size":tilemap.cell_quadrant_size,
		"cell_custom_transfrom":_trans2arr(tilemap.cell_custom_transform),
		"cell_half_offset":tilemap.cell_half_offset,
		"cell_tile_origin":tilemap.cell_tile_origin,
		"cell_y_sort":tilemap.cell_y_sort,
		"show_collision":tilemap.show_collision,
		"compatibility_mode":tilemap.compatibility_mode,
		"centered_textures":tilemap.centered_textures,
		"cell_clip_uv":tilemap.cell_clip_uv,
		"collision_use_parent":tilemap.collision_use_parent,
		"collision_use_kinematic":tilemap.collision_use_kinematic,
		"collision_friction":tilemap.collision_friction,
		"collision_bounce":tilemap.collision_bounce,
		"collision_layer":tilemap.collision_layer,
		"collision_mask":tilemap.collision_mask,
		"bake_nav":tilemap.bake_navigation,
		"nav_layers":tilemap.navigation_layers,
		"occluder_light_mask":tilemap.occluder_light_mask,
		"cells":[]
	}
	
	var cells = tilemap.get_used_cells()
	if cells.size() == 0 or tilemap.tile_set == null: return out
	for cell in cells:
		cell = cell as Vector2
		var id:int = tilemap.get_cell(cell.x, cell.y)
		var tile_mode = tileset.tile_get_tile_mode(id)
		var transposed = tilemap.is_cell_transposed(cell.x, cell.y)
		var x_flipped = tilemap.is_cell_x_flipped(cell.x, cell.y)
		var y_flipped = tilemap.is_cell_y_flipped(cell.x, cell.y)
		var region = tileset.tile_get_region(id)
		var source = tileset.tile_get_texture(id).resource_path
		if not out["sources"].has(source):
			out["sources"].append(source)
		
		var cell_out:Dictionary = {
			"id":id,
			"source": source,
			"index":_v2arr(region.position / region.size),
			"position": _v2arr(cell),
			"tile_mode": tile_mode,
			"transposed": transposed,
			"x_flipped": x_flipped,
			"y_flipped": y_flipped
		}
		if tile_mode == TileSet.AUTO_TILE:
			cell_out["autotile_index"] = _v2arr(
				tilemap.get_cell_autotile_coord(cell.x, cell.y))
		if tile_mode == TileSet.ATLAS_TILE:
			cell_out["atlas_index"] = _v2arr(
				tilemap.get_cell_autotile_coord(cell.x, cell.y))
		out["cells"].append(cell_out)
	return out
	
func _v2arr(v:Vector2) -> Array:
	return [v.x, v.y]

func _trans2arr(trans:Transform2D) -> Array:
	return [_v2arr(trans.x), _v2arr(trans.y), _v2arr(trans.origin)]

# TODO: ignore export of tile outside of texture
# TODO: fix alternative id thing
func process_tilemap(tilemap:TileMap) -> Dictionary:
	#print("inside process func for ", tilemap.name)
	tilemap.fix_invalid_tiles()

	var tileset_res_path:String = ""
	if tilemap.tile_set != null:
		#print("tile set found in ", tilemap.name)
		tileset_res_path = tilemap.tile_set.resource_path
	
	var dict:Dictionary = {
		"name":tilemap.name,
		"node_path":null,
		"scene_resource_path":null,
		"tileset_path":tileset_res_path,
		"cell_size":[
			tilemap.cell_size.x,
			tilemap.cell_size.y
		],
		"cell_quadrant_size":tilemap.cell_quadrant_size,
		"cell_custom_transform":[
			[tilemap.cell_custom_transform.x.x,tilemap.cell_custom_transform.x.y],
			[tilemap.cell_custom_transform.y.x,tilemap.cell_custom_transform.y.y],
			[tilemap.cell_custom_transform.origin.x,tilemap.cell_custom_transform.origin.y]
		],
		"cell_half_offest":tilemap.cell_half_offset,
		"cell_tile_origin":tilemap.cell_tile_origin,
		"cell_y_sort":tilemap.cell_y_sort,
		"show_collision":tilemap.show_collision,
		"compatibility_mode":tilemap.compatibility_mode,
		"centered_textures":tilemap.centered_textures,
		"cell_clip_uv":tilemap.cell_clip_uv,
		"collision_use_parent":tilemap.collision_use_parent,
		"collision_use_kinematic":tilemap.collision_use_kinematic,
		"collision_friction":tilemap.collision_friction,
		"collision_bounce":tilemap.collision_bounce,
		"collision_layer":tilemap.collision_layer,
		"collision_mask":tilemap.collision_mask,
		"bake_nav":tilemap.bake_navigation,
		"nav_layers":tilemap.navigation_layers,
		"occluder_light_mask":tilemap.occluder_light_mask,
		
		"cells":[]
	}

	var used_cells:Array = tilemap.get_used_cells()
	if used_cells.size() != 0 and tilemap.tile_set != null:
		#print("found used cells in ", tilemap.name)
		var tileset = tilemap.tile_set
#		if not tileset:
#			print("no tileset exists in ", tilemap.name)
#			tileset = TileSet.new()
		for indx in used_cells.size() - 1:
			var id = tilemap.get_cell(used_cells[indx].x, used_cells[indx].y)
			var region = tilemap.get_cell_autotile_coord(used_cells[indx].x, used_cells[indx].y)
			var transposed = tilemap.is_cell_transposed(used_cells[indx].x, used_cells[indx].y)
			var x_flipped = tilemap.is_cell_x_flipped(used_cells[indx].x, used_cells[indx].y)
			var y_flipped = tilemap.is_cell_y_flipped(used_cells[indx].x, used_cells[indx].y)
			var atlas_coord:Vector2 = Vector2(
				tileset.tile_get_region(id).position.x/tilemap.cell_size.x, ### i think this is the crash
				tileset.tile_get_region(id).position.y/tilemap.cell_size.y
			)
			var atlas_tex = tileset.tile_get_texture(id)
			var res_path = atlas_tex.resource_path
			#if res_path == null:
				#print("res_path null at: ", used_cells[indx].x, used_cells[indx].y)
			dict["cells"].append({
				"x":used_cells[indx].x,
				"y":used_cells[indx].y,
				"id":id,
				"atlas": res_path,
				"atlas_size":[atlas_tex.get_width(), atlas_tex.get_height()],
				"atlas_coord": [atlas_coord.x, atlas_coord.y],
				"transposed":transposed,
				"x_flipped":x_flipped,
				"y_flipped":y_flipped
			})
	else:
		#print("no used cells found in ", tilemap.name)
		pass
	return dict

func export_tilemap(path:String, tilemap:TileMap):
	var data := better_process(tilemap)
	var json = JSON.print(data, "\t")
	var file = File.new()
	var error = file.open(path, File.WRITE)
	
	if error == OK:
		file.store_string(json)
		file.close()
	else:
		push_error("Could not open file for writing!")
