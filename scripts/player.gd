extends CharacterBody2D

@export var speed: float = 400.0
@export var accel: float = 1200.0        # how quickly we reach target speed (px/s^2)
@export var decel: float = 1500.0       # base deceleration when stopping (px/s^2)
@export var input_response: float = 0.08 # input smoothing time (seconds). Lower = snappier
@export var brake_distance: float = 120.0 # distance over which to brake to a stop (pixels)

var _desired_input: Vector2 = Vector2.ZERO
var _smoothed_input: Vector2 = Vector2.ZERO
@export var min_step_pixels: float = 3.0 # ensure at least this many pixels movement when starting
var _was_moving: bool = false

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

	# Move the character using the resolved velocity
	# CharacterBody2D.move_and_slide() uses the built-in `velocity` property internally
	move_and_slide()

	# update was_moving flag for next frame
	_was_moving = is_moving_now
	
