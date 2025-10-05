class_name OrbitingMovable
extends Movable

## Distance satellites orbit from center
@export var orbit_radius: float = 150.0
## Angular velocity for orbital rotation (radians per second)
@export var orbit_speed: float = 2.0
## Time in seconds between spawning new satellites
@export var spawn_interval: float = 1.0

var spawn_timer: Timer
var satellites: Array[Node2D] = []
var orbit_angle: float = 0.0

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

func _process(delta: float) -> void:
	# Update orbit angle
	orbit_angle += orbit_speed * delta

	# Update all satellite positions
	for i in range(satellites.size()):
		if is_instance_valid(satellites[i]):
			# Distribute satellites evenly around the orbit
			var angle_offset = (TAU / max(satellites.size(), 1)) * i
			var satellite_angle = orbit_angle + angle_offset
			var offset = Vector2(cos(satellite_angle), sin(satellite_angle)) * orbit_radius
			satellites[i].position = offset

func _on_spawn_timer_timeout() -> void:
	spawn_satellite()

func spawn_satellite() -> void:
	# Load the satellite scene
	var satellite_scene = preload("res://scenes/orbiting_satellite.tscn")
	var satellite = satellite_scene.instantiate()

	# Add as child so it moves with the parent
	add_child(satellite)
	satellites.append(satellite)

	# Connect collision signal to handle player damage
	if satellite is Area2D:
		satellite.body_entered.connect(_on_satellite_body_entered.bind(satellite))

func _on_satellite_body_entered(body: Node, satellite: Node2D) -> void:
	# Damage player on satellite collision
	if body is CharacterBody2D:
		body.take_damage(10)
		if body.get_health_percentage() <= 0.0:
			body.health_depleted.emit()

		# Remove the satellite that hit the player
		if satellite in satellites:
			satellites.erase(satellite)
		if is_instance_valid(satellite):
			satellite.queue_free()

func _deferred_despawn() -> void:
	# Clean up all satellites
	for satellite in satellites:
		if is_instance_valid(satellite):
			satellite.queue_free()
	satellites.clear()

	# Call parent despawn
	super._deferred_despawn()
