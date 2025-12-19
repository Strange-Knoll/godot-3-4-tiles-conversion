@tool
extends RefCounted

const TileMapImporter = preload("../tilemap/tilemap_importer.gd")
const TileSetImporter = preload("../tileset/tileset_importer.gd")



signal post_log(report:String)
signal post_progress()
signal post_entry_count(val:int)

#func _init() -> void:
	#map_importer = TileMapImporter.new()
	#set_importer = TileSetImporter.new()

func read_index(index:Dictionary):
	if not (index.has("header") and index["header"] == "sk:gd3-4_tm/ts_ind"):
		push_error("index does not have valid header")
		return 
	var entry_count = index["tilemaps"].keys().size()+index["tilesets"].keys().size()
	post_entry_count.emit(entry_count)
	post_log.emit("found "+str(entry_count)+" in index\n")
	_replace_tilesets(index)
	_replace_tilemaps(index)

func _replace_tilesets(index:Dictionary) -> void:
	#print("<<<<<<<< Replace Tilesets >>>>>>>>")
	#print("TileSet Directory -> ", index["tileset_dir"])
	var set_importer := TileSetImporter.new()
	post_log.emit("Beginning TileSet Import...\n")
	for tileset_entry in index["tilesets"]:
		#print("Reading Entry -> ", tileset_entry)
		var tileset_path = index["tileset_dir"]+tileset_entry+".json"
		#print("TileSet Path -> ", tileset_path)
		var data = set_importer.load_data_from_file(tileset_path)
		#print("Resource Path From Data -> ", data["resource_path"])
		var res_path = data["resource_path"]
		post_log.emit("converting TileSet at: "+res_path+"\n")
		var tileset:TileSet = set_importer.create_tileset_from_classes(data)
		#var tileset:TileSet = set_importer.create_tileset_from_data(data)
		#set_importer.backup_and_save(res_path, tileset)
		set_importer.overwrite_save(res_path, tileset)
		post_progress.emit()

func _replace_tilemaps(index:Dictionary) -> void:
	var map_importer := TileMapImporter.new()
	post_log.emit("Beginning TileMap Import...\n")
	var scene_groups:Dictionary[String, Array]
	for tilemap_entry in index["tilemaps"].keys():
		# wtf is this dictionary spaghetti
		var key = index["tilemaps"][tilemap_entry]["res_path"]
		var value = [tilemap_entry, index["tilemaps"][tilemap_entry]["node_path"]]
		#print("key[ ", key," ] == ", value)
		scene_groups.get_or_add(index["tilemaps"][tilemap_entry]["res_path"], []).append(
			[tilemap_entry, index["tilemaps"][tilemap_entry]["node_path"]]
		)
		#print("scene_groups: ", scene_groups)
	for scene_path in scene_groups:
		var packedscene:PackedScene = load(scene_path)
		var scene = packedscene.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
		var new_packed_scene = PackedScene.new()
		for map_indx in scene_groups[scene_path]:
			# seriously what is happening here
			var data = load_json(index["tilemap_dir"]+"/"+map_indx[0]+".json")
			var node_path = map_indx[1]
			post_log.emit("converting TileMap ("+node_path+") at: "+scene_path+"\n")
			var old_tilemap = scene.get_node(NodePath(node_path))
			if not old_tilemap is TileMap:
				continue
			var new_layer = map_importer.create_better_layer(data)
			if new_layer != null:
				map_importer.replace_tilemap(old_tilemap, new_layer)
			post_progress.emit()
		new_packed_scene.pack(scene)
		map_importer.overwrite_save(scene_path, new_packed_scene)
		scene.queue_free()
		
func load_json(file_path:String) -> Dictionary:
	post_log.emit("loading json file from: "+file_path+"\n")
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
