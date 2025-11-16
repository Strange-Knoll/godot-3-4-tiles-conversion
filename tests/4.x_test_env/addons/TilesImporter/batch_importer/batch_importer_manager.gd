@tool
extends RefCounted

const BatchImporterUIScript:Script = preload("batch_importer_ui.gd")
const BatchImporterUIScene:PackedScene = preload("batch_importer_ui.tscn")
const BatchImporterScript:Script = preload("batch_importer.gd")
var importer:BatchImporterScript
var _ui:Window

func open_file_dialog() -> void:
	var dialog := _get_file_dialog()
	dialog.file_selected.connect(_on_file_selected)
	dialog.popup_centered(Vector2(800,600))

func _init() -> void:
	importer = BatchImporterScript.new()
	if _ui == null: 
		_ui = BatchImporterUIScene.instantiate()
		_ui.set_script(BatchImporterUIScript)
		_ui.hide() 
		EditorInterface.get_base_control().add_child(_ui)
		EditorInterface.get_base_control().move_child(_ui, 0)
	importer.post_entry_count.connect(_ui.set_progress_max)
	importer.post_progress.connect(_ui.incriment_progress)
	importer.post_log.connect(_ui.put_event)

func _get_file_dialog() -> EditorFileDialog:
	var base_control = EditorInterface.get_base_control()
	var file_dialog:EditorFileDialog = base_control.get_node_or_null("BatchImporterFileDialog")
	if not file_dialog:
		file_dialog = EditorFileDialog.new()
		file_dialog.name = "BatchImporterFileDialog"
		file_dialog.title = "TileMap/TileSet Batch Importer"
		file_dialog.dialog_hide_on_ok = true
		file_dialog.mode = Window.MODE_WINDOWED
		file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
		file_dialog.display_mode = EditorFileDialog.DISPLAY_LIST
		file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		file_dialog.set_filename_filter("*.json")
		base_control.add_child(file_dialog)
		base_control.move_child(file_dialog, 0)
	return file_dialog
		
func _on_file_selected(path:String) -> void:
	_ui.popup_centered(Vector2(800,600))
	importer.read_index(importer.load_json(path))
	
