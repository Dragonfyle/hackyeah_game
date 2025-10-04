extends Node

var active_movables: Array[Movable] = []

func spawn(movable: Movable, spawn_position: Vector2, lifetime_sec: int = -1) -> Movable:
	print("MovableManager.spawn called with movable: ", movable, " position: ", spawn_position)
	movable.position = spawn_position
	print("Position set to: ", movable.position)
	
	# Use call_deferred to avoid physics callback issues
	get_tree().current_scene.call_deferred("add_child", movable)
	print("Movable added to scene tree")
	
	active_movables.append(movable)
	print("Movable added to active list. Total active: ", active_movables.size())

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
		print("Despawning movable: ", movable)
		active_movables.erase(movable)

	if is_instance_valid(movable) and movable.get_parent():
		print("Removing movable from parent: ", movable.get_parent())
		# Use call_deferred to avoid physics callback issues
		movable.get_parent().call_deferred("remove_child", movable)
		movable.queue_free()

func despawn_all() -> void:
	for movable in active_movables.duplicate():
		despawn(movable)
	active_movables.clear()

func get_active_count() -> int:
	return active_movables.size()
