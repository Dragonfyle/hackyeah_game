extends CharacterBody2D

signal movement_started
signal movement_stopped
signal health_changed(new_health: float)
signal health_depleted

@export var speed: float = 400.0
@export var accel: float = 1200.0        # how quickly we reach target speed (px/s^2)
@export var decel: float = 1500.0       # base deceleration when stopping (px/s^2)
@export var input_response: float = 0.08 # input smoothing time (seconds). Lower = snappier
@export var brake_distance: float = 120.0 # distance over which to brake to a stop (pixels)
@export var rotation_speed: float = 2.0 # higher = faster turning (used for smooth rotation)
@export var spin_in_place: bool = false  # gdy true -> ciągły obrót wokół osi
@export var spin_speed: float = 3.0      # radiany na sekundę, używane gdy spin_in_place = true

# System życia
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var collision_damage: float = 20.0  # obrażenia za kolizję z movable
@export var health_regen_rate: float = 5.0   # punkty życia odzyskiwane na sekundę gdy stoi
@export var health_display_speed: float = 2.0  # szybkość animacji wskaźnika życia

var _target_health_display: float = 0.0  # docelowy poziom wskaźnika
var _current_health_display: float = 0.0  # aktualny poziom wskaźnika

var _desired_input: Vector2 = Vector2.ZERO
var _smoothed_input: Vector2 = Vector2.ZERO
@export var min_step_pixels: float = 3.0 # ensure at least this many pixels movement when starting
var _was_moving: bool = false
var _last_collided_bodies: Array[RigidBody2D] = []

@onready var splash_sound: AudioStreamPlayer2D = $SplashSound

func _ready() -> void:
	current_health = max_health
	_target_health_display = 0.0  # 100% życia = 0.0 wskaźnika
	_current_health_display = 0.0
	update_health_display()

func _physics_process(delta: float) -> void:
	# Read raw input (left/right/up/down). Uses Godot's default ui_* actions.
	_desired_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Smooth input to simulate input/turning delay
	var t := 1.0
	if input_response > 0.0:
		t = clamp(delta / input_response, 0.0, 1.0)
	_smoothed_input = _smoothed_input.lerp(_desired_input, t)

	var desired_velocity: Vector2 = _smoothed_input * speed

	var is_moving_now: bool = _smoothed_input.length() > 0.01
	if is_moving_now:
		# accelerate toward desired velocity
		# if we just started moving (was stopped last frame), ensure a minimal step
		if not _was_moving and velocity.length() < 1.0 and min_step_pixels > 0.0:
			# required speed to move min_step_pixels this frame: v = d / dt
			var needed_speed: float = min_step_pixels / max(delta, 1e-6)
			if needed_speed > desired_velocity.length():
				# boost in direction of desired_velocity
				if desired_velocity.length() > 0.0:
					var boost_dir: Vector2 = desired_velocity.normalized()
					velocity = boost_dir * needed_speed
				else:
					# fallback: small step in previous velocity direction
					velocity = Vector2.RIGHT * needed_speed
			else:
				velocity = velocity.move_toward(desired_velocity, accel * delta)
		else:
			velocity = velocity.move_toward(desired_velocity, accel * delta)
	else:
		# no input -> brake over distance using physics formula to determine needed deceleration
		if brake_distance > 0.0 and velocity.length() > 0.01:
			var v_len: float = velocity.length()
			# deceleration needed to stop within brake_distance: a = v^2 / (2 * d)
			var decel_needed: float = (v_len * v_len) / (2.0 * brake_distance)
			var decel_to_apply: float = max(decel, decel_needed)
			velocity = velocity.move_toward(Vector2.ZERO, decel_to_apply * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, decel * delta)

	if velocity.length() > 1.0:
		# rotate to face movement direction (smooth)
		var target := velocity.angle()           # angle in radians
		rotation = lerp_angle(rotation, target, clamp(rotation_speed * delta, 0.0, 1.0))

	# If spin mode is enabled, override and spin around own axis
	if spin_in_place:
		rotation += spin_speed * delta

	# Move the character using the resolved velocity
	# CharacterBody2D.move_and_slide() uses the built-in `velocity` property internally
	move_and_slide()

	# Check for collisions with RigidBody2D
	var current_collided_bodies: Array[RigidBody2D] = []
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody2D:
			current_collided_bodies.append(collider)
			# Sprawdź czy to nowa kolizja z movable obiektem
			if collider is Movable and not _last_collided_bodies.has(collider):
				# Zadaj obrażenia za kolizję z movable
				take_damage(collision_damage)

	_last_collided_bodies = current_collided_bodies

	# Detect movement state transitions and emit signals
	if is_moving_now and not _was_moving:
		movement_started.emit()
	elif not is_moving_now and _was_moving:
		movement_stopped.emit()

	# update was_moving flag for next frame
	_was_moving = is_moving_now

	# Animate health display
	animate_health_display(delta)

func change_health(amount: float) -> void:
	var old_health = current_health
	current_health = clamp(current_health + amount, 0.0, max_health)
	
	if current_health != old_health:
		# Aktualizuj docelowy poziom wskaźnika
		var health_percentage = current_health / max_health
		_target_health_display = 1.0 - health_percentage  # 0% życia = 1.0 wskaźnika
		
		health_changed.emit(current_health)
		
		if current_health <= 0.0:
			health_depleted.emit()

func update_health_display() -> void:
	# Znajdź Sprite2D i jego material
	var sprite = $Sprite2D
	if sprite and sprite.material:
		# Ustaw parametr shadera na aktualny poziom wskaźnika
		sprite.material.set_shader_parameter("health_fill", _current_health_display)

func animate_health_display(delta: float) -> void:
	# Płynnie animuj wskaźnik życia do docelowego poziomu
	if _current_health_display != _target_health_display:
		_current_health_display = lerp(_current_health_display, _target_health_display, health_display_speed * delta)
		update_health_display()

func take_damage(amount: float) -> void:
	change_health(-amount)
	splash_sound.play()


func get_health_percentage() -> float:
	return current_health / max_health
