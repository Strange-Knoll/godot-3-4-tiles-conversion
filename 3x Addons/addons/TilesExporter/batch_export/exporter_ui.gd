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

var scan_thread:Thread
var scan_mutex:Mutex
var scan_results

var export_thread:Thread
var export_mutex:Mutex

func set_plugin(p:EditorPlugin):
	if not _plugin: _plugin = p

func _ready():
	
	exporter = BatchExporter.new()
	exporter.connect("post_log", self, "_update_log")
	exporter.connect("post_progress", self, "_update_progress_bar")
	exporter.connect("post_scan_count", self, "_set_progress_max")
	
	export_in_place_btn = $"%ExportInPlaceBtn"
	export_to_dir_btn  = $"%ExportToDirBtn"
	
	scan_thread = Thread.new()
	scan_mutex = Mutex.new()
	export_thread = Thread.new()
	export_mutex = Mutex.new()
	scan_thread.start(self, "_thread_scan", exporter)


func _thread_scan(exporter: BatchExporter):
	scan_mutex.lock()
	scan_results = exporter.scan()
	scan_results = scan_results as BatchExporter.ScanResult
	
	export_in_place_btn.connect("button_up",self,"_on_exp_in_place_btn", [scan_results])
	export_to_dir_btn.connect("button_up", self, "_on_exp_to_dir_btn", [scan_results])
	scan_mutex.unlock()

func _on_exp_to_dir_btn(ref: BatchExporter.ScanResult): 
	var dialog = _get_file_dialogue()
	dialog.connect("dir_selected", self, "_on_exp_dir_selected", [ref])
	dialog.connect("dir_selected", self, "_show_progress_bar")
	dialog.popup_centered(Vector2(800,600))

func _on_exp_in_place_btn(ref: BatchExporter.ScanResult):
	_show_progress_bar()
	export_thread.start(self, "_in_place_thread", ref)

func _in_place_thread(ref: BatchExporter.ScanResult):
	exporter.export_in_place(ref)

func _on_exp_dir_selected(path:String, ref: BatchExporter.ScanResult):
	export_thread.start(self, "_export_dir_thread", [path, ref])

func _export_dir_thread(data:Array):
	exporter.export_to_dir(data[0], data[1])
	


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
	scan_thread.wait_to_finish()
	export_thread.wait_to_finish()
