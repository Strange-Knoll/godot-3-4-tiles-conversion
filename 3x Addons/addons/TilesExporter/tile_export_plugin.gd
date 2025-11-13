tool
extends EditorPlugin

const TileSetExporterInspectorPlugin = preload("tileset/tileset_inspector.gd")
const TileMapExporterInspectorPlugin = preload("tilemap/tilemap_inspector.gd")
const batch_converter_dialogue = preload("batch_export/exporter_ui.tscn")
const batch_converter_dialogue_script = preload("batch_export/exporter_ui.gd")

const TOOL_MENU_LABEL = "TileMap/TileSet Batch Exporter"

var inspectors:Array = []

func _enter_tree():
	var tileset_inspector = TileSetExporterInspectorPlugin.new()
	var tilemap_inspector = TileMapExporterInspectorPlugin.new()
	inspectors = [tileset_inspector,tilemap_inspector]
	for inspector in inspectors:
		add_inspector_plugin(inspector)
		inspector.set_plugin(self)
	add_tool_menu_item(TOOL_MENU_LABEL,self,"start_batch_convert")

func start_batch_convert(_nothing_godot_is_silly): #Needed to make the tool menu work :/
	var dialogue_base_node = batch_converter_dialogue.instance()
	dialogue_base_node.set_script(batch_converter_dialogue_script)
	dialogue_base_node.set_plugin(self)
	
	var base_control = get_editor_interface().get_base_control()
	base_control.add_child(dialogue_base_node)
	
	dialogue_base_node.connect("popup_hide",self,"on_dialogue_closed",[dialogue_base_node])
	dialogue_base_node.popup_centered()

func on_dialogue_closed(dialogue:Node):
	dialogue.queue_free()

func _exit_tree():
	for inspector in inspectors:
		remove_inspector_plugin(inspector)
	inspectors = []
	remove_tool_menu_item(TOOL_MENU_LABEL)
