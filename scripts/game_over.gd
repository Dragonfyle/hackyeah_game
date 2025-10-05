extends CanvasLayer

@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel

var score: int = 0

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_game_over(final_score: int = 0) -> void:
	score = final_score
	score_label.text = "Score: %d" % score
	show()
	get_tree().paused = true

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	MovableManager.despawn_all()
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
