tool
extends WindowDialog

##### TODO #####
# - replace dict nonsense with classes (yeah, multi class files are a thing apparently)
# - add option for mono file export
# - thread export process

onready var event_log:RichTextLabel = $"%EventLog"
onready var export_in_place_btn:Button = $"%ExportInPlaceBtn"
onready var export_to_dir_btn:Button = $"%ExportToDirBtn"
onready var progress:ProgressBar = $"%ProgressBar"

const TileMapExporter = preload("../tilemap/tilemap_exporter.gd")
const TileSetExporter = preload("../tileset/tileset_exporter.gd")

## Key is Object, Value is the string path (could be inside .tscn)
#Dictionary:{TileMap:{PackedScene:String}}
var tilemaps:Dictionary = {}
var tilesets:Dictionary = {} #Load will actually give use a shared ref, we want unique ones
var retry_counter = 0

var file_dialog:EditorFileDialog
var _plugin:EditorPlugin

func set_plugin(p:EditorPlugin):
	if not _plugin: _plugin = p

func _ready():
	_existing_ids = []
	scan()
	print("TileMaps Dict: ", tilemaps)
	print("TileSets Dict: ", tilesets)
	export_in_place_btn.connect("button_up",self,"_on_exp_in_place_btn")
	export_to_dir_btn.connect("button_up", self, "_on_exp_to_dir_btn")

func scan():
	_existing_ids = []
	progress.visible = false
	tilemaps = {}
	tilesets = {}
	event_log.text = "Scanning....\n"
	var scenes = get_all_files("res://","tscn")
	var discovered_tilesets:Dictionary
	
	for scene in scenes:
		scene = scene as String
		#Dictionary: {TileMap:NodePath}
		var tile_maps_dict:Dictionary = search_tscn_file(scene)
		for tilemap in tile_maps_dict.keys():
			tilemap = tilemap as TileMap
			if tilemap.tile_set: 
				#This could get set twice, but the resource path should be the same.
				tilesets[tilemap.tile_set] = tilemap.tile_set.resource_path
			
			var node_path:String = String(tile_maps_dict[tilemap])
			tilemaps[tilemap] = {scene:node_path}
			
		#exporter.output_path = scene
	event_log.text += ("Found %d tilemaps\n" % tilemaps.size())
	event_log.text += ("Found %d tilesets\n" % tilesets.size())
	progress.max_value = tilemaps.size() + tilesets.size()
	

func _on_exp_in_place_btn():
	var map_exporter:TileMapExporter = TileMapExporter.new()
	var set_exporter:TileSetExporter = TileSetExporter.new()
	if not progress.visible: progress.visible = true
	for tilemap in tilemaps:
		var path:String = tilemaps[tilemap].keys()[0]
		var data = map_exporter.process_tilemap(tilemap)
		data["resource_path"] = path
		event_log.text += ("Exporting tilemap %s\n" % path)
		write_data(path.get_base_dir(),tilemap.name,data,"tilemap")
	
	for tileset in tilesets:
		var path:String = tilesets[tileset]
		var data = set_exporter.process_tileset(tileset)
		event_log.text += ("Exporting tileset %s\n" % path)
		write_data(path.get_base_dir(),path.get_file(), data, "tileset")
	pass

func _on_exp_to_dir_btn(): 
	var dialog = _get_file_dialogue()
	dialog.popup_centered(Vector2(800,600))

func _get_file_dialogue() -> EditorFileDialog:
	#print("_get_file_dialogue()")
	#print("self.file_dialog == ", file_dialog)
	if not self.file_dialog:
		file_dialog = EditorFileDialog.new()
		file_dialog.name = "BatchTileExporterFileDialog"
		file_dialog.window_title = "Save Batch Tile JSON Data"
		file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
		file_dialog.display_mode = EditorFileDialog.DISPLAY_LIST
		file_dialog.mode = EditorFileDialog.MODE_OPEN_DIR
		file_dialog.show_on_top = true
		file_dialog.dialog_hide_on_ok = true
		file_dialog.connect("dir_selected", self, "_export")
		#print("_plugin == ", _plugin)
		var base = _plugin.get_editor_interface().get_base_control()
		base.add_child(file_dialog)
		base.move_child(file_dialog, 0)
	#print("self.file_dialog == ", file_dialog)
	return file_dialog

#export to dir
func _export(file_path:String):
	_existing_ids = []
	var map_exporter:TileMapExporter = TileMapExporter.new()
	var set_exporter:TileSetExporter = TileSetExporter.new()
	if not progress.visible: progress.visible = true
	var map_path = create_dir(file_path, "TileMaps")
	var set_path = create_dir(file_path, "TileSets")
	for tilemap in tilemaps:
		var file_name:String = tilemaps[tilemap].keys()[0]
		file_name += tilemaps[tilemap].values()[0]
		print(file_name)
		print(tilemap)
		var data = map_exporter.process_tilemap(tilemap)
		data["resource_path"] = tilemaps[tilemap].keys()[0]
		
		event_log.text += ("Exporting tilemap %s\n" % file_name)
		write_data(map_path, generate_unique_name(16), data, "tilemap")
	
	for tileset in tilesets:
		var path:String = tilesets[tileset]
		var data = set_exporter.process_tileset(tileset)
		event_log.text += ("Exporting tileset %s\n" % path.replace("/", "%"))
		write_data(set_path, generate_unique_name(16), data, "tileset")
		#write_data(set_path, path.get_slice("res://", 1).percent_encode(), data, "tileset")
	pass

func write_data(path:String,file_name:String,dict:Dictionary, fallback:String, retry_attempt:bool = false):
	var json = JSON.print(dict, "\t")
	#print(file_name)
	var file_path = path.plus_file( file_name + ".json")
	var file = File.new()
	var error = file.open(file_path, File.WRITE)
	if error == OK:
		file.store_string(json)
		file.close()
		event_log.text += ("%s Exported\n" % file_path)
		#print("File saved to:", file_path)
	else:
		if not retry_attempt:
			event_log.text += ("Could not save: %s for writing, attempting fallback...\n" % file_path)
			retry_counter += 1
			write_data(path,fallback+"_"+str(retry_counter),dict,fallback,true)
		else:
			event_log.text += "Retry attempt failed\n"
	progress.value+=1

# creates a new dir inside path named dir_name and returns new full path -> path/to/dir/dir_name
func create_dir(path:String, dir_name:String) -> String:
	var full_path = path+"/"+dir_name
	var dir:Directory = Directory.new()
	if not dir.dir_exists(full_path):
		dir.make_dir(full_path)
	return full_path+"/"

func _exit_tree():
	for tilemap in tilemaps:
		tilemap.queue_free()
	pass

# returns Dictionary:{TileMap, NodePath}
func search_tscn_file(path:String) -> Dictionary:
	event_log.text += "Opening TSCN: " + path + "\n"
	var results:Dictionary = {}
	var scene:PackedScene = load(path)
	var scene_state:SceneState = scene.get_state()
	for node_id in scene_state.get_node_count():
		var type =  scene_state.get_node_type(node_id)
		if type == "TileMap":
			event_log.text += "Node of type: " + scene_state.get_node_type(node_id) + " found!\n"
			
			
			var node_path:NodePath = scene_state.get_node_path(node_id)
			print("node_path: ", node_path)
			
			
			var runtime_tilemap:TileMap = TileMap.new()
			runtime_tilemap.name = scene_state.get_node_name(node_id)
			for node_prop_id in scene_state.get_node_property_count(node_id):
				var prop_name = scene_state.get_node_property_name(node_id,node_prop_id)
				var prop_value = scene_state.get_node_property_value(node_id,node_prop_id)
				var prop_type = typeof(prop_value)
				if prop_name != "script":
					runtime_tilemap.set(prop_name,prop_value)
			results[runtime_tilemap] = node_path
	return results

func get_unique_tilesets(tile_maps:Array) -> Array:
	return []

func get_all_files(path: String, file_ext := "", files := []):
	var dir = Directory.new()

	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)

		var file_name = dir.get_next()

		while file_name != "":
			if dir.current_is_dir():
				files = get_all_files(dir.get_current_dir().plus_file(file_name), file_ext, files)
			else:
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue
				var full_path = dir.get_current_dir().plus_file(file_name)
				files.append(full_path)
				#event_log.text += "TSCN found: " + full_path + "\n"

			file_name = dir.get_next()
	else:
		event_log.text = ("An error occurred when trying to access %s." % path)

	return files

func _find_scene_root(start:Node) -> Node:
	var test:Node = start
	while test.owner != null:
		test = test.get_parent()
	return test

var _existing_ids:Array = []
const _chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890abcdefghijklmnopqrstuvwxyz"
func generate_unique_name(count:int) -> String:
	var out:String = ""
	for c in count:
		out += _chars[randi()%_chars.length()-1]
	if _existing_ids.has(out):
		return generate_unique_name(count)
	return out
