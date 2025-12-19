@tool
extends RefCounted

class MyTileSetData:
	var name:String
	var res_path:String
	var atlases
	var tile_data
	func _init() -> void:
		pass
	static func from(data:Dictionary) -> MyTileSetData:
		print_rich("[color=red][[[ TileSetData.from ]]][/color]")
		var out:MyTileSetData = MyTileSetData.new()
		out.name = data["name"]
		print_rich("[b]", out.name,"[/b]")
		out.res_path = data["resource_path"]
		#print(data["name"], " -> atlas_debug: ", data["atlases"])
		var atlases = data["atlases"]
		#atlases = atlases as Array[String] 
		out.atlases = atlases
		out.tile_data = []
		for id in data["tile_data"].keys():
			#print("\ttile_data.id == ", tile_data["id"])
			#tile_data = tile_data as Array[MyTileData]
			#print_rich("[color=black]<out.tile_data.append(TileData)>[/color]")
			out.tile_data.append(MyTileData.from(int(id), data["tile_data"][id]))
			#print_rich("[color=black]</out.tile_data.append(TileData)>[/color]")
			#print_rich("[color=black]\tout.tile_data.size() == ", out.tile_data.size(), "[/color]")
		return out

class MyTileData:
	var id:int
	var coord:Vector2i
	var tile_mode:TileMode
	var tile_config:TileConfig
	func _init() -> void:
		pass
	static func from(id:int, data:Dictionary) -> MyTileData:
		print_rich("[color=orange][[[ TileData.from ]]][/color]")
		var out = MyTileData.new()
		out.id = id
		print("\tout.id == ", out.id)
		out.coord = Vector2i(data["coord"]["x"], data["coord"]["y"])
		#print("\tout.coord == ", out.coord)
		#print("MyTileData -> match data[tilemode]")
		#print(" match data[tilemode] == ", data["tilemode"], " Type: ", typeof(data["tilemode"]))
		if data["tilemode"] == 0:
			#print("\t0: Single")
			out.tile_mode = TileMode.Single
			#print("\tout.tile_mode == Single")
			#print("\tout.tile_mode == ", out.tile_mode)
			out.tile_config = TileConfig.from(data["single_tile"], out.tile_mode)
			#print("\tout.tile_mode == ", out.tile_config)
		if data["tilemode"] == 1: 
			#print("\t1: Auto")
			out.tile_mode = TileMode.Auto
			#print("\tout.tile_mode == Auto")
			#print("\tout.tile_mode == ", out.tile_mode)
			out.tile_config = TileConfig.from(data["autotile"], out.tile_mode)
			#print("\tout.tile_mode == ", out.tile_config)
		if data["tilemode"] == 2: 
			#print("\t2: Atlas")
			out.tile_mode = TileMode.Atlas
			#print("\tout.tile_mode == Atlas")
			#print("\tout.tile_mode == ", out.tile_mode)
			out.tile_config = TileConfig.from(data["atlas_tile"], out.tile_mode)
			#print("\tout.tile_mode == ", out.tile_config)
		return out

class TileConfig:
	var name:String
	var collision_shapes:Array[CollisionShape]
	var material_path:String
	var modulate:Color
	var light_occluder:Array[LightOccluder]
	var light_occluder_offs:Vector2i
	var nav_poly:Array[NavigationPolygon]
	var nav_poly_offs:Vector2i
	var region:Rect2i
	var region_size:Vector2i
	var region_position:Vector2i
	var normal_map_path:String
	var texture_path:String
	var texture_offs:Vector2i
	var z_index:int
	#Atlas Tile
	var fallback_mode:int
	var subtile_size:Vector2i
	var subtile_count:Vector2i
	var subtile_priority:int
	var spacing:int
	# Auto Tile
	var bitmask#:Dictionary[Array, int]
	var bitmask_mode:int
	
	func _init() -> void:
		pass
	static func from(data, tile_mode:TileMode) -> TileConfig:
		print_rich("[color=yellow][[[ TileConfig.from ]]][/color]")
		var out = TileConfig.new()
		#print("TileConfig.from() -> out == ", out)
		out.name = data["name"]
		if data["material_path"] != null:
			out.material_path = data["material_path"]
		out.modulate = Util._color_from_arr(data["modulate"])
		out.light_occluder_offs = Util._v2_from_arr(data["light_occluder_offs"])
		
			
		out.nav_poly_offs = Util._v2_from_arr(data["nav_polygon_offs"])
		out.region = Util._rec2i_from_arr(data["region"])
		out.region_size = Util._v2_from_arr(data["region_size"])
		out.region_position = Util._v2_from_arr(data["region_position"])
		if data["normal_map_path"] != null:
			out.normal_map_path = data["normal_map_path"]
		out.texture_path = data["texture_path"]
		out.texture_offs = Util._v2_from_arr(data["texture_offs"])
		out.z_index = data["z_index"]
		print("\tout.collision_shapes == ", out.collision_shapes)
		print("\tout.light_occluder == ", out.light_occluder)
		print("\tout.nav_poly == ", out.nav_poly)
		#print("\tout.name == ", out.name)
		#print("\tout.material_path == ", out.material_path)
		#print("\tout.region == ", out.region)
		#print("\tout.region_size == ", out.region_size)
		#print("\tout.region_position == ", out.region_position)
		#print("\tout.texture_path == ", out.texture_path)
		#print("\tout.texture_offs == ", out.texture_offs)
		#print("\tout.z_index == ", out.z_index)
		#print("\tout.collision_shapes == ", out.collision_shapes)
		
		if tile_mode == TileMode.Single:
			for shape in data["collision_shapes"]:
				out.collision_shapes.append(CollisionShape.from(shape, out.region_size))
			if data["nav_polygon"] != null:
				print_rich("[color=green]Navigation Polygon[/color]")
				out.nav_poly = Util._nav_from_data(data["nav_polygon"], out.region_size)
				print("\tout.nav_poly == ", out.nav_poly)
			if data["light_occluder"] != null:
				for occluder in data["light_occluder"]:
					out.light_occluder.append(LightOccluder.from(occluder, out.region_size))
		
		if tile_mode == TileMode.Atlas or tile_mode == TileMode.Auto:
			#print_rich("[color=green]tile_mode == Atlas[/color]")
			out.fallback_mode = data["fallback_mode"]
			out.subtile_size = Util._v2_from_arr(data["subtile_size"])
			out.subtile_count = Util._v2_from_arr(data["subtile_count"])
			out.subtile_priority = data["subtile_priority"]
			out.spacing = data["spacing"]
			
			for shape in data["collision_shapes"]:
				out.collision_shapes.append(CollisionShape.from(shape, out.subtile_size))
			if data["nav_polygon"] != null:
				print_rich("[color=green]Navigation Polygon[/color]")
				out.nav_poly = Util._nav_from_data(data["nav_polygon"], out.subtile_size)
				print("\tout.nav_poly == ", out.nav_poly)
			if data["light_occluder"] != null:
				for occluder in data["light_occluder"]:
					out.light_occluder.append(LightOccluder.from(occluder, out.subtile_size))
			#print("\tout.fallback_mode == ", out.fallback_mode)
			#print("\tout.subtile_size == ", out.subtile_size)
			#print("\tout.subtile_count == ", out.subtile_count)
			#print("\tout.subtile_priority == ", out.subtile_priority)
			#print("\tout.spacing == ", out.spacing)
			
			
		if tile_mode == TileMode.Auto:
			#print_rich("[color=green]tile_mode == Auto[/color]")
			out.bitmask = data["bitmask"]
			out.bitmask_mode = data["bitmask_mode"]
			out.fallback_mode = data["fallback_mode"]
			out.subtile_size = Util._v2_from_arr(data["subtile_size"])
			out.subtile_count = Util._v2_from_arr(data["subtile_count"])
			out.subtile_priority = data["subtile_priority"]
			out.spacing = data["spacing"]
			
			for shape in data["collision_shapes"]:
				out.collision_shapes.append(CollisionShape.from(shape, out.subtile_size))
			if data["nav_polygon"] != null:
				print_rich("[color=green]Navigation Polygon[/color]")
				out.nav_poly = Util._nav_from_data(data["nav_polygon"], out.subtile_size)
				print("\tout.nav_poly == ", out.nav_poly)
			if data["light_occluder"] != null:
				for occluder in data["light_occluder"]:
					out.light_occluder.append(LightOccluder.from(occluder, out.subtile_size))
			#print("\tout.bitmask == ", out.bitmask)
			#print("\tout.bitmask_mode == ", out.bitmask_mode)
			#print("\tout.fallback_mode == ", out.fallback_mode)
			#print("\tout.subtile_size == ", out.subtile_size)
			#print("\tout.subtile_count == ", out.subtile_count)
			#print("\tout.subtile_priority == ", out.subtile_priority)
			#print("\tout.spacing == ", out.spacing)
		return out
		

class LightOccluder:
	var closed:bool
	var mode:int
	var pool:PackedVector2Array
	func _init() -> void:
		pass
	static func from(data, tile_size:Vector2i) -> LightOccluder:
		print_rich("[color=green]LightOccluder.from()[/color]")
		var out := LightOccluder.new()
		out.closed = data["closed"]
		out.mode = data["mode"]
		#out.pool = Util._packed_v2_from_arr(data["pool"])
		for point in Util._packed_v2_from_arr(data["pool"]):
			out.pool.append(point - ((tile_size/2) as Vector2))
		print("\tout.pool == ", out.pool)
		return out
	func to() -> OccluderPolygon2D:
		print_rich("[color=cyan]LightOccluder.to()[/color]")
		var out := OccluderPolygon2D.new()
		out.closed = self.closed
		out.cull_mode = self.mode
		out.polygon = self.pool
		print("\tout.polygon == ", out.polygon)
		return out
	
class CollisionShape:
	var autotile_coord:Vector2
	var one_way:bool
	var one_way_margin:int
	var shape:PackedVector2Array
	func _init() -> void:
		pass
	static func from(data, tile_size:Vector2i) -> CollisionShape:
		print_rich("[color=green]CollisionShape.from()[/color]")
		var out := CollisionShape.new()
		out.autotile_coord = Util._v2_from_arr(data["autotile_coord"])
		out.one_way = data["one_way"]
		out.one_way_margin = data["one_way_margin"]
		var tmp_shape = Util._packed_v2_from_arr(data["shape"])
		for point in tmp_shape:
			out.shape.append(point - ((tile_size/2) as Vector2))
		print("\tout.autotile_coord == ", out.autotile_coord)
		print("\tout.shape == ", out.shape)
		return out

class Util:
	static func _rec2i_from_arr(arr) -> Rect2i:
		##print("_rect2i_from_arr( ",arr," )")
		return Rect2i(arr[0], arr[1], arr[2], arr[3])
	static func _v2_from_arr(arr) -> Vector2i:
		##print("_v2_from_arr( ",arr," )")
		return Vector2i(int(arr[0]), int(arr[1]))
	static func _packed_v2_from_arr(arr) -> PackedVector2Array:
		##print("_packed_v2_from_arr( ",arr," )")
		var tmp:Array[Vector2i]
		for a in arr: tmp.append(_v2_from_arr(a))
		return PackedVector2Array(tmp)
	static func _color_from_arr(arr) -> Color:
		##print("_color_from_arr( ", arr, " )")
		return Color(arr[0], arr[1], arr[2], arr[3])
	static func _nav_from_data(data, tile_size:Vector2i) -> Array[NavigationPolygon]:
		print_rich("[color=cyan]nav from data util[/color]")
		var out:Array[NavigationPolygon]
		for shrug in data:
			for nav in shrug:
				print("\tnav == ", nav)
				var tmp_v2arr = Util._packed_v2_from_arr(nav)
				var v2arr:Array[Vector2]
				for point in tmp_v2arr:
					v2arr.append(point - ((tile_size/2) as Vector2))
				var real_nav := NavigationPolygon.new()
				real_nav.add_outline(v2arr)
				print("real_nav == ", real_nav)
				out.append(real_nav)
		return out

func create_tileset_from_classes(data:Dictionary) -> TileSet:
	var tileset_data = MyTileSetData.from(data)
	
	#print_rich("[color=orange]\n----- PROCESSING TILESET -----[/color]")
	#print("\tres_path -> ",tileset_data.res_path)
	#print("\tsources -> ", tileset_data.atlases)
	#print("\ttile_data count -> ", tileset_data.tile_data.size())
	var out := TileSet.new()
	var sources:Dictionary[String, TileSetAtlasSource]
	out.add_navigation_layer(0)
	out.add_occlusion_layer(0)
	out.add_physics_layer(0)
	out.add_terrain_set(0)
	out.add_terrain(0,0)

	for atlas_path in tileset_data.atlases:
		var source := TileSetAtlasSource.new()
		source.texture = load(atlas_path)
		sources[atlas_path] = source
		out.add_source(source)
	#print("Sources Dict: ", sources)
	#print("Out.Sources: ", out.get_source_count())
	
	#print("\ttileset_data.tile_data.size() == ", tileset_data.tile_data.size())
	for tile_data in tileset_data.tile_data:
		var tile_config:TileConfig = tile_data.tile_config
		var texture_path := tile_config.texture_path
		var source = sources[texture_path]
		if tile_data.coord.x > source.texture.get_size().x \
		or tile_data.coord.y > source.texture.get_size().y:
			continue
		#print_rich("[color=cyan]Processed tile_data...[/color]")
		#print("\ttile_config: ", tile_config)
		#print("\ttexture_path: ", texture_path)
		#print("\tsource: ", source)
		#print("\tcoords: ", tile_data.coord)
		
		if tile_data.tile_mode == TileMode.Single:
			#print_rich("[color=yellow]\n--- Creating Single Tile ---[/color]")
			source.texture_region_size = tile_config.region_size
			out.tile_size = tile_config.region_size
			var atlas_coord = tile_data.coord / tile_config.region_size
			source.create_tile(atlas_coord)
			#print("\tcreated tile at atlas coord: ", atlas_coord)
			var tile:TileData = source.get_tile_data(atlas_coord, 0)
			#print("\tTileData retreived from source: ", tile)
			for indx in tile_config.collision_shapes.size():
				var collision_shape = tile_config.collision_shapes[indx]
				_create_collision_from_shape(tile, collision_shape, 0)
			for nav in tile_config.nav_poly:
				tile.set_navigation_polygon(0, nav)
			for indx in tile_config.light_occluder.size():
				tile.add_occluder_polygon(0)
				tile.set_occluder_polygon(0, indx, tile_config.light_occluder[indx].to())
			
		if tile_data.tile_mode == TileMode.Auto:
			#print_rich("[color=green]\n--- Creating Auto Tile ---[/color]")
			source.texture_region_size = tile_config.subtile_size
			out.tile_size = tile_config.subtile_size
			for x in tile_config.subtile_count.x:
				for y in tile_config.subtile_count.y:
					var atlas_coord = Vector2i(x,y)
					source.create_tile(atlas_coord)
					var tile:TileData = source.get_tile_data(atlas_coord, 0)
					tile.terrain_set = 0
					tile.terrain = 0
					var convert = _convert_peeringbits(tile_config.bitmask[str([x,y])])
					for bit in convert:
						tile.set_terrain_peering_bit(bit, 0)
					
					for indx in tile_config.collision_shapes.size():
						var collision_shape = tile_config.collision_shapes[indx]
						if collision_shape.autotile_coord == Vector2(x,y):
							_create_collision_from_shape(tile, collision_shape, 0)
					for nav in tile_config.nav_poly:
						tile.set_navigation_polygon(0, nav)
					for indx in tile_config.light_occluder.size():
						tile.add_occluder_polygon(0)
						tile.set_occluder_polygon(0, indx, tile_config.light_occluder[indx].to())
				
		if tile_data.tile_mode == TileMode.Atlas:
			#print_rich("[color=blue]\n--- Creating Atlas Tile ---[/color]")
			source.texture_region_size = tile_config.subtile_size
			out.tile_size = tile_config.subtile_size
			for x in tile_config.subtile_count.x:
				for y in tile_config.subtile_count.y:
					var atlas_coord = Vector2i(x,y)
					source.create_tile(atlas_coord)
					var tile:TileData = source.get_tile_data(atlas_coord, 0)
					for indx in tile_config.collision_shapes.size():
						var collision_shape = tile_config.collision_shapes[indx]
						if collision_shape.autotile_coord == Vector2(x,y):
							_create_collision_from_shape(tile, collision_shape, 0)
					for nav in tile_config.nav_poly:
						tile.set_navigation_polygon(0, nav)
					for indx in tile_config.light_occluder.size():
						tile.add_occluder_polygon(0)
						tile.set_occluder_polygon(0, indx, tile_config.light_occluder[indx].to())	
	return out

func overwrite_save(old_tileset_path:String, new_tileset:TileSet):
	ResourceSaver.save(new_tileset, old_tileset_path)

func backup_and_save(old_tileset_path:String, new_tileset:TileSet):
	var swap_path = old_tileset_path
	var swap_name = swap_path.get_file()
	var old = load(swap_path)
	var rid = old.get_rid()
	#print("old rid: ", rid)
	var backup_dir = _create_dir("res://", "converted_tileset_backup")
	old.take_over_path(backup_dir+swap_name)
	ResourceSaver.save(old)
	ResourceSaver.save(new_tileset, swap_path)
	ResourceSaver.set_uid(swap_path, rid.get_id())

func load_data_from_file(file_path:String) -> Dictionary:
	#print("<<<<<<<< Load Data From Path >>>>>>>>")
	var text := FileAccess.get_file_as_string(file_path)
	if text.is_empty():
		push_error("JSON file was empty")
		return {}
	#print("--- File Loaded To String ---")
	var result:Dictionary = JSON.parse_string(text)
	#print("--- File Parsed ---")
	if result == null:
		push_error("Invalid JSON format")
		return {}
	#print("--- LOADED TILESET FILE ---")
	return result

#func cast_data(data:Dictionary) -> TileSetData:
	#var out := TileSetData.new()
	#out.name = data["name"]
	#out.res_path = data["resource_path"]
	#out.atlases = data["atlases"]
	#var tile_data:Array[MyTileData]
	#for tile in data["tile_data"]:
		#var my_auto_config := AutoTileConfig.new()
		#my_auto_config.bitmask = tile["autotile"]["bitmask"]
		#my_auto_config.bitmask_mode = tile["autotile"]["bitmask_mode"]
		#my_auto_config.fallback_mode = tile["autotile"]["fallback_mode"]
		#var occluder := LightOccluder.new()
		#if tile["autotile"]["light_occluder"] != null:
			#occluder.closed = tile["autotile"]["light_occluder"]["closed"]
			#occluder.mode = tile["autotile"]["light_occluder"]["mode"]
			#occluder.pool = _string_to_v2_arr(tile["autotile"]["light_occluder"]["pool"])
		#my_auto_config.light_occluder = occluder
		#var nav_polys:Array[PackedVector2Array]
		#if tile["autotile"]["nav_polygon"] != null:
			#for poly in tile["autotile"]["nav_polygon"]:
				#nav_polys.append(_string_to_v2_arr(poly))
		#my_auto_config.nav_polys = nav_polys
		#my_auto_config.size.x = tile["autotile"]["size"][0]
		#my_auto_config.size.y = tile["autotile"]["size"][1]
		#my_auto_config.spacing = tile["autotile"]["spacing"]
		#my_auto_config.subtile_priority = tile["autotile"]["subtile_priority"]
		#my_auto_config.z_index = tile["autotile"]["z_index"]
		#
		#var my_tile := Tile.new()
		#occluder = LightOccluder.new()
		#if tile["tile"]["light_occluder"] != null:
			#occluder.closed = tile["tile"]["light_occluder"]["closed"]
			#occluder.mode = tile["tile"]["light_occluder"]["mode"]
			#occluder.pool = _string_to_v2_arr(tile["tile"]["light_occluder"]["pool"])
		#my_tile.light_occluder = occluder
		#my_tile.material_path = tile["tile"]["material"]
		#my_tile.modulate = _arr_to_color(tile["tile"]["modulate"])
		#my_tile.name = tile["tile"]["name"]
		#my_tile.nav_poly = tile["tile"]["nav_polygon"]
		#my_tile.nav_poly_offs = tile["tile"]["nav_polygon_offs"]
		#my_tile.normal_map_path = tile["tile"]["normal_map"]
		#my_tile.occluder_offs.x = tile["tile"]["occluder_offs"][0]
		#my_tile.occluder_offs.y = tile["tile"]["occluder_offs"][1]
		#my_tile.region = _arr_to_rect2i(tile["tile"]["region"])
		#for shape in tile["tile"]["shapes"]:
			#var my_shape := Shape.new()
			#my_shape.autotile_coord = shape["autotile_coord"]
			#my_shape.one_way = shape["one_way"]
			#my_shape.one_way_margin = shape["one_way_margin"]
			#my_shape.shape[shape["shape"].keys()[0]] = _string_to_v2_arr(shape["shape"].values()[0])
			#my_tile.shapes.append(my_shape)
		#my_tile.texture_path = tile["tile"]["texture"]
		#my_tile.texture_offs.x = tile["tile"]["texture_offs"][0]
		#my_tile.texture_offs.y = tile["tile"]["texture_offs"][1]
		#my_tile.tile_mode = tile["tile"]["tile_mode"]
		#
		#var my_tile_data := MyTileData.new()
		#my_tile_data.id = tile["id"]
		#my_tile_data.coord.x = tile["coord"]["x"]
		#my_tile_data.coord.y = tile["coord"]["y"]
		#my_tile_data.autotile_config = my_auto_config
		#my_tile_data.tile = my_tile
		#out.tile_data.append(my_tile_data)
	#return out

#func create_tileset_from_cast(data:MyTileSetData) -> TileSet:
	#var out := TileSet.new()
	#var sources:Dictionary[String,TileSetAtlasSource]
	#out.add_navigation_layer(0)
	#out.add_occlusion_layer(0)
	#out.add_physics_layer(0)
	#
	## create atlas sources
	#for atlas_path in data.atlases:
		#var source := TileSetAtlasSource.new()
		#source.texture = load(atlas_path)
		#sources[atlas_path] = source
		#out.add_source(source)
	#
	#for tile_data in data.tile_data:
		#if tile_data.tile.tile_mode == TileMode.Auto:
			#print()
		##Process Single Tiles
		#elif  tile_data.tile.tile_mode == TileMode.Single:
			#var source := sources[tile_data.tile.texture_path]
			#var coord = tile_data.coord
			#var region = tile_data.tile.region
			#source.texture_region_size = region.size
			#out.tile_size = region.size
			#if coord.x > region.size.x or coord.y > region.size.y:
				#continue
			#var pos = coord/region.size
			#source.create_tile(pos)
			#var tile:TileData = source.get_tile_data(pos, 0)
			##for indx in tile_data.tile.shapes.size()-1:
				##_create_collision_from_shape(tile, tile_data.tile.shapes[indx], indx)
			#for indx in tile_data.tile.nav_poly.size()-1:
				#var nav_poly := NavigationPolygon.new()
				#nav_poly.add_outline(tile_data.tile.nav_poly[indx])
				#tile.set_navigation_polygon(0, nav_poly)
			#if tile_data.tile.light_occluder.pool.size() == 0:
				#var occ := OccluderPolygon2D.new()
				#occ.closed = tile_data.tile.light_occluder.closed
				#occ.cull_mode = tile_data.tile.light_occluder.mode
				#occ.polygon = tile_data.tile.light_occluder.pool
				#tile.add_occluder_polygon(0)
				#var occ_indx = tile.get_occluder_polygons_count(0)-1
				#tile.set_occluder_polygon(0, occ_indx, occ)
			#
		#elif tile_data.tile.tile_mode == TileMode.Atlas:
			#print()
	#
	#return out

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
	
	#print("groups: ", groups.keys())
	for path in groups.keys():
		var source := TileSetAtlasSource.new()
		out.add_source(source)
		
		#print("path: ", path, 
			#"\nsources: ", out.get_source_count(), 
			#"\nsource: ", source, "\n")
		source.texture = load(path)
		var sep:float = groups[path][0]["autotile"]["spacing"]
		source.separation = Vector2(sep,sep)
		#var tile_mode = groups[path]["tilemode"]
		if groups[path].size() < 2: # if size is 1 then this is an atlas
			source.texture_region_size = source.texture.get_size()
		else: # if there are more than 1 elements this is a group of single tiles
			var size = Vector2(
				groups[path][0]["tile"]["region"][2], 
				groups[path][0]["tile"]["region"][3])
			source.texture_region_size = size
			out.tile_size = size

		for tile in groups[path]:
			var size = source.texture.get_size()
			var coord = Vector2(tile["coord"]["x"], tile["coord"]["y"])
			var region = Vector2(tile["tile"]["region"][2], tile["tile"]["region"][3])
			var pos = Vector2i(coord/region)
			if pos.x > size.x or pos.y > size.y:
				continue
			
			#print("attempting to create tile at ", pos, " in ", data["name"])
			#print("source texture size: ", size)
			#print("source region size: ", source.texture_region_size)
			#print("tile coord (px): ", coord)
			#print("tile size (px): ", region)
			source.create_tile(pos)
			
			var tile_data:TileData = source.get_tile_data(pos, 0)
			for indx in tile["tile"]["shapes"].size()-1:
				var shape = tile["tile"]["shapes"][indx]
				var packed_string:String
				#_create_collisions(tile_data, shape, indx)
			if tile["tile"]["nav_polygon"] != null:
				for indx in tile["tile"]["nav_polygon"].size()-1:
					var nav_poly := NavigationPolygon.new()
					nav_poly.add_outline(_string_to_v2_arr(tile["tile"]["nav_polygon"][indx]))
					tile_data.set_navigation_polygon(0, nav_poly)
			if tile["tile"]["light_occluder"] != null:
				##print("occluder: ", tile["tile"]["light_occluder"])
				var occ_poly := OccluderPolygon2D.new()
				occ_poly.polygon = _string_to_v2_arr(tile["tile"]["light_occluder"]["pool"])
				occ_poly.cull_mode = tile["tile"]["light_occluder"]["mode"]
				occ_poly.closed = tile["tile"]["light_occluder"]["closed"]
				tile_data.add_occluder_polygon(0)
				var occ_indx = tile_data.get_occluder_polygons_count(0)-1
				tile_data.set_occluder_polygon(0, occ_indx, occ_poly)
	return out

func _arr_to_rect2i(arr:Array[int]) -> Rect2i:
	return Rect2i(arr[0], arr[1], arr[2], arr[3])

func _arr_to_color(arr:Array[float]) -> Color:
	var out:Color
	out.r = arr[0]
	out.g = arr[1]
	out.b = arr[2]
	out.a = arr[3]
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

func _create_collision_from_shape(tile_data:TileData, shape:CollisionShape, indx:int):
	print_rich("[color=cyan]--- Create Collision From Shape ---[/color]")
	tile_data.add_collision_polygon(0)
	tile_data.set_collision_polygon_points(0, indx, shape.shape)
	tile_data.set_collision_polygon_one_way(0, indx, shape.one_way)
	tile_data.set_collision_polygon_one_way_margin(0, indx, shape.one_way_margin)
	var debug = tile_data.get_collision_polygon_points(0, indx)
	print_rich("\t[color=cyan]tile_data collision poly: [/color]", debug)

#func _create_collisions(tile_data:TileData, shape:Dictionary, indx:int, ):
	#var packed_string:String
	#if shape["shape"].keys()[0] == "Convex":
		#packed_string = shape["shape"]["Convex"]
	#elif shape["shape"].keys()[0] == "Concave":
		#packed_string = shape["shape"]["Concave"]
	#var packed_vec = _string_to_v2_arr(packed_string)
	#tile_data.set_collision_polygon_points(0, indx, packed_vec)
	#tile_data.set_collision_polygon_one_way(0, indx, shape["one_way"])
	#tile_data.set_collision_polygon_one_way_margin(0, indx, shape["one_way_margin"])
				
func _create_dir(path:String, dir_name:String) -> String:
	var full_path = path+"/"+dir_name
	var dir := DirAccess.open(path)
	if not dir.dir_exists(full_path):
		dir.make_dir(full_path)
	return full_path+"/"

enum TileMode {
	Single = 0,
	Auto = 1,
	Atlas = 2
}

func _convert_peeringbits(bits:Array) -> Array[TileSet.CellNeighbor]:
	var out:Array[TileSet.CellNeighbor]
	for bit in bits:
		if bit == "TopLeft":
			out.append(TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE)
		if bit == "Top":
			out.append(TileSet.CELL_NEIGHBOR_TOP_SIDE)
		if bit == "TopRight":
			out.append(TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE)
		if bit == "Left":
			out.append(TileSet.CELL_NEIGHBOR_LEFT_SIDE)	
		if bit == "Right":
			out.append(TileSet.CELL_NEIGHBOR_RIGHT_SIDE)
		if bit == "BottomLeft":
			out.append(TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE)
		if bit == "Bottom":
			out.append(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)
		if bit == "BottomRight":
			out.append(TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE)
	return out
	
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
