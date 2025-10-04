extends Node

var active_flyables: Array[Flyable] = []

func spawn(flyable: Flyable, spawn_position: Vector2) -> Flyable:
	flyable.position = spawn_position
	get_tree().current_scene.add_child(flyable)
	active_flyables.append(flyable)

	return flyable

func despawn(flyable: Flyable) -> void:
	if flyable in active_flyables:
		active_flyables.erase(flyable)

	if is_instance_valid(flyable) and flyable.get_parent():
		flyable.get_parent().remove_child(flyable)
		flyable.queue_free()

func despawn_all() -> void:
	for flyable in active_flyables.duplicate():
		despawn(flyable)
	active_flyables.clear()

func get_active_count() -> int:
	return active_flyables.size()
