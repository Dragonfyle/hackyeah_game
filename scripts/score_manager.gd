extends Node

# Score rates for different player states
@export var moving_score_rate: float = 10.0   # Points per second when player is moving
@export var idle_score_rate: float = moving_score_rate * 0.1   # Points per second when player is idle

var current_score: float = 0.0
var current_time: float = 0.0
var is_moving: bool = false

func _process(delta: float) -> void:
	# Accumulate score based on current movement state
	if is_moving:
		current_score += moving_score_rate * delta
	else:
		current_score -= idle_score_rate * delta

	# Track game time
	current_time += delta

func set_moving(moving: bool) -> void:
	is_moving = moving

func get_score() -> int:
	return int(current_score)

func get_time() -> float:
	return current_time

func get_time_formatted() -> String:
	var minutes = int(current_time) / 60
	var seconds = int(current_time) % 60
	return "%02d:%02d" % [minutes, seconds]

func reset_score() -> void:
	current_score = 0.0
	current_time = 0.0
	is_moving = false
