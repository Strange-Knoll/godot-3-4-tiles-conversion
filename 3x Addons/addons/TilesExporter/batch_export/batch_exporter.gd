extends Reference

class ScanResult:
	var tilemaps:Dictionary = {}
	var tilesets:Dictionary = {}
	
	func _init():
		self.tilemaps = {}
		self.tilesets = {}
	
	func cleanup():
		for tilemap in tilemaps:
			tilemap = tilemap as TileMap
			tilemap.queue_free()
	
signal post_log(report)
signal post_progress()
signal post_scan_count(val)

const TileMapExporter = preload("../tilemap/tilemap_exporter.gd")
const TileSetExporter = preload("../tileset/tileset_exporter.gd")

func scan() -> ScanResult:
	var out := ScanResult.new()
	var scenes = _get_all_files("res://","tscn")
	for scene in scenes:
		scene = scene as String
		var search_results:Array = _search_tscn_file(scene)
		for result in search_results:
			var tilemap = result[0] as TileMap
			var node_path = result[1] as String
			if tilemap.tile_set: 
				#This could get set twice, but the resource path should be the same.
				out.tilesets[tilemap.tile_set] = tilemap.tile_set.resource_path
			out.tilemaps[tilemap] = [scene, node_path]
	emit_signal("post_scan_count", out.tilemaps.keys().size()+out.tilesets.keys().size())
	return out

func export_in_place(scan_data:ScanResult):
	var map_exporter:TileMapExporter = TileMapExporter.new()
	var set_exporter:TileSetExporter = TileSetExporter.new()
	for tilemap in scan_data.tilemaps:
		var res_path:String = scan_data.tilemaps[tilemap][0]
		var node_path:String = scan_data.tilemaps[tilemap][1]
		var data = map_exporter.process_tilemap(tilemap)
		data["scene_resource_path"] = res_path
		data["node_path"] = node_path
		emit_signal("post_log", ("Exporting tilemap %s\n" % res_path))
		_write_data(res_path.get_base_dir(),tilemap.name,data,"tilemap")
	
	for tileset in scan_data.tilesets:
		var path:String = scan_data.tilesets[tileset]
		var data = set_exporter.process_tileset(tileset)
		emit_signal("post_log", ("Exporting tileset %s\n" % path))
		_write_data(path.get_base_dir(),path.get_file(), data, "tileset")
	scan_data.cleanup()

func export_to_dir(file_path:String, scan_data:ScanResult):
	var map_exporter:TileMapExporter = TileMapExporter.new()
	var set_exporter:TileSetExporter = TileSetExporter.new()
	var map_path = _create_dir(file_path, "TileMaps")
	var set_path = _create_dir(file_path, "TileSets")
	var index = {
		"header":"sk:gd3-4_tm/ts_ind",
		"tilemap_dir":map_path,
		"tileset_dir":set_path,
		"tilemaps":{}, 
		"tilesets":{}
	}
	for tilemap in scan_data.tilemaps:
		tilemap = tilemap as TileMap
		var res_path:String = scan_data.tilemaps[tilemap][0]
		var node_path:String = scan_data.tilemaps[tilemap][1]
		var data = map_exporter.process_tilemap(tilemap)
		data["scene_resource_path"] = res_path
		data["node_path"] = node_path
		emit_signal("post_log",("Exporting tilemap %s\n" % tilemap.name))
		var unique_name = _generate_unique_name(16)
		index["tilemaps"][unique_name] = {"res_path": res_path, "node_path": node_path}
		_write_data(map_path, unique_name, data, "tilemap")
	
	for tileset in scan_data.tilesets:
		var path:String = scan_data.tilesets[tileset]
		var data = set_exporter.process_tileset(tileset)
		emit_signal("post_log", ("Exporting tileset %s\n" % path.replace("/", "%")))
		var unique_name = _generate_unique_name(16)
		index["tilesets"][unique_name] = path
		_write_data(set_path, unique_name, data, "tileset")
	_write_data(file_path, "index", index, "export_index")
	scan_data.cleanup()

var _retry_counter:int = 0
func _write_data(path:String,file_name:String,dict:Dictionary, fallback:String, retry_attempt:bool = false):
	var json = JSON.print(dict, "\t")
	var file_path = path.plus_file( file_name + ".json")
	var file = File.new()
	var error = file.open(file_path, File.WRITE)
	if error == OK:
		file.store_string(json)
		file.close()
		emit_signal("post_log", ("%s Exported\n" % file_path))
	else:
		if not retry_attempt:
			emit_signal("post_log", ("Could not save: %s for writing, attempting fallback...\n" % file_path))
			_retry_counter += 1
			_write_data(path,fallback+"_"+str(_retry_counter),dict,fallback,true)
		else:
			emit_signal("post_log", "Retry attempt failed\n")
	emit_signal("post_progress")

func _create_dir(path:String, dir_name:String) -> String:
	var full_path = path+"/"+dir_name
	var dir:Directory = Directory.new()
	if not dir.dir_exists(full_path):
		dir.make_dir(full_path)
	return full_path+"/"


func _search_tscn_file(path:String) -> Array:
	emit_signal("post_log", "Opening TSCN: " + path + "\n")
	var results:Array = []
	var scene:PackedScene = load(path)
	var scene_state:SceneState = scene.get_state()
	for node_id in scene_state.get_node_count():
		var type = scene_state.get_node_type(node_id)
		if type == "TileMap":
			emit_signal("post_log", "Node of type: " + type + " found!\n")
			var node_path = String(scene_state.get_node_path(node_id))
			var runtime_tilemap:TileMap = TileMap.new()
			runtime_tilemap.name = scene_state.get_node_name(node_id)
			for node_prop_id in scene_state.get_node_property_count(node_id):
				var prop_name = scene_state.get_node_property_name(node_id,node_prop_id)
				var prop_value = scene_state.get_node_property_value(node_id,node_prop_id)
				var prop_type = typeof(prop_value)
				if prop_name != "script":
					runtime_tilemap.set(prop_name,prop_value)
			results.append([runtime_tilemap, node_path])
	return results

func _get_all_files(path: String, file_ext := "", files := []):
	#print("_get_all_files( ", path, " )")
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				files = _get_all_files(dir.get_current_dir().plus_file(file_name), file_ext, files)
			else:
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue
				var full_path = dir.get_current_dir().plus_file(file_name)
				files.append(full_path)
				#event_log.text += "TSCN found: " + full_path + "\n"
				emit_signal("post_log", "TSCN found: " + full_path + "\n")
			file_name = dir.get_next()
	else:
		printerr("An error occurred when trying to access %s." % path)
		#event_log.text = ("An error occurred when trying to access %s." % path)
		emit_signal("post_log", ("An error occurred when trying to access %s." % path))

	return files

var _existing_ids:Array = []
const _chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890abcdefghijklmnopqrstuvwxyz"
func _generate_unique_name(count:int) -> String:
	#print("_generate_unique_name")
	var out:String = ""
	for c in count:
		out += _chars[randi()%_chars.length()-1]
	if _existing_ids.has(out):
		return _generate_unique_name(count)
	return out

#func _find_scene_root(start:Node) -> Node:
#
#	var test:Node = start
#	while test.owner != null:
#		test = test.get_parent()
#	return test
