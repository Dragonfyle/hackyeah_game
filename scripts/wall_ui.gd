extends StaticBody2D

@export var panel: NinePatchRect

func _ready() -> void:
	var col_shape := $CollisionShape2D
	if col_shape and col_shape.shape is RectangleShape2D and panel:
		var rect_shape := col_shape.shape as RectangleShape2D
		panel.size = rect_shape.extents * 2
		panel.position = Vector2.ZERO
