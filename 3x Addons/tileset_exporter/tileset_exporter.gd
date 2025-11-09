extends Node
class_name TileSetExp

export var output_path:String

func process_tileset(tileset:TileSet) -> Dictionary:
	var atlas_ids = tileset.get_tiles_ids()
	var atlas_arr:Array = []
	for id in atlas_ids:
		if not atlas_arr.has(tileset.tile_get_texture(id).resource_path):
			atlas_arr.append(tileset.tile_get_texture(id).resource_path)
	
	var tile_data:Array = []
	for id in tileset.get_tiles_ids():
		var coord:Vector2 = tileset.tile_get_region(id).position
		
		var shapes = tileset.tile_get_shapes(id)
		for indx in shapes.size():
			if shapes[indx]["shape"] is ConvexPolygonShape2D:
				shapes[indx]["shape"] = {"Convex":shapes[indx]["shape"].points}
			if shapes[indx]["shape"] is ConcavePolygonShape2D:
				shapes[indx]["shape"] = {"Concave":shapes[indx]["shape"].points}
		
		var occluder:OccluderPolygon2D = tileset.tile_get_light_occluder(id)
		var light_occluder
		if occluder != null:
			light_occluder = {
				"closed":occluder.closed,
				"mode":occluder.cull_mode,
				"pool":occluder.polygon
			}
		else: light_occluder = null
		
		occluder = tileset.autotile_get_light_occluder(id, coord)
		var autotile_light_occluder
		if occluder != null:
			autotile_light_occluder = {
				"closed":occluder.closed,
				"mode":occluder.cull_mode,
				"pool":occluder.polygon
			}
		else: autotile_light_occluder = null
		
		var nav_poly:NavigationPolygon = tileset.autotile_get_navigation_polygon(id, coord)
		var auto_nav_poly
		if nav_poly != null:
			auto_nav_poly = []
			for indx in nav_poly.get_outline_count():
				auto_nav_poly.append(nav_poly.get_outline(indx))
		else: auto_nav_poly = null
		
		nav_poly = tileset.tile_get_navigation_polygon(id)
		var tile_nav_poly
		if nav_poly != null:
			tile_nav_poly = []
			for indx in nav_poly.get_outline_count():
				tile_nav_poly.append(nav_poly.get_outline(indx))
		else: tile_nav_poly = null
		
		var tile_mat:Material = tileset.tile_get_material(id)
		var mat_path
		if tile_mat != null:
			mat_path = tile_mat.resource_path
		else: mat_path = null
		
		var normap_map = tileset.tile_get_normal_map(id)
		var map
		if normap_map != null:
			map = normap_map.resource_path
		else: map = null
		
		tile_data.append({
			"id":id,
			"coord":{"x":coord.x, "y":coord.y},
			"autotile":{
				"bitmask":tileset.autotile_get_bitmask(id,coord),
				"bitmask_mode":tileset.autotile_get_bitmask_mode(id),
				"fallback_mode":tileset.autotile_get_fallback_mode(id),
				"light_occluder":autotile_light_occluder,
				"nav_polygon":auto_nav_poly,
				"size":[tileset.autotile_get_size(id).x, tileset.autotile_get_size(id).y],
				"spacing":tileset.autotile_get_spacing(id),
				"subtile_priority":tileset.autotile_get_subtile_priority(id, coord),
				"z_index":tileset.autotile_get_z_index(id, coord),
			},
			"tile":{
				"light_occluder":light_occluder,
				"material":mat_path,
				"modulate":[
					tileset.tile_get_modulate(id).r,
					tileset.tile_get_modulate(id).g,
					tileset.tile_get_modulate(id).b,
					tileset.tile_get_modulate(id).a
				],
				"name":tileset.tile_get_name(id),
				"nav_polygon":tile_nav_poly,
				"nav_polygon_offs":[
					tileset.tile_get_navigation_polygon_offset(id).x,
					tileset.tile_get_navigation_polygon_offset(id).y
				],
				"normal_map":map,
				"occluder_offs":[
					tileset.tile_get_occluder_offset(id).x,
					tileset.tile_get_occluder_offset(id).y
				],
				"region":[
					tileset.tile_get_region(id).position.x,
					tileset.tile_get_region(id).position.y,
					tileset.tile_get_region(id).size.x,
					tileset.tile_get_region(id).size.y
				],
				"shapes":shapes,
				"texture":tileset.tile_get_texture(id).resource_path,
				"texture_offs":[
					tileset.tile_get_texture_offset(id).x,
					tileset.tile_get_texture_offset(id).y
				],
				"tile_mode":tileset.tile_get_tile_mode(id),
				"z_index":tileset.tile_get_z_index(id)
			}
		})
	
	var dict:Dictionary = {
		"name": tileset.resource_path.get_file(), #extract_name(tileset.resource_path, "/"),
		"atlases": atlas_arr,
		"tile_data":tile_data
	}
	
	return dict


## DEPRECATED VARS
var tilemaps:Array = []
var outputs:Array = []

## DEPRECATED
func _ready():
	get_tilemaps(get_tree().root)
	for tilemap in tilemaps:
		outputs.append(_create_dict(tilemap))
	
	for output in outputs:
		#print(output["name"])
		_write_file(
			output_path,
			output["name"],
			output
		)

## DEPRECATED
func _write_file(path:String, file_name:String, dict:Dictionary):
	var json = JSON.print(dict, "\t")
	#print(file_name)
	var file_path = path + file_name +".json"
	var file = File.new()
	var error = file.open(file_path, File.WRITE)
	if error == OK:
		file.store_string(json)
		file.close()
		#print("File saved to:", file_path)
	else:
		push_error("Could not open file for writing!")

## DEPRECATED
func get_tilemaps(node:Node):
	for _node in node.get_children():
		if _node is TileMap: tilemaps.append(_node)
		if _node.get_children().size() > 0:
			get_tilemaps(_node)

## DEPRECATED
func _create_dict(tilemap:TileMap):
	var tileset = tilemap.tile_set
	var atlas_ids = tileset.get_tiles_ids()
	var atlas_arr:Array = []
	for id in atlas_ids:
		if not atlas_arr.has(tileset.tile_get_texture(id).resource_path):
			atlas_arr.append(tileset.tile_get_texture(id).resource_path)
#	var tile_ids:Array =[]
#	var used_cells = tilemap.get_used_cells()
#	print(used_cells)
#	for cellv2 in used_cells:
#		var id = tilemap.get_cellv(cellv2)
#		print(id)
#		if not tile_ids.has(id): tile_ids.append(id)
	
	var tile_data:Array = []
	for id in tileset.get_tiles_ids():
		#this is super wrong - only returns 0,0 for single tiles
		var coord:Vector2 = tileset.tile_get_region(id).position
		
		var shapes = tileset.tile_get_shapes(id)
		for indx in shapes.size():
			if shapes[indx]["shape"] is ConvexPolygonShape2D:
				shapes[indx]["shape"] = {"Convex":shapes[indx]["shape"].points}
			if shapes[indx]["shape"] is ConcavePolygonShape2D:
				shapes[indx]["shape"] = {"Concave":shapes[indx]["shape"].points}
		
		var occluder:OccluderPolygon2D = tileset.tile_get_light_occluder(id)
		var light_occluder
		if occluder != null:
			light_occluder = {
				"closed":occluder.closed,
				"mode":occluder.cull_mode,
				"pool":occluder.polygon
			}
		else: light_occluder = null
		
		occluder = tileset.autotile_get_light_occluder(id, coord)
		var autotile_light_occluder
		if occluder != null:
			autotile_light_occluder = {
				"closed":occluder.closed,
				"mode":occluder.cull_mode,
				"pool":occluder.polygon
			}
		else: autotile_light_occluder = null
		
		var nav_poly:NavigationPolygon = tileset.autotile_get_navigation_polygon(id, coord)
		var auto_nav_poly
		if nav_poly != null:
			auto_nav_poly = []
			for indx in nav_poly.get_outline_count():
				auto_nav_poly.append(nav_poly.get_outline(indx))
		else: auto_nav_poly = null
		
		nav_poly = tileset.tile_get_navigation_polygon(id)
		var tile_nav_poly
		if nav_poly != null:
			tile_nav_poly = []
			for indx in nav_poly.get_outline_count():
				tile_nav_poly.append(nav_poly.get_outline(indx))
		else: tile_nav_poly = null
		
		var tile_mat:Material = tileset.tile_get_material(id)
		var mat_path
		if tile_mat != null:
			mat_path = tile_mat.resource_path
		else: mat_path = null
		
		var normap_map = tileset.tile_get_normal_map(id)
		var map
		if normap_map != null:
			map = normap_map.resource_path
		else: map = null
		
		tile_data.append({
			"id":id,
			"coord":{"x":coord.x, "y":coord.y},
			"autotile":{
				"bitmask":tileset.autotile_get_bitmask(id,coord),
				"bitmask_mode":tileset.autotile_get_bitmask_mode(id),
				"fallback_mode":tileset.autotile_get_fallback_mode(id),
				"light_occluder":autotile_light_occluder,
				"nav_polygon":auto_nav_poly,
				"size":[tileset.autotile_get_size(id).x, tileset.autotile_get_size(id).y],
				"spacing":tileset.autotile_get_spacing(id),
				"subtile_priority":tileset.autotile_get_subtile_priority(id, coord),
				"z_index":tileset.autotile_get_z_index(id, coord),
			},
			"tile":{
				"light_occluder":light_occluder,
				"material":mat_path,
				"modulate":[
					tileset.tile_get_modulate(id).r,
					tileset.tile_get_modulate(id).g,
					tileset.tile_get_modulate(id).b,
					tileset.tile_get_modulate(id).a
				],
				"name":tileset.tile_get_name(id),
				"nav_polygon":tile_nav_poly,
				"nav_polygon_offs":[
					tileset.tile_get_navigation_polygon_offset(id).x,
					tileset.tile_get_navigation_polygon_offset(id).y
				],
				"normal_map":map,
				"occluder_offs":[
					tileset.tile_get_occluder_offset(id).x,
					tileset.tile_get_occluder_offset(id).y
				],
				"region":[
					tileset.tile_get_region(id).position.x,
					tileset.tile_get_region(id).position.y,
					tileset.tile_get_region(id).size.x,
					tileset.tile_get_region(id).size.y
				],
				"shapes":shapes,
				"texture":tileset.tile_get_texture(id).resource_path,
				"texture_offs":[
					tileset.tile_get_texture_offset(id).x,
					tileset.tile_get_texture_offset(id).y
				],
				"tile_mode":tileset.tile_get_tile_mode(id),
				"z_index":tileset.tile_get_z_index(id)
			}
		})
	
	var dict:Dictionary = {
		"name": extract_name(tileset.resource_path, "/"),
		"atlases": atlas_arr,
		"tile_data":tile_data
	}
	
	#print(tileset.resource_name)
	return dict

## DEPRECATED
func extract_name(path:String, del:String = "\\"):
	var file_name:String = path.right(path.find_last(del))
	var just_name:String = file_name.get_slice(".", 0)
	return just_name

## DEPRECATED
func find_tilesets_in_res() -> Array:
	var results = []
	_scan_dir("res://", results)
	return results

## DEPRECATED
func _scan_dir(path: String, results: Array) -> void:
	var dir = Directory.new()
	if dir.open(path) != OK:
		push_warning("Could not open directory: " + path)
		return

	dir.list_dir_begin(true, true)  # Skip hidden files and return relative paths
	var file_name = dir.get_next()

	while file_name != "":
		var full_path = path.plus_file(file_name)

		if dir.current_is_dir():
			_scan_dir(full_path, results)
		else:
			if file_name.ends_with(".tres") or file_name.ends_with(".res") or file_name.ends_with(".tileset"):
				var res = ResourceLoader.load(full_path)
				if res and res is TileSet:
					results.append({
						"path": full_path,
						"resource": res
					})
		file_name = dir.get_next()

	dir.list_dir_end()
