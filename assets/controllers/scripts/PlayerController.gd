#class_name Player
extends CharacterBody3D

#                                       @@      @ @      @@
#                                         @@  @     @  @@
#                                           @@       @@
#                                             @     @
#                                               @ @
#                                                @

#signal weapon_shoot(ray_cast_3d: RayCast3D)
signal weapon_main_action
signal weapon_sub_action
signal player_ready
signal physics_process
signal now_in_water
signal now_out_water

const SAFE_MARGIN = 0.001 # 碰撞安全距离
# # 子弹
# const BULLET = preload ("res://assets/weapons/bullet.tscn")
# const BULLET_DECAL = preload ("res://assets/weapons/bullet_decal.tscn")

#@export var CAMERA: HL.Camera
@export var ShootMarker3D: Marker3D ## 武器位置
@export var visible_range: float = 1000.0
@export var auxiliary_aiming_distance: float = 20.0
@export_range(0.0, 1.0, 0.01) var auxiliary_aiming_radius: float = 0.07
@export var mass: float = 60.0 # 2m->78kg  1.7m->60kg
@export var slow_rigid_force: float = 10.0
#@export var normal_max_current_speed: float = 40.0
# 地面移动
@export_group("Movement Parameters")
@export var speed_slow: float = 2.0
@export var speed_normal: float = 6.0
@export var speed_max: float = 10.0
#@export var speed_max1: float = 10.0
@export var acc_normal_t: float = 0.1 ## ACC -> Acceleration
@export var acc_max_t: float = 6.0
# 跳跃
@export_group("Jump Ready Parameters")
@export var jump_time: float = 1.5 ## 跳跃时间
@export var jump_height: float = 5.0 ## 跳跃高度
@export var mouse_wheel_jump_time: float = 0.82158383625774 ## 跳跃时间 = pow((new_height * jump_time ** 2)/jump_height, 0.5)
@export var mouse_wheel_jump_height: float = 1.5 ## 滚轮跳高度
@export var jump_distance_min: float = 10.0 ## 最小跳跃距离
@export var jump_distance_max: float = 16.5 ## 跳跃距离
# 空中
@export_group("Air Parameters")
@export var air_speed_max: float = 12.0
@export var normal_jump_air_speed_acc: float = 0.9 # 非常苛刻的预输入跳加速
@export_range(0.0, 1.0) var dashjump_air_acc_multi: float = 0.5
# 其他
@export_group("Other")
@export var push_power: float = 8
#@export var jerk_decelerate: float = 50
@export var acc_decelerate: float = 20

# 跳跃
var current_jump_time: float # 当前跳跃总时间
var jump_vel: float
var jump_distance: float
var jumpingtimer: SceneTreeTimer
# 跳跃高度debug
var jumping_height: float = 0.0
var jumping_height_max: float = 0.0
var jumping_height_temp: Vector3
# 空中
var air_speed: float = 0.0
var air_acc: float = 0.0 # 空中加速度 60.0
var air_acc_time: float = 0.08 # 空中加速度 
var air_acc_target: float = 0.0 # 目标空中加速度
var speed_temp: Vector3 # 速度暂存
var horizontal_acceleration: float = 0.0 # 实时水平加速度
var horizontal_speed_temp: float = 0.0 # 水平速度暂存
# 重力
var gravity_jump: float = 0.0 # 跳跃重力
var gravity_fall: float = 0.0 # 下降重力
# 加速度
var acc_normal: float
var acc_max: float
# 方向相关
var vel_up: float
var vel_hor: Vector3 # VEL -> Velocity  Horizontal  玩家视角水平速度
#var vel_hor_speed: float
var dir_hor: Vector3 # horizontal 玩家视角水平方向
var input_dir: Vector2
var input_up_down: float
var input_direction: Vector3
var velocity_last_frame: Vector3
var global_position_last_frame: Vector3
var look_at_target: Vector3
# 转身
var turn_round_rotation: float = 0.0
var is_turn_round: bool = false
# 落地音效
var landing: bool = false
# 挨打
var taking_damge: bool = false
var knockback_velocity: Vector3
# 额外减速
var decelerate: float # 百分比
var decelerate_list: Array[float] = []
# 台阶
var stairs_below_edge_colliding: bool = false
var stairs_below_edge_colliding_last_frame: bool = false
# 摩擦
var friction: float = 1.0
# 游泳
var water_meshs: Array = []
var water_density: float
var water_viscosity: float
var swim_speed: float = 6.0
# 其他
var acceleration: Vector3 # 实时的加速度，方便给外面调用
var max_current_speed_up: float
var max_current_speed_hor: float


# 身体
@onready var head: Node3D = $Head
@onready var camera: HL.Camera = $Head/Camera3D
@onready var hand: GrabFuction = $Head/Hand
@onready var player_transform_marker: Node3D = $PlayerTransformMarker
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
# 计时器
@onready var coyote_timer: Timer = $Timers/CoyoteTimer # 0.08
@onready var jump_request_timer: Timer = $Timers/JumpRequestTimer # 0.08
@onready var not_air_speed_clamp_timer: Timer = $Timers/NotAirSpeedClampTimer
@onready var turn_round_timer: Timer = $Timers/TurnRoundTimer # 0.8
# 冲刺
@onready var dash_timer: Timer = $Timers/DashTimer # 0.12
@onready var dash_cd_timer: Timer = $Timers/DashCDTimer # 0.2
@onready var dash_jump_timer: Timer = $Timers/DashJumpTimer
# 音效
@onready var dash_audio: AudioStreamPlayer = $Audios/DashAudio
@onready var gun_audio_3d: AudioStreamPlayer3D = $Audios/GunAudio3D
@onready var landing_audio_3d: AudioStreamPlayer3D = $Audios/LandingAudio3D
# 状态机
@onready var movement_state_machine: StateMachine = $MovementStateMachine
@onready var idle: PlayerIdle = $MovementStateMachine/Idle
@onready var run: PlayerRun = $MovementStateMachine/Run
@onready var jump: PlayerJump = $MovementStateMachine/Jump
@onready var fall: PlayerFall = $MovementStateMachine/Fall
@onready var swim: PlayerSwim = $MovementStateMachine/Swim
@onready var dash: PlayerDash = $MovementStateMachine/Dash
@onready var dash_jump: PlayerDashJump = $MovementStateMachine/DashJump
@onready var climb: PlayerClimb = $MovementStateMachine/Climb
@onready var free_view_mode: FreeViewMode = $MovementStateMachine/FreeViewMode
# 射击
#@onready var ray_cast_3d: RayCast3D = $Head/Rifle/低多边步枪/MuzzleMarker/RayCast3D
@onready var eye_ray_cast: RayCast3D = $Head/Camera3D/EyeRayCast
@onready var normal_target_marker: Marker3D = $Head/Camera3D/NormalTargetMarker
@onready var rifle: Node3D = $WeaponManager/Rifle
#@onready var eye_shape_cast: ShapeCast3D = $Head/Camera3D/EyeShapeCast
@onready var ui: CanvasLayer = $"../UI"
# 楼梯检测
@onready var snap_stairs: SnapStairs = $SnapStairs
# 其他
@onready var trail_3d: Node3D = $Trail3D
@onready var below_ray: RayCast3D = $BelowRay
@onready var physics_ticks_per_second = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")


func _ready() -> void:
	safe_margin = SAFE_MARGIN
	#player_rigid_body.mass = self.mass
	calculate_jump()
	await Global.global_scenes_ready
	Global.war_fog.tracked_object.append(self)


func _enter_tree() -> void:
	Global.main_player = self
	Global.main_player_ready.emit()


func _input(event) -> void:
	if event.is_action_pressed("jump"):
		jump.is_wheel_jump = false
		calculate_jump()
		jump_request_timer.start()
	if can_wheel_jump():
		jump.is_wheel_jump = true
		calculate_jump(mouse_wheel_jump_height, mouse_wheel_jump_time)
		jump_request_timer.start()
	if event.is_action_pressed("shoot_left") and not hand.picked_up:
		weapon_main_action.emit()
	if event.is_action_pressed("shoot_right") and not hand.picked_up:
		weapon_sub_action.emit()


func _process(_delta: float) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED: # 进入角色时绑定鼠标
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(_delta: float) -> void:
	look_at_target = eye_ray_cast.get_collision_point() if eye_ray_cast.is_colliding() else normal_target_marker.global_position
	trail_3d.process_mode = PROCESS_MODE_DISABLED if is_player_not_moving() else PROCESS_MODE_PAUSABLE

	# 预制方向和速度
	input_dir = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_backward") # 获取输入方向
	input_up_down = Input.get_axis(&"slow", &"jump")
	input_direction = (player_transform_marker.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() # 计算移动方向
	dir_hor = input_direction
	vel_up = velocity.dot(up_direction)
	vel_hor = velocity - up_direction * vel_up

	# 游泳参数
	water_density = 0
	water_viscosity = 0
	if water_meshs.size() > 0 and not can_dash_jump():
		for _water in water_meshs:
			water_density += _water.density
			water_viscosity += _water.viscosity
		water_density /= water_meshs.size()
		water_viscosity /= water_meshs.size()

		var _water_decelerate: float = clampf(
			remap(water_density, 0, 15000, 0, 1) + remap(water_viscosity, 0, 400, 0, 1)
			, 0, 0.9)
		decelerate_list.append(_water_decelerate)
		#decelerate_list.append(clampf(remap(velocity.length()**2, 0, 100, 0, 0.9), 0, 0.9) )
		

	# 限速
	max_current_speed_hor = remap(water_viscosity, 0.001, 400, 8, 1) if is_swimming() else 1000
	max_current_speed_hor = max(max_current_speed_hor, 1)
	max_current_speed_up = remap(water_viscosity, 0.001, 400, 4, 1) if is_swimming() else 1000
	max_current_speed_up = max(max_current_speed_up, 1)

	additional_slowdown(_delta)
	handle_friction()
	
	# 移动参数
	acc_normal = max(speed_normal / acc_normal_t * friction * decelerate, 0)
	acc_max = max(speed_max / acc_max_t * friction * decelerate, 0)
	dash.dash_speed = dash.dash_distance / dash.dash_time	

	_calculate_acceleration_in_physics_process(_delta)
	velocity_last_frame = velocity
	global_position_last_frame = global_position
	
	# 发送处理完信号
	physics_process.emit()


func apply_velocity(do_move_and_slide: bool = true, limit: bool = true) -> void:
	vel_hor = vel_hor - vel_hor.dot(up_direction) * up_direction
	if limit: # 速度的钳制
		var _acc: float = acc_decelerate * Global.get_delta_time() * (velocity.length() / 6) ** 2
		if vel_hor.length() > max_current_speed_hor:
			vel_hor = vel_hor.normalized() * move_toward(vel_hor.length(), max_current_speed_hor, _acc)
		if abs(vel_up) > max_current_speed_up:
			vel_up = sign(vel_up) * move_toward(abs(vel_up), max_current_speed_up, _acc)
	velocity = vel_hor + up_direction * vel_up

	if is_on_floor():
		snap_stairs.last_frame_was_on_floor = Engine.get_physics_frames()

	if do_move_and_slide:
		move_and_slide() # 使用滑动移动方法应用速度和处理碰撞

	if Input.is_action_pressed("slow"):
		push_rigidbody3D(velocity, push_power * 0.8, 1)
	else:
		push_rigidbody3D()


func calculate_jump(_height: float = jump_height, _time: float = jump_time) -> void: # 跳跃参数
	gravity_jump = (2 * _height) / pow(_time/2, 2)
	gravity_fall = (2 * _height) / pow(_time/2, 2)
	jump_vel = gravity_jump * _time/2
	current_jump_time = _time
	# dashjump_gravity_jump = (2 * dashjump_height) / pow(dashjump_Peak_time, 2)
	# dashjump_gravity_fall = (2 * dashjump_height) / pow(dashjump_fall_time, 2)
	# dashjump_vel = dashjump_gravity_jump * dashjump_Peak_time


func calculate_jump_distance() -> void: # 动态计算跳跃距离
	jump_distance = air_speed * current_jump_time
	if vel_hor.length() <= speed_normal:
		jump_distance = jump_distance_min
	elif Input.is_action_pressed("move_forward"): # 速度大于speed_normal时，jump_distance随速度变化
		jump_distance = lerp(
			jump_distance_min, jump_distance_max,
			inverse_lerp(speed_normal, speed_max, vel_hor.length()))


func calculate_air_speed(target_distance: float, target_time: float, is_normal_jump: bool = false) -> void: # 动态计算空中速度
	var new_air_speed: float = target_distance / target_time
	if not is_normal_jump:
		air_speed = new_air_speed
		return

	# 正常跳跃
	var normal_jump_air_speed_max = jump_distance_max / jump_time
	if new_air_speed > normal_jump_air_speed_max: # 限制最大空中速度
		air_speed = normal_jump_air_speed_max + (new_air_speed - normal_jump_air_speed_max) * normal_jump_air_speed_acc
	else:
		air_speed = new_air_speed
	air_acc = air_speed / air_acc_time


func air_speed_clamp(_delta) -> void:
	if air_speed > vel_hor.length() and horizontal_acceleration < 0:
		air_speed = lerp(air_speed, vel_hor.length(), 0.2)
	air_speed = clamp(air_speed, jump_distance_min / jump_time, max_current_speed_hor)


func movement_floor(delta: float) -> void: # 有方向输入 地上
	self.floor_stop_on_slope = false #  bugGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
	if Input.is_action_pressed("slow"):
		slow_movement_on_floor(delta)
		return
	stairs_below_edge_colliding = false

	if vel_hor.length() >= speed_normal - 0.005 and Input.is_action_pressed("move_forward") and decelerate > 0.999: # 加速跑
		var _ratio = 30 if vel_hor.length() > speed_max else 1 # 速度比例, 如果超速会快减速
		vel_hor = (HL.exponential_decay_vec3(vel_hor.normalized(), dir_hor, speed_max / acc_max_t * 0.1)
			* move_toward(vel_hor.length(), speed_max, acc_max * _ratio * delta))

	else:
		var _current_speed: float = max(speed_normal * decelerate, 1) # 最小速度
		vel_hor = vel_hor.move_toward(dir_hor * _current_speed, acc_normal * delta)



func movement_air(delta: float, is_dashjump: bool = false) -> void: # 有方向输入 空中
	if not dir_hor: # 无方向不移动
		return

	if vel_hor.length() < air_speed and vel_hor.length() < speed_max and not is_dashjump:
		air_acc = vel_hor.length() / air_acc_time
	else:
		air_acc = air_speed / air_acc_time
	if vel_hor.length() > air_speed_max:
		air_acc *= air_speed_max / vel_hor.length() / 4

	air_acc *= dashjump_air_acc_multi if is_dashjump else 1.0 # 减慢冲刺跳加速
	var air_acc_min = 20 if is_dashjump else 30
	air_acc = clamp(air_acc, air_acc_min, 200) # 为了优化贴墙对着墙跳前移动
	air_acc_target = move_toward(air_acc_target, air_acc, air_acc / 0.2 * delta)
	# 磕头跳加速
	if is_on_ceiling():
		var y = smoothstep(speed_normal, speed_max, air_speed)
		var head_butt_speed = 1
		air_speed += y * head_butt_speed
	# 应用
	#if is_swimming(): # 游泳
		#var face_dir: Vector3 = camera._face_dir * -input_dir.y + camera._face_dir.cross(Vector3.UP) * input_dir.x
		#var _dir_up: float = face_dir.dot(up_direction)
		#var _dir_hor: Vector3 = face_dir - up_direction * _dir_up
		#vel_up = move_toward(vel_up, _dir_up * air_speed * decelerate, air_acc_target * delta)
		#vel_hor = vel_hor.move_toward(_dir_hor * air_speed * decelerate, air_acc_target * delta)
	#else:
	vel_hor = vel_hor.move_toward(dir_hor * air_speed * decelerate, air_acc_target * delta)
	
	


func stop_movement(delta: float) -> void: # 地面&空中
	var t = acc_decelerate * friction * decelerate
	if is_on_floor():
		relative_movement_on_floor()
		if is_slow():
			t *= 2
		vel_hor = HL.exponential_decay(vel_hor.length(), 0, t * delta) * vel_hor.normalized()
	elif is_slow():
		vel_hor = HL.exponential_decay(vel_hor.length(), 0, t * delta) * vel_hor.normalized()

	#vel_up = move_toward(vel_up, 0.0, 1.2 * delta)


# 防止跳到移动物体上的滑步，移动时保证流畅不触发
func relative_movement_on_floor() -> void:
	if input_dir:
		return
	var slide_collision = below_ray.get_collider()
	if slide_collision is AnimatableBody3D or slide_collision is CharacterBody3D:
		velocity.x = 0
		velocity.z = 0
		vel_hor = Vector3.ZERO


func jump_ready(jumpVEL: float) -> void: # 处理跳跃
	vel_up += jumpVEL * decelerate # 设置跳跃速度
	prints(decelerate)
	jump_request_timer.stop()
	coyote_timer.stop()
	not_air_speed_clamp_timer.start()
	jumpingtimer = get_tree().create_timer(current_jump_time, false, true, false) # debug
	if is_on_floor() and below_ray.is_colliding():
		if below_ray.get_collider() is RigidBody3D:
			var collider: RigidBody3D = below_ray.get_collider()
			collider.apply_force(
				Global.gravity_vector * jump_distance_max / current_jump_time * (mass + collider.mass) * 1.5, 
				below_ray.get_collision_point() - collider.global_position)
	jumping_height_temp = global_position


func jumping_up() -> void: # 处理跳跃上升过程
	air_acc_target = air_acc


func jump_debug() -> void: # 跳跃debug
	jumping_height = up_direction.dot(global_position - jumping_height_temp) # 跳跃debug数值
	if jumping_height_max < jumping_height: # 跳跃debug数值
		jumping_height_max = jumping_height


# 添加重力
const default_gravity: float = 9.8
func apply_gravity(gravity: float, delta: float) -> void:
	var _ratio: float = get_gravity().dot(-up_direction) / default_gravity
	var g: float = gravity * (_ratio - remap(water_density, 0, 1600, 0, 1) * abs(_ratio)) # 后边浮力
	vel_up += g * delta


func swimming(delta: float) -> void:
	if is_swimming():
		vel_up += input_up_down * (swim_speed + get_gravity().dot(-up_direction)) * delta
		#vel_hor += dir_hor * swim_speed * delta


# 减速
func additional_slowdown(_delta: float) -> void:
	decelerate = 1
	for value in decelerate_list: # 列表给减速后清零
		decelerate -= value
	decelerate_list.clear()
	decelerate = clampf(decelerate, 0, 1)


# 摩擦力
func handle_friction() -> void:
	if not below_ray.is_colliding():
		return
	if not below_ray.get_collider():
		return
	if below_ray.get_collider().has_method("get_physics_material_override"):
		var obj = below_ray.get_collider()
		if obj.physics_material_override == null:
			return
		friction = obj.get_physics_material_override().friction
	else:
		friction = 1.0


# 玩家碰撞
func push_rigidbody3D(v: Vector3 = velocity, power: float = push_power, velocity_attenuation: float = 0.7, push_angle: float = 45) -> bool: # 0.7 is good
	var motion = v * Global.get_delta_time()
	for step in max_slides:
		var test: KinematicCollision3D = is_player_collision_into_rigidbody3D(motion, input_direction)
		if test == null:
			return false

		var RigidBody: RigidBody3D = test.get_collider()
		var push_velocity: float = max(mass/(mass+RigidBody.mass), 0.75) * v.length()

		var i_dir: Vector3 = -test.get_normal()
		var i_length: float = max(push_velocity, RigidBody.mass ** 0.82, 0) * power # 0.82 is good
		var apply_pos: Vector3 = test.get_position() - RigidBody.global_position

		# ↓对地面上推动物体的方向进行优化，最大额外向下30度推动，期望按倒地上不起跳
		if is_on_floor():
			var A = test.get_position()
			var B = RigidBody.global_position + RigidBody.center_of_mass
			var d: float = (B - A).dot(Global.gravity_vector) # 重心到碰撞点的差，带正负
			var angle: float = smoothstep(0, 1, d) * push_angle
			i_dir = i_dir.rotated(self.basis.x, deg_to_rad(-angle))
			#DebugDraw.draw_mesh_line(A, B, 5, Color.RED)
			var d2 = (test.get_position() - self.global_position).dot(Global.gravity_vector)
			apply_pos += Global.gravity_vector * smoothstep(0.85, -0.85, d2) * 0.1 # 身高1.7m

		var i: Vector3 = i_dir * i_length
		RigidBody.apply_force(i, apply_pos)
		#DebugDraw.draw_mesh_line_relative(test.get_position(), i, 5, Color.BLUE)

		velocity = velocity.lerp(v.limit_length(push_velocity), velocity_attenuation)
		#prints("push_velocity", push_velocity, "i_length", i_length, "mass/(mass+RigidBody.mass)", mass/(mass+RigidBody.mass))
	return true


# 碰到刚体
func is_player_collision_into_rigidbody3D(motion: Vector3, input_direction: Vector3) -> KinematicCollision3D:
	var collision: KinematicCollision3D = move_and_collide(motion, true)
	if not collision:
		#prints("1", motion)
		collision = move_and_collide(input_direction * 0.05, true)
		if not collision:
			#prints("2", motion.length())
			return null

	if not collision.get_collider() is RigidBody3D:
		return null

	return collision


# 上下台阶
func slow_movement_on_floor(delta: float) -> void:
	self.floor_stop_on_slope = true
	camera.slide_camera_smooth_back_to_origin_y_only = false
	camera.save_camera_pos_for_smoothing()

	var speed = 0.1 if stairs_below_edge_colliding_last_frame else 0.5 * acc_normal
	speed *= delta
	vel_hor = HL.exponential_decay(vel_hor.length(), speed_slow, speed) * dir_hor

	stairs_below_edge_colliding_last_frame = false

	# ↓ 边缘检测
	var current_position = self.global_position
	var next_position = current_position + Vector3(vel_hor.x, 0, vel_hor.y) * delta * 2
	# 检查下一个位置的地面高度
	snap_stairs.stairs_below_ray.global_position = next_position
	snap_stairs.stairs_below_ray.global_position.y = current_position.y
	snap_stairs.stairs_below_ray.force_update_transform()
	snap_stairs.stairs_below_ray.force_raycast_update()

	# 如果高度差大于射线预设，阻止玩家移动
	if not snap_stairs.stairs_below_ray.is_colliding():
		snap_stairs.stairs_below_edge_ray.global_position = current_position + Vector3(dir_hor.x, 0, dir_hor.y)
		snap_stairs.stairs_below_edge_ray.global_position.y = current_position.y - 0.05
		# 修复不同输入角度的射线角度
		snap_stairs.stairs_below_edge_ray.rotation.y = Vector3(camera._face_dir.x, 0, camera._face_dir.z).signed_angle_to(Vector3(input_direction.x, 0, input_direction.z), Vector3.UP)

		snap_stairs.stairs_below_edge_ray.force_update_transform()
		snap_stairs.stairs_below_edge_ray.force_raycast_update()

		if snap_stairs.stairs_below_edge_ray.is_colliding():
			var normalV2 = Vector2(snap_stairs.stairs_below_edge_ray.get_collision_normal().x, snap_stairs.stairs_below_edge_ray.get_collision_normal().z)
			var normal = snap_stairs.stairs_below_edge_ray.get_collision_normal()
			var taget_vel2d = vel_hor - normal * (1 + current_position.distance_to(snap_stairs.stairs_below_edge_ray.get_collision_point() ) * 3 )
			vel_hor = taget_vel2d
			stairs_below_edge_colliding_last_frame = true
		else:
			vel_hor = Vector3.ZERO

	stairs_below_edge_colliding = snap_stairs.stairs_below_edge_ray.is_colliding()
	# 还原位置
	if snap_stairs.stairs_below_ray.global_position != Vector3.ZERO:
		snap_stairs.stairs_below_ray.global_position = Vector3.ZERO
		snap_stairs.stairs_below_ray.force_update_transform()

	vel_hor = clamp(vel_hor.length(), 0, 2) * vel_hor.normalized()


# 实时计算加速度
func _calculate_acceleration_in_physics_process(delta: float) -> void:
	acceleration = velocity - speed_temp / delta
	speed_temp = velocity
	horizontal_acceleration = (Vector3(velocity.x, 0, velocity.z).length() - horizontal_speed_temp) / delta
	horizontal_speed_temp = Vector3(velocity.x, 0, velocity.z).length()


# 挨揍
func be_hit(attack: HL.Attack) -> void:
	#damaged(attack.damage)
	var force = attack.position.direction_to(global_position) * attack.knockback_force * attack.position.distance_to(global_position) / attack.radius
	knockback_velocity = force / mass
	velocity += knockback_velocity
	#taking_damge = true
	prints("player hit by", attack.source)


# 落地音效
func landing_sound_player() -> void:
	if is_on_floor():
		var volume: float = smoothstep(0.0, 3.0, velocity_last_frame.length() * -velocity_last_frame.dot(up_direction))
		landing_audio_3d.volume_db = remap(volume, 0, 1, -80, 0)
		landing_audio_3d.play()


# 简单越界传送
func _on_area_3d_body_entered(body: Node3D) -> void:
	if not body == self:
		return
	print("掉了")
	teleport()


func teleport(_pos: Vector3 = Vector3(0, 2, 0), _rota: Vector3 = Vector3.FORWARD) -> void:
	position = _pos
	#rotation = _rota
	air_speed = 0
	dir_hor = Vector3.ZERO
	vel_hor = Vector3.ZERO
	velocity = Vector3.ZERO
	#head.rotation = _rota
	#movement_state_machine.current_state.Transitioned.emit(self, "Idle")
	#player_rigid_body.global_position = self.global_position
	#player_rigid_body.integral = Vector3.ZERO


func get_centre_pos() -> Vector3:
	return collision_shape_3d.global_position


"""
下面都是bool bool bool
"""
func can_jump() -> bool: # 地面上 威力狼跳 时间预输入 小跳有问题
	return (
		is_on_floor()
		or coyote_timer.time_left * velocity.length() / speed_normal > 0
		or snap_stairs.snapped_to_stairs_last_frame
		) and jump_request_timer.time_left > 0

func can_dash() -> bool:
	return (
		dash_cd_timer.time_left == 0
		and dash_timer.time_left == 0
		and dash.dash_number > 0
		and Input.is_action_just_pressed("shift")
		)

func can_vertical_dash() -> bool: # 没用
	return Input.is_action_pressed("jump")

func can_dash_jump() -> bool: # can_dash_on_floor_jump
	return can_jump() and dash_jump_timer.time_left > 0

func can_wheel_jump() -> bool: 
	return Input.is_action_pressed("mouse_wheel_jump") and not hand.picked_up and not camera.is_zoom

func is_player_idle() -> bool:
	return movement_state_machine.current_state.name == "Idle"

func is_player_not_moving() -> bool:
	return velocity == Vector3.ZERO or global_position == global_position_last_frame

func is_in_air() -> bool:
	return (
		not movement_state_machine.current_state.name == "Idle"
		and not movement_state_machine.current_state.name == "Run"
		and not is_on_floor()
		and not is_swimming()
		)

func is_slow() -> bool:
	return (
		Input.is_action_pressed("slow")
		or (
			Input.is_action_pressed("slow_combo1")
			and Input.is_action_pressed("slow_combo2")
			)
		)

func is_swimming() -> bool:
	return not water_meshs.is_empty()

func is_stationary() -> bool:
	return velocity.is_zero_approx()
