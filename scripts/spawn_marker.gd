class_name SpawnMarker
extends Node2D

signal animation_complete

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.play("flash")

func _on_animation_finished(_anim_name: String) -> void:
	animation_complete.emit()
	queue_free()
