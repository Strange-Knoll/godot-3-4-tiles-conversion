@tool
extends EditorPlugin

const ContextMenu:Script = preload("res://addons/tilemap_converter/context_menu.gd")
var context_menu:EditorContextMenuPlugin = ContextMenu.new()

#func _enter_tree() -> void: pass
#
#func _exit_tree() -> void: pass
#
func _enable_plugin() -> void:
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE, context_menu)

func _disable_plugin() -> void:
	remove_context_menu_plugin(context_menu)
