@tool
extends EditorPlugin

const ContextMenu:Script = preload("res://addons/tileset_converter/context_menu.gd")
var context_menu:EditorContextMenuPlugin

func _enter_tree() -> void: pass

func _exit_tree() -> void: pass

func _enable_plugin() -> void:
	print("_enable_plugin")
	context_menu = ContextMenu.new()
	print("context_menu:", context_menu)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, context_menu)

func _disable_plugin() -> void:
	print("_disable_plugin")
	remove_context_menu_plugin(context_menu)
