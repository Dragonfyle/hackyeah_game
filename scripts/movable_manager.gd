extends Node

var active_movables: Array[Movable] = []
var is_paused: bool = false

func spawn(movable: Movable, spawn_position: Vector2, lifetime_sec: int = -1, show_marker: bool = true) -> Movable:
	if show_marker:
		# Show spawn marker and wait for animation
		var marker_scene = preload("res://scenes/spawn_marker.tscn")
		var marker = marker_scene.instantiate()
		marker.position = spawn_position
		get_tree().current_scene.add_child(marker)
		await marker.animation_complete

	movable.position = spawn_position

	# Use call_deferred to avoid physics callback issues
	get_tree().current_scene.call_deferred("add_child", movable)

	active_movables.append(movable)

	# If currently slowed, apply slowdown to the newly spawned movable
	if is_paused:
		movable.call_deferred("apply_slowdown")

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
		# Use call_deferred to avoid physics callback issues
		movable.get_parent().call_deferred("remove_child", movable)
		movable.queue_free()

func despawn_all() -> void:
	for movable in active_movables.duplicate():
		despawn(movable)
	active_movables.clear()

func get_active_count() -> int:
	return active_movables.size()

func apply_slowdown_all() -> void:
	is_paused = true
	for movable in active_movables:
		if is_instance_valid(movable):
			movable.apply_slowdown()

func remove_slowdown_all() -> void:
	is_paused = false
	for movable in active_movables:
		if is_instance_valid(movable):
			movable.remove_slowdown()
