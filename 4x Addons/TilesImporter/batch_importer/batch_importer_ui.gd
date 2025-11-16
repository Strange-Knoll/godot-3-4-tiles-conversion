@tool
extends Window

const BatchImporter = preload("batch_importer.gd")
var importer:BatchImporter

@onready var event_log:RichTextLabel = $"%RichTextLabel"
@onready var progress_bar:ProgressBar = $"%ProgressBar"

func _ready() -> void:
	close_requested.connect(hide)

func put_event(event:String):
	event_log.text+=event

func set_progress_max(val:int):
	progress_bar.max_value = val

func incriment_progress():
	progress_bar.value+=1
