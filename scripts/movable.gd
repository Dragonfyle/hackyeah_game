class_name Movable
extends RigidBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var projectile_speed: float
var projectile_velocity: Vector2
var scale_factor: float = 2.0  # Skala pocisku (zmniejsza się przy podziale)
var min_scale: float = 0.5  # Minimalna skala przed usunięciem
var _stored_velocity: Vector2 = Vector2.ZERO  # For pause/resume

func setup(texture_resource: Texture2D, new_speed: float, new_velocity: Vector2, initial_scale: float = 2.0) -> void:
	self.scale_factor = initial_scale
	$Sprite2D.texture = texture_resource
	$Sprite2D.scale = Vector2(initial_scale, initial_scale)
	$CollisionShape2D.scale = Vector2(initial_scale, initial_scale)
	self.projectile_speed = new_speed
	self.projectile_velocity = new_velocity
	self.gravity_scale = 0.0
	self.linear_damp = 0.0

	# Rotate the sprite to match the velocity direction
	if new_velocity.length() > 0.0:
		rotation = new_velocity.angle() + 135
	# Debug log

func _ready() -> void:
	if projectile_velocity != Vector2.ZERO:
		linear_velocity = self.projectile_velocity
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func set_direction(direction: Vector2) -> void:
	self.projectile_velocity = direction.normalized() * self.projectile_speed
	linear_velocity = self.projectile_velocity
	self.rotation = direction.angle()
	rotation = direction.angle()

func _on_body_entered(body: Node) -> void:
	if body is StaticBody2D:
		split_projectile()
	if body is CharacterBody2D:
		emit_signal("collision", body, body.global_position, Vector2.ZERO)
		call_deferred("_deferred_despawn")

		body.take_damage(10)
		if body.get_health_percentage() <= 0.0:
			body.health_depleted.emit()


func split_projectile() -> void:
	if scale_factor <= min_scale:
		call_deferred("_deferred_despawn")
		return

	var new_scale = scale_factor * 0.75
	# Pobranie tekstury z aktualnego sprite'a
	var texture_resource = sprite.texture
	
	# Load scene
	var flyable_scene = preload("res://scenes/movable.tscn")
	
	# Pierwszy pocisk - lekko w lewo
	var new_pocisk1 = flyable_scene.instantiate() as Movable
	var direction1 = projectile_velocity.rotated(-self.rotation + randf_range(-PI/4, -PI/8))  # -45° to -22.5°
	var spawn_position1 = self.position
	MovableManager.spawn(new_pocisk1, spawn_position1, -1, false)  # No marker for splits
	new_pocisk1.setup(texture_resource, projectile_speed, direction1, new_scale)
	# Set correct rotation for the sprite to match direction

	# Drugi pocisk - lekko w prawo
	var new_pocisk2 = flyable_scene.instantiate() as Movable
	var direction2 = projectile_velocity.rotated(-self.rotation + randf_range(-PI/4, -PI/8))  # 22.5° to 45°
	var spawn_offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
	var spawn_position2 = self.position + spawn_offset
	MovableManager.spawn(new_pocisk2, spawn_position2, -1, false)  # No marker for splits
	new_pocisk2.setup(texture_resource, projectile_speed, direction2, new_scale)
	# Set correct rotation for the sprite to match direction

	# Usuń oryginalny pocisk
	call_deferred("_deferred_despawn")

func _deferred_despawn() -> void:
	MovableManager.despawn(self)

func apply_slowdown() -> void:
	_stored_velocity = linear_velocity
	linear_velocity = linear_velocity * 0.07

func remove_slowdown() -> void:
	linear_velocity = _stored_velocity
