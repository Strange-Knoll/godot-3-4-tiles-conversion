tool
extends WindowDialog

##### TODO #####
# - add option for mono file export
# - thread export process

onready var event_log:RichTextLabel = $"%EventLog"
onready var progress:ProgressBar = $"%ProgressBar"
var export_in_place_btn:Button
var export_to_dir_btn:Button

const BatchExporter = preload("batch_exporter.gd")
var exporter


var file_dialog:EditorFileDialog
var _plugin:EditorPlugin

#var thread:Thread
#var mutex:Mutex
#var scan_results

signal _ready_complete

func set_plugin(p:EditorPlugin):
	if not _plugin: _plugin = p

func _ready():
	
	exporter = BatchExporter.new()
	exporter.connect("post_log", self, "_update_log")
	exporter.connect("post_progress", self, "_update_progress_bar")
	exporter.connect("post_scan_count", self, "_set_progress_max")
	
	export_in_place_btn = $"%ExportInPlaceBtn"
	export_to_dir_btn  = $"%ExportToDirBtn"
	connect("_ready_complete", self, "_on_ready_complete")
	emit_signal("_ready_complete")
#	thread = Thread.new()
#	mutex = Mutex.new()
#	thread.start(self, "_thread_scan", exporter)
#	scan_results = thread.wait_to_finish()
	
func _on_ready_complete() -> void:
	var scan_results = exporter.scan() as BatchExporter.ScanResult
	export_in_place_btn.connect("button_up",self,"_on_exp_in_place_btn", [scan_results])
	export_to_dir_btn.connect("button_up", self, "_on_exp_to_dir_btn", [scan_results])

#func _thread_scan(exporter: BatchExporter) -> BatchExporter.ScanResult:
#	mutex.lock()
#	return exporter.scan() as BatchExporter.ScanResult
#	mutex.unlock()

func _on_exp_to_dir_btn(ref: BatchExporter.ScanResult): 
	var dialog = _get_file_dialogue()
	dialog.connect("dir_selected", self, "_on_exp_dir_selected", [ref])
	dialog.connect("dir_selected", self, "_show_progress_bar")
	dialog.popup_centered(Vector2(800,600))

func _on_exp_in_place_btn(ref: BatchExporter.ScanResult):
	_show_progress_bar()
	exporter.export_in_place(ref)
	#thread.start(self, "_in_place_thread", [ref])
	

#func _in_place_thread(data:Array):
#	mutex.lock()
#	exporter.export_in_place(data[0])
#	mutex.unlock()
#	thread.wait_to_finish()

func _on_exp_dir_selected(path:String, ref: BatchExporter.ScanResult):
	exporter.export_to_dir(path, ref)
#	thread.start(self, "_export_dir_thread", [path, ref])
#	thread.wait_to_finish()
	pass

#func _export_dir_thread(data:Array):
#	mutex.lock()
#	exporter.export_to_dir(data[0], data[1])
#	mutex.unlock()
	


func _get_file_dialogue() -> EditorFileDialog:
	if not self.file_dialog:
		file_dialog = EditorFileDialog.new()
		file_dialog.name = "BatchTileExporterFileDialog"
		file_dialog.window_title = "Save Batch Tile JSON Data"
		file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
		file_dialog.display_mode = EditorFileDialog.DISPLAY_LIST
		file_dialog.mode = EditorFileDialog.MODE_OPEN_DIR
		file_dialog.show_on_top = true
		file_dialog.dialog_hide_on_ok = true
		var base = _plugin.get_editor_interface().get_base_control()
		base.add_child(file_dialog)
		base.move_child(file_dialog, 0)
	return file_dialog

func _update_log(report):
	report = report as String
	event_log = event_log as RichTextLabel
	event_log.text += report

func _show_progress_bar(path = ""):
	progress = progress as ProgressBar
	progress.visible = true

func _update_progress_bar():
	progress = progress as ProgressBar
	progress.value += 1
	pass

func _set_progress_max(val:int):
	progress = progress as ProgressBar
	progress.max_value = val

func _exit_tree():
	#thread.wait_to_finish()
	pass
