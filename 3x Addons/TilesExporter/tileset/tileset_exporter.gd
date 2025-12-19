extends Reference
#----------------------------------------------------#
# TileSet Exporter                                   #
# This script stores all code related to the         #
# processessing and exporting of individual tilesets #
#----------------------------------------------------#

func better_process(tileset:TileSet) -> Dictionary:
	
	var out:Dictionary = {
		"name": tileset.resource_path.get_file(),
		"resource_path": tileset.resource_path,
		"atlases":[],
		"tile_data":{}
	}
	print("<<< TileSet Obj >>>\n\t", out)
	var tile_ids:Array = tileset.get_tiles_ids()
	print("\ttile_ids: ", tile_ids)
	for id in tile_ids:
		print("better_process:")
		print("\tid: ", id)
		#gather source paths
		var atlas_path = tileset.tile_get_texture(id).resource_path
		if not out["atlases"].has(atlas_path):
			out["atlases"].append(atlas_path)

		var coord = tileset.tile_get_region(id).position
		var mode = tileset.tile_get_tile_mode(id)
		var obj = {
			"id":id,
			"coord":{"x":coord.x, "y":coord.y},
			"tilemode":mode,
		}
		print("\tobj: ", obj)
		out["tile_data"][id] = obj
		# process depending on mode
		if mode == TileSet.AUTO_TILE:
			out["tile_data"][id].merge(build_autotile_data(tileset, id))
		elif mode == TileSet.SINGLE_TILE:
			out["tile_data"][id].merge(build_single_tile_data(tileset, id))
		elif mode == TileSet.ATLAS_TILE:
			out["tile_data"][id].merge(build_atlas_data(tileset, id))
	return out

func build_single_tile_data(tileset:TileSet, id:int) -> Dictionary:
	print("build_single_tile_data")
	print("\ttile id: ", id)
	var out:Dictionary = {"single_tile":{}}
	#safety check
	var test_coord = tileset.tile_get_region(id).position
	var test_img = tileset.tile_get_texture(id).get_size()
	if test_coord.x > test_img.x or test_coord.y > test_img.y: 
		printerr("tile id ",id , " is outside image bounds. Skipping tile export")
		return out
	
	out["single_tile"] = {
		"name":tileset.tile_get_name(id),
		"collision_shapes":null,
		"material_path":null,
		"modulate":null,
		"light_occluder":null,
		"light_occluder_offs": _v2arr(tileset.tile_get_occluder_offset(id)),
		"nav_polygon":null,
		"nav_polygon_offs":_v2arr(tileset.tile_get_navigation_polygon_offset(id)),
		"region": _rect2arr(tileset.tile_get_region(id)),
		"region_size":_v2arr(tileset.tile_get_region(id).size),
		"region_position":_v2arr(tileset.tile_get_region(id).position),
		"normal_map_path":null,
		"texture_path":null,
		"texture_offs": _v2arr(tileset.tile_get_texture_offset(id)),
		"z_index":tileset.tile_get_z_index(id),
	}	
	var collision_shapes = tileset.tile_get_shapes(id)
	if collision_shapes != null:
		out["single_tile"]["collision_shapes"] = _format_shapes(collision_shapes)
	var occluder = tileset.tile_get_light_occluder(id)
	if occluder != null:
		out["single_tile"]["light_occluder"] = [_format_occluder(occluder)]
	var nav_poly = tileset.tile_get_navigation_polygon(id)
	if nav_poly != null:
		out["single_tile"]["nav_polygon"] = [_format_nav_poly(nav_poly)]
	var mat = tileset.tile_get_material(id)
	if mat != null:
		out["single_tile"]["material_path"] = mat.resource_path
	out["single_tile"]["modulate"] = _colorarr(tileset.tile_get_modulate(id))
	var tex = tileset.tile_get_texture(id)
	if tex != null:
		out["single_tile"]["texture_path"] = tex.resource_path
	var normal_path = tileset.tile_get_normal_map(id)
	if normal_path != null:
		out["single_tile"]["normal_map_path"] = normal_path.resource_path
	
	#print(out)
	return out

func build_autotile_data(tileset:TileSet, id:int) -> Dictionary:
	print("build_autotile_data")
	var out:Dictionary = {"autotile":{}}
	var bitmask_data:Array = []
	var coord = tileset.tile_get_region(id).position
	var tile_size:Vector2 = tileset.tile_get_region(id).size
	var subtile_size:Vector2 = tileset.autotile_get_size(id)
	var subtile_count:Vector2 = tile_size/subtile_size
	#print(tileset.resource_path, " -> subtile_count: ", subtile_count)
	out["autotile"] = {
		"name":tileset.tile_get_name(id),
		"bitmask":{},
		"bitmask_mode":tileset.autotile_get_bitmask_mode(id),
		"collision_shapes":null,
		"fallback_mode":tileset.autotile_get_fallback_mode(id),
		"material_path":null,
		"modulate":_colorarr(tileset.tile_get_modulate(id)),
		"light_occluder":null,
		"light_occluder_offs": _v2arr(tileset.tile_get_occluder_offset(id)),
		"nav_polygon":null,
		"nav_polygon_offs":_v2arr(tileset.tile_get_navigation_polygon_offset(id)),
		"region": _rect2arr(tileset.tile_get_region(id)),
		"region_size":_v2arr(tile_size),
		"region_position":_v2arr(tileset.tile_get_region(id).position),
		"subtile_size":_v2arr(subtile_size),
		"subtile_count":_v2arr(subtile_count),
		"subtile_priority":tileset.autotile_get_subtile_priority(id, coord),
		"spacing":tileset.autotile_get_spacing(id),
		"normal_map_path":null,
		"texture_path":null,
		"texture_offs": _v2arr(tileset.tile_get_texture_offset(id)),
		"z_index":tileset.autotile_get_z_index(id, coord),
	}
	var subtile_coord
	var occluders:Array = []
	var nav_polys:Array = []
	for x in subtile_count.x:
		for y in subtile_count.y:
			subtile_coord = Vector2(x,y) #* subtile_size
			#print("subtile_coord: ", subtile_coord)
			# Safety check
			var real_coord = subtile_coord*subtile_size
			var img_size = tileset.tile_get_texture(id).get_size()
			if real_coord.x > img_size.x or real_coord.y > img_size.y:
				printerr("tile id ",id , " is outside image bounds. Skipping tile export")
				continue
			
			var bitmask = tileset.autotile_get_bitmask(id, subtile_coord)
			out["autotile"]["bitmask"][_v2arr(subtile_coord)] = bitmask_converter(bitmask)
			var occluder = tileset.autotile_get_light_occluder(id, subtile_coord)
			if occluder != null: occluders.append(_format_occluder(occluder))
			var nav_poly = tileset.autotile_get_navigation_polygon(id, subtile_coord)
			if nav_poly != null: nav_polys.append(_format_nav_poly(nav_poly))
	
	var collision_shapes = tileset.tile_get_shapes(id)
	if collision_shapes != null:
		out["autotile"]["collision_shapes"] = _format_shapes(collision_shapes)
	if occluders != null or not occluders.empty():
		out["autotile"]["light_occluder"] = occluders
	if nav_polys != null or not nav_polys.empty():
		out["autotile"]["nav_polygon"] = nav_polys
	
	var mat = tileset.tile_get_material(id)
	if mat != null: out["autotile"]["material_path"] = mat.resource_path
	var tex = tileset.tile_get_texture(id)
	if tex != null: out["autotile"]["texture_path"] = tex.resource_path
	var normal_path = tileset.tile_get_normal_map(id)
	if normal_path != null: out["autotile"]["normal_map_path"] = normal_path.resource_path
	
	return out

func build_atlas_data(tileset:TileSet, id:int) -> Dictionary:
	print("build_atlas_data")
	var out:Dictionary = {"atlas_tile":{}}
	var coord = tileset.tile_get_region(id).position
	var tile_size:Vector2 = tileset.tile_get_region(id).size
	var subtile_size:Vector2 = tileset.autotile_get_size(id)
	var subtile_count:Vector2 = tile_size/subtile_size
	out["atlas_tile"] = {
		"name":tileset.tile_get_name(id),
		"collision_shapes":null,
		"fallback_mode":tileset.autotile_get_fallback_mode(id),
		"material_path":null,
		"modulate":_colorarr(tileset.tile_get_modulate(id)),
		"light_occluder":null,
		"light_occluder_offs": _v2arr(tileset.tile_get_occluder_offset(id)),
		"nav_polygon":null,
		"nav_polygon_offs":_v2arr(tileset.tile_get_navigation_polygon_offset(id)),
		"region": _rect2arr(tileset.tile_get_region(id)),
		"region_size":_v2arr(tile_size),
		"region_position":_v2arr(tileset.tile_get_region(id).position),
		"subtile_size":_v2arr(subtile_size),
		"subtile_count":_v2arr(subtile_count),
		"subtile_priority":tileset.autotile_get_subtile_priority(id, coord),
		"spacing":tileset.autotile_get_spacing(id),
		"normal_map_path":null,
		"texture_path":null,
		"texture_offs": _v2arr(tileset.tile_get_texture_offset(id)),
		"z_index":tileset.autotile_get_z_index(id, coord),
	}
	var subtile_coord:Vector2
	var occluders:Array = []
	var nav_polys:Array = []
	for x in subtile_count.x-1:
		for y in subtile_count.y-1:
			subtile_coord = Vector2(x,y)*subtile_size
			# Safety check
			var real_coord = subtile_coord*subtile_size
			var img_size = tileset.tile_get_texture(id).get_size()
			if real_coord.x > img_size.x or real_coord.y > img_size.y:
				printerr("tile id ",id , " is outside image bounds. Skipping tile export")
				continue
			
			var occluder = tileset.autotile_get_light_occluder(id, subtile_coord)
			if occluder != null: occluders.append(_format_occluder(occluder))
			var nav_poly = tileset.autotile_get_navigation_polygon(id, subtile_coord)
			if nav_poly != null: nav_polys.append(_format_nav_poly(nav_poly))
			
	
	var collision_shapes = tileset.tile_get_shapes(id)
	if collision_shapes != null:
		out["atlas_tile"]["collision_shapes"] = _format_shapes(collision_shapes)
	if occluders != null or not occluders.empty():
		out["atlas_tile"]["light_occluder"] = occluders
	if nav_polys != null or not nav_polys.empty():
		out["atlas_tile"]["nav_polygon"] = nav_polys
	
	var mat = tileset.tile_get_material(id)
	if mat != null: out["atlas_tile"]["material_path"] = mat.resource_path
	var tex = tileset.tile_get_texture(id)
	if tex != null: out["atlas_tile"]["texture_path"] = tex.resource_path
	var normal_path = tileset.tile_get_normal_map(id)
	if normal_path != null: out["atlas_tile"]["normal_map_path"] = normal_path.resource_path
	
	return out

# Processes the tilesed and exports its data to path (does not append json ext)
func export_tileset(path:String, tileset:TileSet) -> void:
	var data := better_process(tileset)
	var json = JSON.print(data, "\t")
	var file = File.new()
	var error = file.open(path, File.WRITE)
	
	if error == OK:
		file.store_string(json)
		file.close()
	else:
		push_error("Could not open file for writing!")

func _format_nav_poly(poly:NavigationPolygon) -> Array:
	#print("nav_poly: ", poly)
	if poly == null: return []
	var outlines = []
	for indx in poly.get_outline_count():
		outlines.append(_packedv2toarr(poly.get_outline(indx)))
	return outlines

func _format_occluder(occluder:OccluderPolygon2D) -> Dictionary:
	if occluder == null: return {}
	return {
		"closed":occluder.closed,
		"mode":occluder.cull_mode,
		"pool":_packedv2toarr(occluder.polygon)
	}
	

func _format_shapes(shapes, debug="") -> Array:
	#print("format_shapes")
	#print(debug)
	#print("shapes ", shapes)
	var out:Array = []
	if shapes == null or shapes.empty() or shapes.size() == 0:
		#print("no elements in shapes array")
		return []
	for shape in shapes:
		#print(shape)
		var poly = shape["shape"]
		var polypool:PoolVector2Array
		if poly is ConvexPolygonShape2D:
			poly = poly as ConvexPolygonShape2D
			polypool = poly.points
		elif poly is ConcavePolygonShape2D:
			poly = poly as ConcavePolygonShape2D
			polypool = poly.segments
		var transform = shape["shape_transform"]
		var one_way = shape["one_way"]
		var one_way_margin = shape["one_way_margin"]
		var autotile_coord = shape["autotile_coord"]
		out.append({
			"shape": _packedv2toarr(polypool),
			"shape_transform":_transformarr(transform),
			"one_way": one_way,
			"one_way_margin": one_way_margin,
			"autotile_coord": _v2arr(autotile_coord)
		})
	return out

func _rect2arr(r:Rect2) -> Array:
	return [r.position.x, r.position.y, r.size.x, r.size.y]

func _colorarr(c:Color) -> Array:
	return [c.r, c.g, c.b, c.a]

func _v2arr(v2:Vector2, debug="") -> Array:
	#print("v2arr")
	#print(debug)
	return [v2.x, v2.y]

func _packedv2toarr(poly, debug="") -> Array:
	#print("packedv2toarr")
	#print(debug)
	if poly == null or poly.size() == 0 or poly.empty():
		#print("no elements in PoolVector2Array")
		return []
	var out:Array = []
	for vec in poly:
		out.append(_v2arr(vec))
	return out
	
func _transformarr(trans:Transform2D, debug="") -> Array:
	#print("transfromarr")
	#print(debug)
	return [
		_v2arr(trans.x),
		_v2arr(trans.y),
		_v2arr(trans.origin)
	]

const bitmask_ref = {
	1:"TopLeft",
	2:"Top",
	4:"TopRight",
	8:"Left",
	16:"Center",
	32:"Right",
	64:"BottomLeft",
	128:"Bottom",
	256:"BottomRight"
}

func bitmask_converter(bitmask:int)	-> Array:
	var out := []
	for bit_val in bitmask_ref:
		if bitmask & bit_val != 0:
			out.append(bitmask_ref[bit_val])
	return out


#func process_tileset(tileset:TileSet) -> Dictionary:
#	# <Atlas Block>
#	# this block identifies the different texture atlases contained
#	# inside of a tileset
#	var atlas_ids = tileset.get_tiles_ids()
#	var atlas_arr:Array = []
#	for id in atlas_ids:
#		if not atlas_arr.has(tileset.tile_get_texture(id).resource_path):
#			atlas_arr.append(tileset.tile_get_texture(id).resource_path)
#	#print("Atlas Array -> ", atlas_arr)
#	# </Atlas Block>
#
#	# <Main Loop>
#	# this loop looks through the tiles in a TileSet and collects its
#	# data into a dictionary for output to a JSON file
#	var tile_data:Array = []
#	for id in tileset.get_tiles_ids():
#		var mode = tileset.tile_get_tile_mode(id)
#		if mode == TileSet.AUTO_TILE:
#			print()
#		elif mode == TileSet.SINGLE_TILE:
#			print()
#		elif mode == TileSet.ATLAS_TILE:
#			print()
#
#		#print("tile id: ", id)
#		# identify the atlas coord (in pixels) for use in the import process
#		var coord:Vector2 = tileset.tile_get_region(id).position
#		#print("tile coord(px): ", coord)
#
#		# gather the collision shape data
#		# gd3 just calls this "shapes" and not "collision_shapes"
#		var shapes = tileset.tile_get_shapes(id)
#		for indx in shapes.size():
#			if shapes[indx]["shape"] is ConvexPolygonShape2D:
#				shapes[indx]["shape"] = {"Convex":shapes[indx]["shape"].points}
#			if shapes[indx]["shape"] is ConcavePolygonShape2D:
#				shapes[indx]["shape"] = {"Concave":shapes[indx]["shape"].points}
#		#print("collision shapes: ", shapes)
#
#		# gather occluder data for single tiles
#		var occluder:OccluderPolygon2D = tileset.tile_get_light_occluder(id)
#		var light_occluder
#		if occluder != null:
#			light_occluder = {
#				"closed":occluder.closed,
#				"mode":occluder.cull_mode,
#				"pool":occluder.polygon
#			}
#		else: light_occluder = null
#		#print("single tile light occluder: ", light_occluder)
#
#		# gather occluder data for atlases and autotiles
#		occluder = tileset.autotile_get_light_occluder(id, coord)
#		var autotile_light_occluder
#		if occluder != null:
#			autotile_light_occluder = {
#				"closed":occluder.closed,
#				"mode":occluder.cull_mode,
#				"pool":occluder.polygon
#			}
#		else: autotile_light_occluder = null
#		#print("autotile light occluder: ", autotile_light_occluder)
#
#		# gather nav data for atlases and auto tiles
#		var nav_poly:NavigationPolygon = tileset.autotile_get_navigation_polygon(id, coord)
#		var auto_nav_poly
#		if nav_poly != null:
#			auto_nav_poly = []
#			for indx in nav_poly.get_outline_count():
#				auto_nav_poly.append(nav_poly.get_outline(indx))
#		else: auto_nav_poly = null
#		#print("autotile nav polys: ", auto_nav_poly)
#
#		# gather nav data for single tiles
#		nav_poly = tileset.tile_get_navigation_polygon(id)
#		var tile_nav_poly
#		if nav_poly != null:
#			tile_nav_poly = []
#			for indx in nav_poly.get_outline_count():
#				tile_nav_poly.append(nav_poly.get_outline(indx))
#		else: tile_nav_poly = null
#		#print("single tile nav polys: ", tile_nav_poly)
#
#		# gather material data 
#		var tile_mat:Material = tileset.tile_get_material(id)
#		var mat_path
#		if tile_mat != null:
#			mat_path = tile_mat.resource_path
#		else: mat_path = null
#		#print("tile material path: ", mat_path)
#
#		# gather normal map data
#		var normap_map = tileset.tile_get_normal_map(id)
#		var map
#		if normap_map != null:
#			map = normap_map.resource_path
#		else: map = null
#		#print("tile normal map: ", map)
#
#		# <TileSet Data Construction>
#		# constructs a dictionary containing the data we have gathered about the current tile
#		# and appends it to the tile_data array
#		tile_data.append({
#			"id":id,
#			"coord":{"x":coord.x, "y":coord.y},
#			"tilemode": tileset.tile_get_tile_mode(id),
#			"autotile":{
#				"bitmask":tileset.autotile_get_bitmask(id,coord),
#				"bitmask_mode":tileset.autotile_get_bitmask_mode(id),
#				"fallback_mode":tileset.autotile_get_fallback_mode(id),
#				"light_occluder":autotile_light_occluder,
#				"nav_polygon":auto_nav_poly,
#				"size":[tileset.autotile_get_size(id).x, tileset.autotile_get_size(id).y],
#				"spacing":tileset.autotile_get_spacing(id),
#				"subtile_priority":tileset.autotile_get_subtile_priority(id, coord),
#				"z_index":tileset.autotile_get_z_index(id, coord),
#			},
#			"tile":{
#				"light_occluder":light_occluder,
#				"material":mat_path,
#				"modulate":[
#					tileset.tile_get_modulate(id).r,
#					tileset.tile_get_modulate(id).g,
#					tileset.tile_get_modulate(id).b,
#					tileset.tile_get_modulate(id).a
#				],
#				"name":tileset.tile_get_name(id),
#				"nav_polygon":tile_nav_poly,
#				"nav_polygon_offs":[
#					tileset.tile_get_navigation_polygon_offset(id).x,
#					tileset.tile_get_navigation_polygon_offset(id).y
#				],
#				"normal_map":map,
#				"occluder_offs":[
#					tileset.tile_get_occluder_offset(id).x,
#					tileset.tile_get_occluder_offset(id).y
#				],
#				"region":[
#					tileset.tile_get_region(id).position.x,
#					tileset.tile_get_region(id).position.y,
#					tileset.tile_get_region(id).size.x,
#					tileset.tile_get_region(id).size.y
#				],
#				"shapes":shapes,
#				"texture":tileset.tile_get_texture(id).resource_path,
#				"texture_offs":[
#					tileset.tile_get_texture_offset(id).x,
#					tileset.tile_get_texture_offset(id).y
#				],
#				"tile_mode":tileset.tile_get_tile_mode(id),
#				"z_index":tileset.tile_get_z_index(id)
#			}
#		})
#		# </TileSet Data Construction>
#	# </Main Block>
#
#	# <Final Output Construction>
#	var dict:Dictionary = {
#		"name": tileset.resource_path.get_file(),
#		"resource_path": tileset.resource_path,
#		"atlases": atlas_arr,
#		"tile_data":tile_data
#	}
#	#print("Final TileSet Output Dictionary: ", dict)
#	# </Final Output Construction>
#	return dict


