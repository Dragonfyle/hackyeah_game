extends Node

var active_movables: Array[Movable] = []

func spawn(movable: Movable, spawn_position: Vector2, lifetime_sec: int = -1) -> Movable:
	movable.position = spawn_position
	get_tree().current_scene.add_child(movable)
	active_movables.append(movable)

	# automatic despawn
	if lifetime_sec > 0:
		var timer = Timer.new()
		timer.wait_time = lifetime_sec
		timer.one_shot = true
		timer.timeout.connect(func(): despawn(movable))
		movable.add_child(timer)
		timer.start()

	return movable

func despawn(movable: Movable) -> void:
	if movable in active_movables:
		active_movables.erase(movable)

	if is_instance_valid(movable) and movable.get_parent():
		movable.get_parent().remove_child(movable)
		movable.queue_free()

func despawn_all() -> void:
	for movable in active_movables.duplicate():
		despawn(movable)
	active_movables.clear()

func get_active_count() -> int:
	return active_movables.size()
