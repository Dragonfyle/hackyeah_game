class_name Movable
extends RigidBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var projectile_speed: float
var projectile_velocity: Vector2
var scale_factor: float = 1.0  # Skala pocisku (zmniejsza się przy podziale)
var min_scale: float = 0.25  # Minimalna skala przed usunięciem

func setup(texture_resource: Texture2D, new_speed: float, new_velocity: Vector2, initial_scale: float = 1.0) -> void:
	self.scale_factor = initial_scale
	$Sprite2D.texture = texture_resource
	$Sprite2D.scale = Vector2(initial_scale, initial_scale)
	$CollisionShape2D.scale = Vector2(initial_scale, initial_scale)
	self.projectile_speed = new_speed
	self.projectile_velocity = new_velocity
	self.gravity_scale = 0.0

func _ready() -> void:
	if projectile_velocity != Vector2.ZERO:
		linear_velocity = self.projectile_velocity
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	print("Movable ready, collision monitoring: ", contact_monitor)

func set_direction(direction: Vector2) -> void:
	self.projectile_velocity = direction.normalized() * self.projectile_speed
	linear_velocity = self.projectile_velocity
	self.rotation = direction.angle()

func _on_body_entered(body: Node) -> void:
	print('body.name', body.name)	# Sprawdź czy to kolizja ze ścianą (StaticBody2D lub Area2D) i czy nie przetworzyliśmy już tej kolizji
	if body is StaticBody2D:
		print('body_name, split_projectile')
		split_projectile()


func split_projectile() -> void:
	if scale_factor <= min_scale:
		print("Too small, despawning instead of splitting")
		call_deferred("_deferred_despawn")
		return

	var new_scale = scale_factor * 0.75
	# Stwórz dwa nowe pociski w różnych kierunkach
	for i in range(2):
		var angle_offset = randf_range(-PI/3, PI/3) # Kąt odchylenia ±60° (π/3 radianów)
		var direction_angle = rotation + angle_offset
		var new_direction = Vector2(cos(direction_angle), sin(direction_angle))
		var new_velocity = new_direction * projectile_speed

		# Pobranie tekstury z aktualnego sprite'a
		var texture_resource = sprite.texture

		# Load scene
		var flyable_scene = preload("res://scenes/movable.tscn")
		var new_pocisk = flyable_scene.instantiate() as Movable

		var spawn_offset = new_direction * 20.0
		var spawn_position = self.position + spawn_offset
		MovableManager.spawn(new_pocisk, spawn_position)

		# Setup z nową skalą
		new_pocisk.setup(texture_resource, projectile_speed, new_velocity, new_scale)
		new_pocisk.set_direction(new_direction)

	# Usuń oryginalny pocisk
	call_deferred("_deferred_despawn")

func _deferred_despawn() -> void:
	MovableManager.despawn(self)
