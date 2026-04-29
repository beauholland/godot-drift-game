class_name PlayerCar
extends CharacterBody2D

signal drift_state_changed(is_drifting: bool)

@export var car_data: CarData

const STEER_SPEED_RAMP: float = 60.0
const ROLL_FRICTION: float = 0.6
const BRAKE_TO_REVERSE_RATIO: float = 0.5

var is_drifting: bool = false

@onready var body: Polygon2D = $Body
@onready var trim: Polygon2D = $Trim

func _ready() -> void:
	if car_data:
		_apply_car_data()

func setup(data: CarData) -> void:
	car_data = data
	if is_inside_tree():
		_apply_car_data()

func _apply_car_data() -> void:
	if body and car_data:
		body.color = car_data.color

func _physics_process(delta: float) -> void:
	if not car_data:
		return

	var input_throttle := Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	var input_steer := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var drift_held := Input.is_action_pressed("drift")

	var forward := Vector2.RIGHT.rotated(rotation)
	var right_vec := Vector2.DOWN.rotated(rotation)

	var forward_speed := velocity.dot(forward)
	var steer_factor: float = clamp(absf(forward_speed) / STEER_SPEED_RAMP, 0.0, 1.0)
	var steer_sign: float = signf(forward_speed) if absf(forward_speed) > 1.0 else 1.0
	rotation += input_steer * car_data.steering_speed * steer_factor * steer_sign * delta

	forward = Vector2.RIGHT.rotated(rotation)
	right_vec = Vector2.DOWN.rotated(rotation)

	if input_throttle > 0.0:
		velocity += forward * car_data.acceleration * input_throttle * delta
	elif input_throttle < 0.0:
		if forward_speed > 0.0:
			velocity += forward * (-car_data.brake_strength) * absf(input_throttle) * delta
		else:
			velocity += forward * car_data.acceleration * input_throttle * BRAKE_TO_REVERSE_RATIO * delta

	if velocity.length() > car_data.max_speed:
		velocity = velocity.normalized() * car_data.max_speed

	var fwd_vel: Vector2 = forward * velocity.dot(forward)
	var lat_vel: Vector2 = right_vec * velocity.dot(right_vec)

	var speed := velocity.length()
	var can_drift: bool = drift_held and speed > car_data.min_drift_speed
	var grip: float = car_data.drift_grip if can_drift else car_data.grip
	lat_vel *= 1.0 - clamp(grip * delta, 0.0, 1.0)

	if absf(input_throttle) < 0.01:
		fwd_vel *= 1.0 - clamp(ROLL_FRICTION * delta, 0.0, 1.0)

	velocity = fwd_vel + lat_vel

	move_and_slide()

	if can_drift != is_drifting:
		is_drifting = can_drift
		drift_state_changed.emit(is_drifting)

func get_speed() -> float:
	return velocity.length()

func get_slip_angle() -> float:
	if velocity.length() < 5.0:
		return 0.0
	var forward := Vector2.RIGHT.rotated(rotation)
	var vdir := velocity.normalized()
	return absf(forward.angle_to(vdir))
