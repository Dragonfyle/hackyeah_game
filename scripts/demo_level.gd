extends Node2D

const PLAYABLE_WIDTH = 1936
const PLAYABLE_HEIGHT = 1024
const WALL_MARGIN = 100  # Odległość od krawędzi gdzie spawnują się pociski

func _ready() -> void:
	spawn_projectile_from_edge()

	var player = get_node("Player")
	if player:
		player.movement_stopped.connect(_on_player_stopped)
		player.movement_started.connect(_on_player_started)

	# Start with movables paused since player starts stopped
	MovableManager.pause_all()

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

func spawn_projectile(spawn_pos: Vector2, direction: Vector2, show_marker: bool = true) -> Movable:
	# Tworzenie nowego pocisku z parametrami konstruktora
	var texture_resource = types_of_projectiles[randi() % types_of_projectiles.size()]["texture"]
	var speed: float = types_of_projectiles[randi() % types_of_projectiles.size()]["speed"]
	var velocity: Vector2 = direction.normalized() * speed

	# Load and instantiate the flyable scene
	var flyable_scene = preload("res://scenes/movable.tscn")
	var pocisk = flyable_scene.instantiate() as Movable

	# Spawn pocisku przez FlyableManager (musi być przed setup)
	await MovableManager.spawn(pocisk, spawn_pos, -1, show_marker)

	# Setup the projectile with parameters (po dodaniu do drzewa)
	pocisk.setup(texture_resource, speed, velocity)

	# Ustawienie kierunku (może być potrzebne do aktualizacji rotacji)
	pocisk.set_direction(direction)

	return pocisk

# Spawn pocisku z losowej krawędzi ekranu, skierowanego do środka
func spawn_projectile_from_edge() -> Movable:
	var edge = randi() % 4  # 0=lewo, 1=prawo, 2=góra, 3=dół
	var spawn_pos: Vector2
	var direction: Vector2

	# Use camera viewport for spawning at visible edges
	var camera = $Camera2D
	var viewport_size = get_viewport_rect().size / camera.zoom
	var playable_center = Vector2(camera.position.x, camera.position.y)


	match edge:
		0:  # Lewa krawędź
			spawn_pos = Vector2(playable_center.x - viewport_size.x/2.0 + WALL_MARGIN, playable_center.y + randf_range(-viewport_size.y/2.0, viewport_size.y/2.0) + WALL_MARGIN)
			direction = (playable_center - spawn_pos).normalized()
		1:  # Prawa krawędź
			spawn_pos = Vector2(playable_center.x + viewport_size.x/2.0 - WALL_MARGIN, playable_center.y + randf_range(-viewport_size.y/2.0, viewport_size.y/2.0) + WALL_MARGIN)
			direction = (playable_center - spawn_pos).normalized()
		2:  # Górna krawędź
			spawn_pos = Vector2(playable_center.x + randf_range(-viewport_size.x/2.0, viewport_size.x/2.0) + WALL_MARGIN, playable_center.y + viewport_size.y/2.0 - WALL_MARGIN)
			direction = (playable_center - spawn_pos).normalized()
		3:  # Dolna krawędź
			spawn_pos = Vector2(playable_center.x + randf_range(-viewport_size.x/2.0, viewport_size.x/2.0) + WALL_MARGIN, playable_center.y - viewport_size.y/2.0 + WALL_MARGIN)
			direction = (playable_center - spawn_pos).normalized()

	return await spawn_projectile(spawn_pos, direction)

# Przykład: spawn pocisku na kliknięcie
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		spawn_projectile_from_edge()

func _on_player_stopped() -> void:
	MovableManager.pause_all()

func _on_player_started() -> void:
	MovableManager.resume_all()
