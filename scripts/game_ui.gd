extends CanvasLayer

@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	time_label.text = "Time: %s" % ScoreManager.get_time_formatted()
	score_label.text = "Score: %d" % ScoreManager.get_score()
