@tool
extends EditorPlugin

const TileMapImporterUIScript:Script = preload("tilemap/tilemap_importer_ui.gd")
const TilesetImporterUIScript:Script = preload("tileset/tileset_importer_ui.gd")
const BatchImporterManager:Script = preload("batch_importer/batch_importer_manager.gd")
var tilemap_importer_menu:EditorContextMenuPlugin
var tileset_importer_menu:EditorContextMenuPlugin
var batch_manager:BatchImporterManager

func _enter_tree() -> void: pass

func _exit_tree() -> void: pass

func _enable_plugin() -> void:
	tilemap_importer_menu = TileMapImporterUIScript.new()
	tileset_importer_menu = TilesetImporterUIScript.new()
	batch_manager = BatchImporterManager.new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE, tilemap_importer_menu)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, tileset_importer_menu)
	add_tool_menu_item("TileMap/TileSet Batch Importer", _open_batch_import)

func _open_batch_import():
	batch_manager.open_file_dialog()

func _disable_plugin() -> void:
	#print("_disable_plugin")
	remove_context_menu_plugin(tilemap_importer_menu)
	remove_context_menu_plugin(tileset_importer_menu)
	remove_tool_menu_item("TileMap/TileSet Batch Importer")
