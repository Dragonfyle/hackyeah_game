class_name SpawningMovable
extends Movable

## Time in seconds between spawning projectiles
@export var spawn_interval: float = 0.5
## Angle offset for spawned projectiles (in degrees)
@export var spawn_angle_degrees: float = 45.0
## Maximum number of bounces before despawning
@export var max_bounces: int = 5

var spawn_timer: Timer
var bounce_count: int = 0

func _ready() -> void:
	# Call parent _ready to set up velocity and signals
	super._ready()

	# Create and configure spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false  # Repeating timer
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()

## Override the collision handler to count bounces
func _on_body_entered(body: Node) -> void:
	# Handle player collision
	if body is CharacterBody2D:
		emit_signal("collision", body, body.global_position, Vector2.ZERO)
		call_deferred("_deferred_despawn")

		body.take_damage(10)
		if body.get_health_percentage() <= 0.0:
			body.health_depleted.emit()

	# Count wall bounces and despawn after max_bounces
	if body is StaticBody2D:
		bounce_count += 1
		if bounce_count >= max_bounces:
			call_deferred("_deferred_despawn")

func _on_spawn_timer_timeout() -> void:
	spawn_projectiles()

func spawn_projectiles() -> void:
	# Get texture from current sprite
	var texture_resource = sprite.texture

	# Load the base movable scene for spawned projectiles
	var movable_scene = preload("res://scenes/movable.tscn")

	# Get current velocity direction
	var current_direction = linear_velocity.normalized()
	var spawn_angle_rad = deg_to_rad(spawn_angle_degrees)

	# Spawn projectile at +45° angle
	var direction1 = current_direction.rotated(spawn_angle_rad)
	var new_movable1 = movable_scene.instantiate() as Movable
	var spawn_offset1 = direction1 * 20  # Spawn slightly ahead in that direction
	MovableManager.spawn(new_movable1, self.position + spawn_offset1, -1, false)
	var spawn_speed = projectile_speed * 0.7
	var spawn_scale = scale_factor * 0.6
	new_movable1.setup(texture_resource, spawn_speed, direction1 * spawn_speed, spawn_scale)

	# Spawn projectile at -45° angle
	var direction2 = current_direction.rotated(-spawn_angle_rad)
	var new_movable2 = movable_scene.instantiate() as Movable
	var spawn_offset2 = direction2 * 20  # Spawn slightly ahead in that direction
	MovableManager.spawn(new_movable2, self.position + spawn_offset2, -1, false)
	new_movable2.setup(texture_resource, spawn_speed, direction2 * spawn_speed, spawn_scale)
