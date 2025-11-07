extends Node
class_name TileSetExporter

export var output_path:String

var tilemaps:Array = []
var outputs:Array = []

func _ready():
	get_tilemaps(get_tree().root)
	for tilemap in tilemaps:
		outputs.append(_create_dict(tilemap))
	
	for output in outputs:
		print(output["name"])
		_write_file(
			output_path,
			output["name"],
			output
		)

func _write_file(path:String, file_name:String, dict:Dictionary):
	var json = JSON.print(dict, "\t")
	print(file_name)
	var file_path = path + file_name +".json"
	var file = File.new()
	var error = file.open(file_path, File.WRITE)
	if error == OK:
		file.store_string(json)
		file.close()
		print("File saved to:", file_path)
	else:
		push_error("Could not open file for writing!")

func get_tilemaps(node:Node):
	for _node in node.get_children():
		if _node is TileMap: tilemaps.append(_node)
		if _node.get_children().size() > 0:
			get_tilemaps(_node)

func _create_dict(tilemap:TileMap):
	var tileset = tilemap.tile_set
#	var atlas_ids = tileset.get_tiles_ids()
#	var atlas_arr:Array = []
#	for id in atlas_ids:
#		atlas_arr.append({
#			"id": id,
#			"path": tileset.tile_get_texture(id).resource_path
#		})
#	var tile_ids:Array =[]
#	var used_cells = tilemap.get_used_cells()
#	print(used_cells)
#	for cellv2 in used_cells:
#		var id = tilemap.get_cellv(cellv2)
#		print(id)
#		if not tile_ids.has(id): tile_ids.append(id)
	
	var tile_data:Array = []
	for id in tileset.get_tiles_ids():
		var coord:Vector2 = tileset.autotile_get_icon_coordinate(id)
		
		tile_data.append({
			"id":id,
			"coord":{"x":coord.x, "y":coord.y},
			"autotile":{
				"bitmask":tileset.autotile_get_bitmask(id,coord),
				"bitmask_mode":tileset.autotile_get_bitmask_mode(id),
				"fallback_mode":tileset.autotile_get_fallback_mode(id),
				"light_occluder":tileset.autotile_get_light_occluder(id, coord),
				"nav_polygon":tileset.autotile_get_navigation_polygon(id, coord),
				"size":[tileset.autotile_get_size(id).x, tileset.autotile_get_size(id).y],
				"spacing":tileset.autotile_get_spacing(id),
				"subtile_priority":tileset.autotile_get_subtile_priority(id, coord),
				"z_index":tileset.autotile_get_z_index(id, coord),
			},
			"tile":{
				"light_occluder":tileset.tile_get_light_occluder(id),
				"material":tileset.tile_get_material(id),
				"modulate":[
					tileset.tile_get_modulate(id).r,
					tileset.tile_get_modulate(id).g,
					tileset.tile_get_modulate(id).b,
					tileset.tile_get_modulate(id).a
				],
				"name":tileset.tile_get_name(id),
				"nav_polygon":tileset.tile_get_navigation_polygon(id),
				"nav_polygon_offs":[
					tileset.tile_get_navigation_polygon_offset(id).x,
					tileset.tile_get_navigation_polygon_offset(id).y
				],
				"normal_map":tileset.tile_get_normal_map(id),
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
				"shapes":tileset.tile_get_shapes(id),
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
		#"atlases": atlas_arr,
		"tile_data":tile_data
	}
	
	print(tileset.resource_name)
	return dict
	

func extract_name(path:String, del:String = "\\"):
	var file_name:String = path.right(path.find_last(del))
	var just_name:String = file_name.get_slice(".", 0)
	return just_name

func find_tilesets_in_res() -> Array:
	var results = []
	_scan_dir("res://", results)
	return results


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
