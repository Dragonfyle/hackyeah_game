extends CanvasLayer

@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	time_label.text = "Time: %s" % ScoreManager.get_time_formatted()
