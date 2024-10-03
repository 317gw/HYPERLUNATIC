extends CharacterBody3D
# https://github.com/kyrick/godot-boids

@export var max_speed: float = 2.0 # 最大速度
#@export var mouse_follow_force: = 0.05  # 鼠标跟随力
@export var cohesion_force: float = 0.5 # 凝聚力
@export var algin_force: float = 0.05 # 对齐力
@export var separation_force: float = 0.05 # 分离力
@export var view_distance: float = 100.0 # 视野距离
@export var avoid_distance: float = 20.0 # 避障距离

@export var health: float = 2.0 # 生命值

var _flock: Array = [CharacterBody3D] # 鸟群数组
var _velocity: Vector3 # 速度向量
var target_direction: Vector3
var state_machine: AnimationNodeStateMachinePlayback
var taking_damge: bool = false
var frame_skiper: FrameSkiper

@onready var view_radius = $FlockView/ViewRadius
@onready var animation_player = $"飞鱼2/AnimationPlayer"
@onready var animation_tree: AnimationTree = $AnimationTree


func _ready() -> void:
	randomize()

	frame_skiper = FrameSkiper.new()
	self.add_child(frame_skiper)
	frame_skiper.ready(30, 6)

	_velocity = Vector3(randf_range( - 1, 1), randf_range( - 1, 1), randf_range( - 1, 1)).normalized() * max_speed
	view_radius.shape.radius = view_distance
	_flock.clear()
	target_direction = global_position + _velocity
	state_machine = animation_tree["parameters/playback"]
	state_machine.start("Start", true)


func _on_flock_view_body_entered(body) -> void:
	if self != body and body is CharacterBody3D and body.is_in_group("FlyingFish"): # and body.collision_layer == 5
		_flock.append(body)


func _on_flock_view_body_exited(body) -> void:
	if body in _flock:
		_flock.remove_at(_flock.find(body))


func _physics_process(_delta: float) -> void:
	if frame_skiper.is_in_executable_frame():
		# 获取鸟群的凝聚、对齐和分离向量
		var vectors = get_flock_status(_flock)
		# 向这些向量转向
		var cohesion_vector = vectors[0] * cohesion_force
		var align_vector = vectors[1] * algin_force
		var separation_vector = vectors[2] * separation_force
		var acceleration = cohesion_vector + align_vector + separation_vector
		_velocity = (_velocity + acceleration).limit_length(max_speed)

	if is_on_floor() and _velocity.y < 0:
		_velocity.y = 0
	# 设置飞鱼的方向为速度的方向
	target_direction = target_direction.lerp(global_position + _velocity, 0.1)
	if transform.basis.y.dot(Vector3.UP) > 0.001 and velocity.length() > 0.01 and not self.global_position == target_direction:
		look_at(target_direction)
	if is_on_floor():
		rotation.x = lerp(rotation.x, get_floor_angle(), 0.1)
	velocity = _velocity
	#move_and_collide(velocity * delta)

	#velocity *= 0.95
	move_and_slide()

	_velocity = velocity
	#var velocity = get_velocity()
	#velocity = (velocity + acceleration).clamp(Vector3.ZERO, (velocity + acceleration).normalized() * max_speed)
	#set_velocity(velocity)
	#move_and_slide()
	# 移动速度管理动画速度
	animation_player.speed_scale = velocity.length() / max_speed


func get_flock_status(flock: Array):
	var center_vector := Vector3() # 中心向量
	var flock_center := Vector3() # 鸟群中心
	var align_vector := Vector3() # 对齐向量
	var avoid_vector := Vector3() # 避开向量
	for f: CharacterBody3D in flock:
		var neighbor_pos: Vector3 = f.global_position
		align_vector += f._velocity
		flock_center += neighbor_pos
		var d = global_position.distance_to(neighbor_pos)
		if d > 0 and d < avoid_distance:
			avoid_vector -= (neighbor_pos - global_position).normalized() * (avoid_distance / d * max_speed)
	var flock_size = flock.size()
	if flock_size:
		align_vector /= flock_size
		flock_center /= flock_size
		var center_dir = global_position.direction_to(flock_center)
		var center_speed = max_speed * (global_position.distance_to(flock_center) / $FlockView/ViewRadius.shape.radius)
		center_vector = center_dir * center_speed
	return [center_vector, align_vector, avoid_vector]


func get_random_target() -> void:
	randomize()
	var sice := 20.0
	return Vector3(randf_range( - sice, sice), randf_range( - sice, sice), randf_range(0.5, 2))


func be_hit(attack: Attack) -> void:
	health -= attack.damage
	if health <= 0:
		queue_free()
	taking_damge = true
	velocity += (global_position - attack.position).normalized() * attack.knockback_force
	#print("hit by bullet")
