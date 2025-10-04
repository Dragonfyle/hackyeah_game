class_name Flyable
extends Sprite2D

var speed: float
var velocity: Vector2

func _init(texture_resource: Texture2D, speed: float, velocity: Vector2) -> void:
	self.texture = texture_resource
	self.speed = speed
	self.velocity = velocity

func _ready() -> void:
	print("Flyable created at position: ", position)

func _process(delta: float) -> void:
	# Ruch pocisku
	position += self.velocity * delta


func set_direction(direction: Vector2) -> void:
	self.velocity = direction.normalized() * self.speed
	self.rotation = direction.angle()
