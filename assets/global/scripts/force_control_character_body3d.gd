# ForceControlCharacterBody3D
# force_control_character_body3d
extends CharacterBody3D

enum DampMode {Inverse, ExponentInverse, Linear}

@export_range(0.001, 1000) var mass: float = 1.0 # kg
@export_range(-8, 8) var gravity_scale = 1.0
@export_range(0, 1) var friction: float = 1
@export var max_speed: float = 200.0 # 最大速度
@export var damp_mode: DampMode = DampMode.Inverse

var accelerations: Array[Vector3]
#var _velocity: Vector3 = Vector3.ZERO
var _force: Vector3 = Vector3.ZERO
var _impulse: Vector3 = Vector3.ZERO

var linear_damp: float = 0

var acceleration: Vector3
var velocity_temp: Vector3



func _physics_process(delta: float) -> void:
	_calculate_real_acceleration(delta)


func force_control_process(delta: float) -> void:
	var current_accelerations: Array[Vector3] = [
		Global.gravity * delta
		, _force / mass * delta
		, _impulse / mass
		, _friction(get_real_velocity(), delta)
		, acceleration * _damp() * delta * 0.005
		]
	current_accelerations.append_array(accelerations)
	
	velocity = calculate_velocity(velocity, current_accelerations)
	move_and_slide()
	
	_force = Vector3.ZERO
	_impulse = Vector3.ZERO


# using boids  ssssssss
func calculate_velocity(vel: Vector3, accelerations: Array) -> Vector3:
	if accelerations.is_empty():
		return vel
	
	var a: Vector3 = Vector3.ZERO
	for _a in accelerations:
		a += _a
	
	return (vel + a).limit_length(max_speed)


func apply_central_force(force: Vector3) -> void:
	_force = force


func apply_central_impulse(impulse: Vector3) -> void:
	_impulse = impulse


func _damp() -> float:
	var damp: float
	match damp_mode:
		DampMode.Inverse:
			damp = 1/(linear_damp + 1.0)
		DampMode.ExponentInverse:
			damp = 1/pow(HL.E, linear_damp)
		DampMode.Linear:
			damp = linear_damp/(2 * mass)
	return clampf(damp, 0, 1)
	#return 1


func _friction(vel: Vector3, delta: float) -> Vector3:
	if is_on_floor():
		return -vel * friction * delta
	return Vector3.ZERO


# 实时计算加速度
func _calculate_real_acceleration(delta: float) -> void:
	acceleration = velocity - velocity_temp / delta
	velocity_temp = velocity
