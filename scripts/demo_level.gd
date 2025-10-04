extends Node2D

const SCREEN_WIDTH = 1920
const SCREEN_HEIGHT = 1080
const WALL_MARGIN = 50  # Odległość od krawędzi gdzie spawnują się pociski

func _ready() -> void:
	print('Spawning projectile...')
	spawn_projectile_from_edge()

var types_of_projectiles: Array[Dictionary] = [
	{
		"texture": preload("res://icon.svg"),
		"speed": 700.0,
	},
	{
		"texture": preload("res://icon.svg"),
		"speed": 1000.0,
	},
]

func spawn_projectile(spawn_pos: Vector2, direction: Vector2) -> Movable:
	# Tworzenie nowego pocisku z parametrami konstruktora
	var texture_resource = types_of_projectiles[randi() % types_of_projectiles.size()]["texture"]
	var speed: float = types_of_projectiles[randi() % types_of_projectiles.size()]["speed"]
	var velocity: Vector2 = direction.normalized() * speed
	
	# Load and instantiate the flyable scene
	var flyable_scene = preload("res://scenes/movable.tscn")
	var pocisk = flyable_scene.instantiate() as Movable

	# Spawn pocisku przez FlyableManager (musi być przed setup)
	MovableManager.spawn(pocisk, spawn_pos)

	# Setup the projectile with parameters (po dodaniu do drzewa)
	pocisk.setup(texture_resource, speed, velocity)

	# Ustawienie kierunku (może być potrzebne do aktualizacji rotacji)
	pocisk.set_direction(direction)
	
	print("Active projectiles: ", MovableManager.get_active_count())
	
	return pocisk

# Spawn pocisku z losowej krawędzi ekranu, skierowanego do środka
func spawn_projectile_from_edge() -> Movable:
	var edge = randi() % 4  # 0=lewo, 1=prawo, 2=góra, 3=dół
	var spawn_pos: Vector2
	var direction: Vector2

	var center = Vector2(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)

	# match edge:
	# 	0:  # Lewa krawędź
	# 		spawn_pos = Vector2(WALL_MARGIN, randf() * SCREEN_HEIGHT)
	# 		direction = (center - spawn_pos).normalized()
	# 	1:  # Prawa krawędź
	# 		spawn_pos = Vector2(SCREEN_WIDTH - WALL_MARGIN, randf() * SCREEN_HEIGHT)
	# 		direction = (center - spawn_pos).normalized()
	# 	2:  # Górna krawędź
	# 		spawn_pos = Vector2(randf() * SCREEN_WIDTH, WALL_MARGIN)
	# 		direction = (center - spawn_pos).normalized()
	# 	3:  # Dolna krawędź
	# 		spawn_pos = Vector2(randf() * SCREEN_WIDTH, SCREEN_HEIGHT - WALL_MARGIN)
	# 		direction = (center - spawn_pos).normalized()

	print("Spawn position: ", spawn_pos)
	print("Direction: ", direction)

	direction = (center - Vector2(200, 200)).normalized()

	return spawn_projectile(Vector2(200, 200), direction)

# Przykład: spawn pocisku na kliknięcie
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		spawn_projectile_from_edge()
