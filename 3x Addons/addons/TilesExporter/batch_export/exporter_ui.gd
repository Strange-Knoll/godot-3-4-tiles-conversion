tool
extends WindowDialog

##### TODO #####
# - add option for mono file export
# - thread export process

onready var event_log:RichTextLabel = $"%EventLog"
onready var export_in_place_btn:Button = $"%ExportInPlaceBtn"
onready var export_to_dir_btn:Button = $"%ExportToDirBtn"
onready var progress:ProgressBar = $"%ProgressBar"

const BatchExporter = preload("batch_exporter.gd")
var exporter


var file_dialog:EditorFileDialog
var _plugin:EditorPlugin

func set_plugin(p:EditorPlugin):
	if not _plugin: _plugin = p

func _ready():
	exporter = BatchExporter.new()
	exporter.connect("post_log", self, "_update_log")
	exporter.connect("post_progress", self, "_update_progress_bar")
	exporter.connect("post_scan_count", self, "_set_progress_max")
	
	var scan_results = exporter.scan()
	scan_results = scan_results as BatchExporter.ScanResult
	export_in_place_btn.connect("button_up",self,"_on_exp_in_place_btn", [scan_results])
	export_to_dir_btn.connect("button_up", self, "_on_exp_to_dir_btn", [scan_results])

func _on_exp_to_dir_btn(ref: BatchExporter.ScanResult): 
	print("_on_exp_to_dir_btn")
	var dialog = _get_file_dialogue()
	dialog.connect("dir_selected", exporter, "export_to_dir", [ref])
	dialog.connect("dir_selected", self, "_show_progress_bar")
	dialog.popup_centered(Vector2(800,600))

func _on_exp_in_place_btn(ref: BatchExporter.ScanResult):
	print("_on_exp_in_place_btn")
	_show_progress_bar()
	exporter.export_in_place(ref)

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
		#file_dialog.connect("dir_selected", self, "_export")
		#print("_plugin == ", _plugin)
		var base = _plugin.get_editor_interface().get_base_control()
		base.add_child(file_dialog)
		base.move_child(file_dialog, 0)
	#print("self.file_dialog == ", file_dialog)
	return file_dialog

func _update_log(report):
	print("_update_log")
	report = report as String
	event_log = event_log as RichTextLabel
	event_log.text += report

func _show_progress_bar(path = ""):
	print("_show_progress_bar")
	progress = progress as ProgressBar
	progress.visible = true

func _update_progress_bar():
	print("_update_progress_bar")
	progress = progress as ProgressBar
	progress.value += 1
	pass

func _set_progress_max(val:int):
	print("_set_progress_max")
	progress = progress as ProgressBar
	progress.max_value = val

func _exit_tree():
#	for tilemap in tilemaps:
#		tilemap.queue_free()
	pass

