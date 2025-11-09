tool
extends EditorPlugin

const InspectorScript:Script = preload("res://addons/tilemap_exporter/inspector.gd")
var inspector = InspectorScript.new()


func _enter_tree():
	add_inspector_plugin(inspector)
	inspector.set_plugin(self)
	pass


func _exit_tree():
	remove_inspector_plugin(inspector)
	pass
