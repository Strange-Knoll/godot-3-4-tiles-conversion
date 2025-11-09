extends Node
class_name TileMapExp

export var output_path:String

var tilemaps:Array = []
#var tilesets:Array = []

#func _ready():
#	_collect_tilemaps(get_tree().root)
#	var dicts = process_tilemaps()
#	for dict in dicts:
#		_write_file(
#			output_path,
#			dict["name"], 
#			dict
#		)


func _write_file(path:String, name:String, dict:Dictionary):
	var json = JSON.print(dict, "\t")

	var file_path = path + "/" + name +".json"
	var file = File.new()
	var error = file.open(file_path, File.WRITE)
	if error == OK:
		file.store_string(json)
		file.close()
		#print("File saved to:", file_path)
	else:
		push_error("Could not open file for writing!")


func _collect_tilemaps(start:Node):
	for child in start.get_children():
		if child is TileMap: 
			tilemaps.append(child)
		
		if child.get_children().size() > 0:
			_collect_tilemaps(child)

func process_tilemap(tilemap:TileMap) -> Dictionary:
	var tileset:TileSet = tilemap.tile_set		

	var dict:Dictionary = {
		"name":tilemap.name,
		#"atlas_path":atlas_path,
		#"tile_ids":tile_ids,
		#"tile_regions":tile_regions,
		"tileset_path":tilemap.tile_set.resource_path,
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
	for indx in used_cells.size() - 1:
		var id = tilemap.get_cell(used_cells[indx].x, used_cells[indx].y)
		var region = tilemap.get_cell_autotile_coord(used_cells[indx].x, used_cells[indx].y)
		var transposed = tilemap.is_cell_transposed(used_cells[indx].x, used_cells[indx].y)
		var x_flipped = tilemap.is_cell_x_flipped(used_cells[indx].x, used_cells[indx].y)
		var y_flipped = tilemap.is_cell_y_flipped(used_cells[indx].x, used_cells[indx].y)
		var atlas_coord:Vector2 = Vector2(
			tileset.tile_get_region(id).position.x/tilemap.cell_size.x,
			tileset.tile_get_region(id).position.y/tilemap.cell_size.y
		)
		var res_path = tileset.tile_get_texture(id).resource_path
		if res_path == null:
			print("res_path null at: ", used_cells[indx].x, used_cells[indx].y)
		dict["cells"].append({
			"x":used_cells[indx].x,
			"y":used_cells[indx].y,
			"id":id,
			"atlas": res_path,
			"atlas_coord": [atlas_coord.x, atlas_coord.y],
			"transposed":transposed,
			"x_flipped":x_flipped,
			"y_flipped":y_flipped
		})
	return dict



func process_tilemaps():
	var out:Array = []
	for tm in tilemaps:
		var tilemap:TileMap = tm
		var tileset:TileSet = tilemap.tile_set
		#if not tilesets.find(tileset):
		#	tilesets.append(tileset)
		
#		var tile_ids = tileset.get_tiles_ids()
#		var atlas_path:Array = []
#		for id in tile_ids:
#			atlas_path.append(tileset.tile_get_texture(id).resource_path)
#
#		var tile_regions:Array = []
#		for id in tile_ids:
#			tile_regions.append(tileset.tile_get_region(id))
		
		

		var dict:Dictionary = {
			"name":tilemap.name,
			#"atlas_path":atlas_path,
			#"tile_ids":tile_ids,
			#"tile_regions":tile_regions,
			"tileset_path":tilemap.tile_set.resource_path,
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
		for indx in used_cells.size() - 1:
			var id = tilemap.get_cell(used_cells[indx].x, used_cells[indx].y)
			var region = tilemap.get_cell_autotile_coord(used_cells[indx].x, used_cells[indx].y)
			var transposed = tilemap.is_cell_transposed(used_cells[indx].x, used_cells[indx].y)
			var x_flipped = tilemap.is_cell_x_flipped(used_cells[indx].x, used_cells[indx].y)
			var y_flipped = tilemap.is_cell_y_flipped(used_cells[indx].x, used_cells[indx].y)
			var atlas_coord:Vector2 = Vector2(
				tileset.tile_get_region(id).position.x/tilemap.cell_size.x,
				tileset.tile_get_region(id).position.y/tilemap.cell_size.y
			)
			var res_path = tileset.tile_get_texture(id).resource_path
			if res_path == null:
				print("res_path null at: ", used_cells[indx].x, used_cells[indx].y)
			dict["cells"].append({
				"x":used_cells[indx].x,
				"y":used_cells[indx].y,
				"id":id,
				"atlas": res_path,
				"atlas_coord": [atlas_coord.x, atlas_coord.y],
				"transposed":transposed,
				"x_flipped":x_flipped,
				"y_flipped":y_flipped
			})
		out.append(dict)
		
	return out
