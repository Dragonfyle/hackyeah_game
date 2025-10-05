class_name ExplosiveMovable
extends Movable

## Time in seconds before the movable explodes
@export var explosion_time: float = 2.0
## Number of projectiles spawned in the explosion
@export var explosion_count: int = 8

var explosion_timer: Timer

func _ready() -> void:
	# Call parent _ready to set up velocity and signals
	super._ready()

	# Create and configure explosion timer
	explosion_timer = Timer.new()
	explosion_timer.wait_time = explosion_time
	explosion_timer.one_shot = true
	explosion_timer.timeout.connect(_on_explosion_timer_timeout)
	add_child(explosion_timer)
	explosion_timer.start()

## Override the collision handler to NOT split on wall collision
func _on_body_entered(body: Node) -> void:
	# Still damage player on collision
	if body is CharacterBody2D:
		emit_signal("collision", body, body.global_position, Vector2.ZERO)
		call_deferred("_deferred_despawn")

		body.take_damage(10)
		if body.get_health_percentage() <= 0.0:
			body.health_depleted.emit()

func _on_explosion_timer_timeout() -> void:
	explode()

func explode() -> void:
	# Get texture from current sprite
	var texture_resource = sprite.texture

	# Load the base movable scene for spawned projectiles
	var movable_scene = preload("res://scenes/movable.tscn")

	# Calculate angle step for even distribution
	var angle_step = TAU / explosion_count  # TAU = 2*PI = 360 degrees

	# Spawn projectiles in all directions
	for i in range(explosion_count):
		var angle = i * angle_step
		var direction = Vector2(cos(angle), sin(angle))

		# Create new movable
		var new_movable = movable_scene.instantiate() as Movable

		# Spawn at current position with a slight random offset
		var spawn_offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		var spawn_position = self.position + spawn_offset

		# Use MovableManager to spawn without marker (instant spawn)
		MovableManager.spawn(new_movable, spawn_position, -1, false)

		# Setup with slightly reduced speed and scale
		var explosion_speed = projectile_speed * 0.8
		var explosion_scale = scale_factor * 0.75
		new_movable.setup(texture_resource, explosion_speed, direction * explosion_speed, explosion_scale)

	# Remove the original explosive movable
	call_deferred("_deferred_despawn")
