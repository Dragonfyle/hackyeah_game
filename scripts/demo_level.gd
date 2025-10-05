extends Node2D

## --- Constants ---
const PLAYABLE_WIDTH = 1936
const PLAYABLE_HEIGHT = 1024
const WALL_MARGIN = 100

## --- Exported Variables ---
@export_group("Spawning")
## The scene of the Movable object you want to spawn.
@export var movable_scene: PackedScene
## The rectangular area where objects can be spawned.
@export var spawn_area: Rect2 = Rect2(0, 0, 1920, 1080)
## The physics layer number for your walls.
@export_flags_2d_physics var wall_layer_mask

@export_group("Timing")
## The initial spawn interval (e.g., between 3 and 4 seconds).
@export var initial_interval: Vector2 = Vector2(3, 3.5)
## The fastest the spawn interval will become.
@export var final_interval: float = 1.0
## How many seconds until the spawning starts to speed up.
@export var time_to_start_speedup: float = 30.0
## How many seconds until the spawning reaches its maximum speed.
@export var time_to_reach_max_speed: float = 90.0

@export_group("Projectile Properties")
#var player = get_node("Player")


var types_of_projectiles: Array[Dictionary] = [
	{
		"texture": preload("res://assets/sperm_cell.png"),
		"speed": 700.0,
	},
	{
		"texture": preload("res://assets/sperm_cell.png"),
		"speed": 1000.0,
	},
]

## --- Node References ---
@onready var spawn_timer: Timer = $SpawnTimer
@onready var player = $Player # Assumes "Player" is a direct childsi

## --- Private Variables ---
var elapsed_time: float = 0.0
const MAX_ATTEMPTS = 100

## --- Godot Functions ---
func _ready() -> void:
	# Ensure the scene to spawn has been assigned in the Inspector.
	if not movable_scene:
		print("Movable scene is not set! Disabling spawner.")
		set_process(false)
		return

	# Connect signals from the player and timer.
	if player:
		player.movement_stopped.connect(_on_player_stopped)
		player.movement_started.connect(_on_player_started)
		player.health_depleted.connect(_on_player_death)

	# Start with movables slowed down since player starts stopped
	MovableManager.apply_slowdown_all()

	# Initialize score system - player starts idle
	ScoreManager.set_moving(false)

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	# Start the first spawn cycle immediately.
	_on_spawn_timer_timeout()

func _process(delta: float) -> void:
	# Keep track of the total elapsed time to control spawn speed.
	elapsed_time += delta

## --- Signal Handlers ---
func _on_spawn_timer_timeout() -> void:
	# 1. Decide how many movables to spawn in this wave (from 1 to 4).
	var spawn_count = randi_range(1, 4)
	
	# 2. Loop that many times to spawn each movable.
	for i in range(spawn_count):
		# Find a unique valid position for each new object.
		var spawn_pos = find_valid_spawn_position()
		
		if spawn_pos != Vector2.INF:
			# Determine the direction (e.g., towards the player).
			var direction = Vector2.RIGHT
			if player:
				direction = (player.global_position - spawn_pos).normalized()
			
			# Call your custom spawn function with the position and direction.
			spawn_projectile(spawn_pos, direction)
		else:
			print("Could not find a valid spawn position after %d attempts." % MAX_ATTEMPTS)
			# If one fails, stop this wave to avoid spamming errors if space is tight.
			break
			
	# 3. Calculate the wait time for the *next* wave and start the timer.
	var wait_time = _calculate_current_spawn_time()
	spawn_timer.wait_time = wait_time
	spawn_timer.start()

func _on_player_stopped() -> void:
	MovableManager.apply_slowdown_all()
	ScoreManager.set_moving(false)

func _on_player_started() -> void:
	MovableManager.remove_slowdown_all()

## --- Custom Functions ---
func spawn_projectile(spawn_pos: Vector2, direction: Vector2, show_marker: bool = true) -> void:
	# Pick random properties for the new projectile.
	var projectile_type = types_of_projectiles.pick_random()
	var texture_resource = projectile_type["texture"]
	var speed: float = projectile_type["speed"]
	var velocity: Vector2 = direction * speed

	# Instantiate the scene you assigned in the Inspector.
	var pocisk = movable_scene.instantiate() as Movable

	# Use your MovableManager to handle the spawn.
	await MovableManager.spawn(pocisk, spawn_pos, -1, show_marker)

	# Setup the projectile with its unique parameters.
	pocisk.setup(texture_resource, speed, velocity)
	pocisk.set_direction(direction)

## --- Helper Functions ---
func _calculate_current_spawn_time() -> float:
	if elapsed_time < time_to_start_speedup:
		return randf_range(initial_interval.x, initial_interval.y)
	else:
		var current_interval = remap(
			elapsed_time,
			time_to_start_speedup,
			time_to_reach_max_speed,
			initial_interval.y,
			final_interval
		)
		return max(current_interval, final_interval)

func find_valid_spawn_position() -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var attempts = 0
	while attempts < MAX_ATTEMPTS:
		attempts += 1
		var random_pos = Vector2(
			randf_range(spawn_area.position.x, spawn_area.end.x),
			randf_range(spawn_area.position.y, spawn_area.end.y)
		)
		var query = PhysicsPointQueryParameters2D.new()
		query.position = random_pos
		query.collision_mask = wall_layer_mask
		var result = space_state.intersect_point(query)
		if result.is_empty():
			return random_pos
	return Vector2.INF
	ScoreManager.set_moving(true)

func _on_player_death() -> void:
	var game_over = get_node("GameOver")
	if game_over:
		game_over.show_game_over(ScoreManager.get_score())
