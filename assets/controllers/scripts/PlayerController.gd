#class_name Player
extends CharacterBody3D

# @@      @ @      @@
#   @@  @     @  @@
#     @@       @@
#       @     @
#         @ @
#          @

#signal weapon_shoot(ray_cast_3d: RayCast3D)
signal weapon_main_action
signal weapon_sub_action

const SAFE_MARGIN = 0.001 # 碰撞安全距离
# # 子弹
# const BULLET = preload ("res://assets/weapons/bullet.tscn")
# const BULLET_DECAL = preload ("res://assets/weapons/bullet_decal.tscn")

@export var CAMERA: HL.Controller.Camera
@export var ShootMarker3D: Marker3D ## 武器位置
@export var visible_range: float = 1000.0
@export var auxiliary_aiming_distance: float = 20.0
@export_range(0.0, 1.0, 0.01) var auxiliary_aiming_radius: float = 0.07
@export var mass: float = 60.0 # 2m->78kg  1.7m->60kg
@export var slow_rigid_force: float = 10.0
@export var max_current_speed: float = 40.0
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
@export var jump_peak_time: float = 0.75 ## 跳跃峰值时间
@export var jump_fall_time: float = 0.75 ## 下落时间
@export var jump_height: float = 5.0 ## 跳跃高度
@export var jump_distance_min: float = 10.0 ## 最小跳跃距离
@export var jump_distance_max: float = 16.5 ## 跳跃距离
# 空中
@export_group("Air Parameters")
@export var air_speed_max: float = 12.0
@export var normal_jump_air_speed_acc: float = 0.9 # 非常苛刻的预输入跳加速
@export_range(0.0, 1.0) var dashjump_air_acc_multi: float = 0.5
# 冲刺
@export_group("Dash Parameters")
@export var  dash_number_max: int = 1 # 冲刺次数
@export var dash_distance: float = 5.0
@export var dash_time: float = 0.16
# 冲刺跳跃
@export_group("Dash jump_ready Parameters")
@export var dashjump_height: float = 1.25 ## 冲刺跳跃高度
@export var dashjump_distance: float = 15.0 ## 冲刺跳跃距离

@export var push_power: float = 9
@export var jerk_decelerate: float = 50

# 跳跃
var jump_time = jump_peak_time + jump_fall_time # 跳跃总时间
var jump_distance: float
var jump_vel: float
var jumpingtimer: SceneTreeTimer
# 跳跃高度debug
var jumping_height: float = 0.0
var jumping_height_max: float = 0.0
var jumping_height_temp: float = 0.0
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
var vel2d: Vector2 # VEL -> Velocity
var vel2d_speed: float
var input_dir: Vector2
var input_direction: Vector3
var dir2d: Vector2 # horizontal
var velocity_last_frame: Vector3
var global_position_last_frame: Vector3
# 冲刺
var dash_number: int
var dash_speed: float # 冲刺速度
var dash_dir2d: Vector2
var dash_dir3d: Vector3
var dashjump_time: float = 0.0 # 冲刺跳跃总时间
var dashjump_speed: float = 0.0 # 冲刺跳跃速度
var dashjump_vel: float = 0.0 # 冲刺跳跃速度
var dashjump_gravity: float = 0.0 # 冲刺跳跃重力
# 转身
var turn_round_rotation: float = 0.0
var is_turn_round: bool = false
# 落地音效
var landing: bool = false
# 挨打
var taking_damge: bool = false
var knockback_velocity: Vector3
# 额外减速
var acc_decelerate: float
# 台阶
var stairs_below_edge_colliding: bool = false
var stairs_below_edge_colliding_last_frame: bool = false
# 摩擦
var friction: float = 1.0
# 其他
var acceleration: Vector3 # 实时的加速度，方便给外面调用


# 身体
@onready var head: Node3D = $Head
@onready var camera: HL.Controller.Camera = $Head/Camera3D
@onready var hand: GrabFuction = $Head/Hand
@onready var player_transform_marker: Node3D = $PlayerTransformMarker
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var player_rigid_body: PlayerRigidBody3D = $PlayerRigidBody
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
@onready var movement_state_machine: StateMachine = $MovementStateMachine # 状态机
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

@onready var default_gravity: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity") * ProjectSettings.get_setting("physics/3d/default_gravity_vector")
@onready var physics_ticks_per_second = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")

func _ready() -> void:
	safe_margin = SAFE_MARGIN
	dash_timer.wait_time = dash_time
	dash_number = dash_number_max
	player_rigid_body.mass = self.mass


func _input(event) -> void:
	#if Input.is_action_just_released("free_view_mode"):
		#movement_state_machine.current_state.Transitioned.emit(movement_state_machine.current_state, "FreeViewMode")
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	if event.is_action_pressed("mouse_wheel_jump") and not hand.picked_up and not camera.is_zoom:
		jump_request_timer.start()
	if event.is_action_pressed("shoot_left") and not hand.picked_up:
		#weapon_shoot.emit()
		weapon_main_action.emit()


func _process(_delta: float) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED: # 进入角色时绑定鼠标
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(_delta: float) -> void:
	trail_3d.process_mode = PROCESS_MODE_DISABLED if is_player_not_moving() else PROCESS_MODE_PAUSABLE
	get_DIR2D_VEL2D()

	additional_slowdown()
	handle_friction()
	calculate_movement_parameters()
	calculate_jump_parameters()

	calculate_acceleration_in_physics_process(_delta)
	velocity_last_frame = velocity
	global_position_last_frame = global_position

	#if is_slow(): # 低速模式加重
		#player_rigid_body.mass = self.mass * slow_rigid_force
		#player_rigid_body.k_amend = slow_rigid_force
	#elif player_rigid_body.mass != self.mass or player_rigid_body.k_amend != 1:
		#player_rigid_body.mass = self.mass
		#player_rigid_body.k_amend = 1


func apply_velocity(do_move_and_slide: bool = true) -> void:
	#additional_slowdown()

	velocity.x = vel2d.x
	velocity.z = vel2d.y
	velocity = velocity.normalized() * clamp(velocity.length(), 0.0, max_current_speed) # 临时的钳制，没有考虑垂直和水平

	if is_on_floor():
		snap_stairs.last_frame_was_on_floor = Engine.get_physics_frames()

	if do_move_and_slide:
		move_and_slide() # 使用滑动移动方法应用速度和处理碰撞

	if Input.is_action_pressed("slow"):
		push_rigidbody3D(velocity, push_power * 0.5, 1)
	else:
		push_rigidbody3D()


#玩家碰撞
func push_rigidbody3D(v: Vector3 = velocity, power: float = push_power, velocity_attenuation: float = 0.7, push_angle: float = 45) -> bool: # 0.7 is good
	var motion = v * Global.get_delta_time()
	for step in max_slides:
		var test: KinematicCollision3D = is_player_collision_into_rigidbody3D(motion, input_direction)
		if test == null:
			return false

		var RigidBody: RigidBody3D = test.get_collider()
		var push_velocity: float = max(mass/(mass+RigidBody.mass), 0.75) * v.length()

		var i_dir: Vector3 = -test.get_normal()
		var i_length: float = max(push_velocity, RigidBody.mass ** 0.82, 0) * power * Global.get_delta_time() # 0.82 is good
		var apply_pos: Vector3 = test.get_position() - RigidBody.global_position

		# ↓对地面上推动物体的方向进行优化，最大额外向下30度推动，期望按倒地上不起跳
		if is_on_floor():
			var A = test.get_position()
			var B = RigidBody.global_position + RigidBody.center_of_mass
			var d: float = (B - A).dot(default_gravity.normalized()) # 重心到碰撞点的差，带正负
			var angle: float = smoothstep(0, 1, d) * push_angle
			i_dir = i_dir.rotated(self.basis.x, deg_to_rad(-angle))
			#DebugDraw.draw_mesh_line(A, B, 5, Color.RED)
			var d2 = (test.get_position() - self.global_position).dot(default_gravity.normalized())
			apply_pos += default_gravity.normalized() * smoothstep(0.85, -0.85, d2) * 0.1 # 身高1.7m

		var i: Vector3 = i_dir * i_length
		RigidBody.apply_impulse(i, apply_pos)
		#DebugDraw.draw_mesh_line_relative(test.get_position(), i, 5, Color.BLUE)

		velocity = velocity.lerp(v.limit_length(push_velocity), velocity_attenuation)
		vel2d_speed = velocity.length()
		#prints("push_velocity", push_velocity, "i_length", i_length, "mass/(mass+RigidBody.mass)", mass/(mass+RigidBody.mass))
	return true


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


func additional_slowdown() -> void:
	if is_zero_approx(acc_decelerate):
		acc_decelerate = 0
		return
	#velocity = velocity.normalized() * move_toward(velocity.length(), 0, acc_decelerate * Global.get_delta_time())
	#vel2d_speed = move_toward(vel2d_speed, 0, acc_decelerate * Global.get_delta_time())
	#vel2d = vel2d.normalized() * move_toward(vel2d.length(), 0, acc_decelerate * Global.get_delta_time())
	acc_decelerate = move_toward(acc_decelerate, 0, jerk_decelerate * Global.get_delta_time())


func handle_friction() -> void:
	if not below_ray.is_colliding():
		return
	if below_ray.get_collider().has_method("get_physics_material_override"):
		var obj = below_ray.get_collider()
		if obj.physics_material_override == null:
			return
		friction = obj.get_physics_material_override().friction
	else:
		friction = 1.0



func calculate_movement_parameters() -> void:
	acc_normal = max(speed_normal / acc_normal_t * friction - acc_decelerate * 0.5, 0)
	acc_max = max(speed_max / acc_max_t * friction - acc_decelerate, 0)
	dash_speed = dash_distance / dash_time


func calculate_jump_parameters() -> void:
	gravity_jump = (2 * jump_height) / pow(jump_peak_time, 2)
	gravity_fall = (2 * jump_height) / pow(jump_fall_time, 2)
	jump_vel = gravity_jump * jump_peak_time
	# dashjump_gravity_jump = (2 * dashjump_height) / pow(dashjump_Peak_time, 2)
	# dashjump_gravity_fall = (2 * dashjump_height) / pow(dashjump_fall_time, 2)
	# dashjump_vel = dashjump_gravity_jump * dashjump_Peak_time


func calculate_jump_distance() -> void: # 动态计算跳跃距离
	jump_distance = air_speed * jump_time
	if vel2d_speed <= speed_normal:
		jump_distance = jump_distance_min
	elif Input.is_action_pressed("move_forward"): # 速度大于speed_normal时，jump_distance随速度变化
		jump_distance = lerp(
			jump_distance_min, jump_distance_max,
			inverse_lerp(speed_normal, speed_max, vel2d_speed))


func calculate_air_speed(target_distance: float, target_time: float, is_normal_jump: bool=false) -> void: # 动态计算空中速度
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
	if air_speed > vel2d_speed and horizontal_acceleration < 0:
		air_speed = lerp(air_speed, vel2d_speed, 0.2)
	air_speed = clamp(air_speed, jump_distance_min / jump_time, max_current_speed)


# func Calculate_dashjump_distance() -> void: # 动态计算冲刺跳跃距离
# 	var new_dashjump_speed: float = dashjump_distance / (dashjump_Peak_time + dashjump_fall_time)
# 	if new_dashjump_speed > jump_distance_max:
# 		dashjump_vel = jump_distance_max + (new_dashjump_speed - jump_distance_max) * 0.255
# 	else:
# 		dashjump_vel = new_dashjump_speed
# 	dashjump_vel = clamp(dashjump_vel, 0.0, air_speed_max)


func get_DIR2D_VEL2D():
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward") # 获取输入方向
	input_direction = (player_transform_marker.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() # 计算移动方向
	dir2d = Vector2(input_direction.x, input_direction.z) # 归一化的
	vel2d = Vector2(velocity.x, velocity.z) # 水平速度
	vel2d_speed = vel2d.length()


func movement_floor(delta: float) -> void: # 有方向输入 地上
	self.floor_stop_on_slope = false #  bugGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
	if Input.is_action_pressed("slow"):
		slow_movement_on_floor(delta)
		return
	stairs_below_edge_colliding = false


	if vel2d_speed >= speed_normal - 0.005 and Input.is_action_pressed("move_forward"): # 加速跑
		var ratio = 30 if vel2d_speed > speed_max else 1 # 速度比例, 如果超速会快减速
		vel2d_speed = move_toward(vel2d_speed, speed_max, acc_max * ratio * delta)
		vel2d = vel2d_speed * Global.exponential_decay_vec2(vel2d.normalized(), dir2d, speed_max / acc_max_t * 0.1)

	else:
		var _current_speed: float = max(speed_normal - acc_decelerate * delta, 0)
		vel2d = vel2d.move_toward(dir2d * _current_speed, acc_normal * delta)
		vel2d_speed = vel2d.length()



func movement_air(delta: float, is_dashjump: bool = false) -> void: # 有方向输入 空中
	if not dir2d:
		return

	if vel2d_speed < air_speed and vel2d_speed < speed_max and not is_dashjump:
		air_acc = vel2d_speed / air_acc_time
	else:
		air_acc = air_speed / air_acc_time
	if vel2d_speed > air_speed_max:
		air_acc = air_acc * air_speed_max / vel2d_speed / 4

	air_acc *= dashjump_air_acc_multi if is_dashjump else 1.0 # 减慢冲刺跳加速
	var air_acc_min = 20 if is_dashjump else 30
	air_acc = clamp(air_acc, air_acc_min, 200) # 为了优化贴墙对着墙跳前移动
	air_acc_target = move_toward(air_acc_target, air_acc, air_acc / 0.2 * delta)

	if is_on_ceiling(): # 磕头跳加速
		var y = smoothstep((speed_max+speed_normal)/2, speed_max, air_speed)
		var head_butt_speed = 0.5
		air_speed += y * head_butt_speed
	vel2d = vel2d.move_toward(dir2d * air_speed, air_acc_target * delta)


func stop_movement(delta: float) -> void:
	var t = 20 * friction # 地面&空中
	if is_on_floor():
		relative_movement_on_floor()
		if is_slow():
			t *= 2
		vel2d = Global.exponential_decay(vel2d.length(), 0, t * delta) * vel2d.normalized()

	if not is_on_floor() and is_slow():
		vel2d = Global.exponential_decay(vel2d.length(), 0, t * delta) * vel2d.normalized()

	#velocity.y = move_toward(velocity.y, 0.0, 1.2 * delta)


# 防止跳到移动物体上的滑步，移动时保证流畅不触发
func relative_movement_on_floor() -> void:
	if input_dir:
		return
	var slide_collision = below_ray.get_collider()
	if slide_collision is AnimatableBody3D or slide_collision is CharacterBody3D:
		velocity.x = 0
		velocity.z = 0
		vel2d = Vector2.ZERO


func jump_ready(jumpVEL: float) -> void: # 处理跳跃
	velocity.y += jumpVEL # 设置跳跃速度
	jump_request_timer.stop()
	coyote_timer.stop()
	not_air_speed_clamp_timer.start()
	jumpingtimer = get_tree().create_timer(jump_peak_time + jump_fall_time, false, true, false) # debug


func apply_gravity(gravity: float, delta: float) -> void: # 添加重力效果
	if get_gravity() == default_gravity:
		velocity.y -= gravity * delta # 应用重力
	else:
		velocity += get_gravity() * delta
	#print(get_gravity())


func jumping_up() -> void: # 处理跳跃上升过程
	air_acc_target = air_acc


func jump_debug() -> void: # 跳跃debug
	jumping_height = position.y - jumping_height_temp # 跳跃debug数值
	if jumping_height_max < jumping_height: # 跳跃debug数值
		jumping_height_max = jumping_height


func dash_on_floor() -> void: # 冲刺启动
	dash_dir2d = dir2d
	dash_dir3d = Vector3(dir2d.x, 0, dir2d.y)


func dash_on_air() -> void: # 调整冲刺方向
	dash_dir3d = CAMERA._face_dir #-transform.basis.z # 视角滞后  不对
	if not is_on_floor():
		return

	var CameraRot = CAMERA._mouse_rotation.x
	if CameraRot < deg_to_rad(91) and CameraRot > deg_to_rad(67): # 动鼠标垂直冲刺的优化？
		dash_dir3d = Vector3(0, 1, 0)
	elif CameraRot < deg_to_rad( - 70) and CameraRot > deg_to_rad( - 91):
		dash_dir3d = Vector3(0, 0, 0)


func dash_ready() -> void:
	dash_speed = dash_distance / dash_time
	dash_timer.wait_time = dash_time
	dash_timer.start()
	dash_cd_timer.start()
	dash_jump_timer.start()
	dash_number -= 1
	dash_audio.play()
	safe_margin = 0.025
	FreezeTickManager.tick_freeze_short()
	#camera.smooth_target_pos = Vector3.ZERO


# 冲刺次数
func reset_dash_number() -> void:
	if dash_number != dash_number_max and is_on_floor():
		dash_number = dash_number_max


# 2
func dashing_on_floor() -> void:
	vel2d = dash_dir2d * dash_speed
	velocity.y = 0


# 3s
func dashing_on_air() -> void:
	var vel3d = dash_dir3d * dash_speed # vel3d
	vel2d = Vector2(vel3d.x, vel3d.z)
	velocity.y = vel3d.y


# 4
func dash_on_wall(delta: float) -> void: # 调整冲刺到墙壁的速度
	if not (is_on_wall() and get_last_slide_collision() ): # 检测是否冲刺到墙壁
		return

	var v: Vector3
	v.x = vel2d.x
	v.z = vel2d.y
	if Input.is_action_pressed("slow"):
		if push_rigidbody3D(v, push_power * 3, 1):
			return
	if push_rigidbody3D(v):
		return

	var wall_normal = get_last_slide_collision().get_normal()
	# var angle = velocity.angle_to(wall_normal)
	if wall_normal != Vector3.ZERO and wall_normal != Vector3.UP: # 如果冲刺到墙壁，减小速度
		var slide_speed_reduction = dash_dir3d.normalized().dot(wall_normal) + 1
		slide_speed_reduction = clamp(slide_speed_reduction, 0, 1)
		dash_speed = move_toward(dash_speed, dash_speed * slide_speed_reduction, delta * 100)
		velocity.y = (velocity.normalized() * speed_normal).y


# 5
func dash_velocity_clamp() -> void:
	velocity = velocity.normalized() * clamp(velocity.length(), 0.0, dash_speed)


# 6
func dash_out() -> void:
	#if velocity.y >= -dash_speed*0.5: # 空中斜向下45不减速
		#vel2d = vel2d.normalized() * speed_normal
		#velocity.y = (velocity.normalized() * speed_normal).y
		#print("空中斜向下45不减速")
	#else :
		#print("asd")

	velocity = velocity.normalized() * clamp(velocity.length(), 0, speed_normal)
	dash_dir3d = Vector3.ZERO
	safe_margin = SAFE_MARGIN # 碰撞优化


func calculate_dashjump_parameters() -> void:
	# 根据高度和距离,锁定dash_speed
	# dashjump_time = dashjump_distance / dash_speed
	# dashjump_vel = 4 * dashjump_height / dashjump_time
	# dashjump_gravity = 2 * dashjump_vel / dashjump_time
	# dashjump_speed = dash_speed

	# 根据距离,锁定dash_speed和dashjump_gravity
	# dashjump_time = dashjump_distance / dash_speed
	# dashjump_gravity = gravity_fall * 1.5
	# dashjump_vel = dashjump_gravity * dashjump_time / 2
	# dashjump_speed = dash_speed

	# 根据高度和距离,锁定dashjump_gravity
	dashjump_gravity = gravity_fall * 1.5
	dashjump_vel = sqrt(2 * dashjump_height * dashjump_gravity)
	dashjump_speed = dashjump_vel * dashjump_distance / dashjump_height / 4
	dashjump_time = dashjump_distance / dashjump_speed

	# print("dashjump_time:", dashjump_time)
	# print("dashjump_speed:", dashjump_speed)
	# print("dashjump_gravity:", dashjump_gravity)
	# print("dashjump_vel:", dashjump_vel)


# 实时计算加速度
func calculate_acceleration_in_physics_process(delta: float) -> void:
	acceleration = velocity - speed_temp / delta
	speed_temp = velocity
	horizontal_acceleration = (Vector3(velocity.x, 0, velocity.z).length() - horizontal_speed_temp) / delta
	horizontal_speed_temp = Vector3(velocity.x, 0, velocity.z).length()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not body == self:
		return

	print("掉了")
	position = Vector3(0, 2, 0)
	air_speed = 0
	dir2d = Vector2.ZERO
	vel2d = Vector2.ZERO
	velocity = Vector3.ZERO
	#movement_state_machine.current_state.Transitioned.emit(self, "Idle")
	rotation = Vector3.FORWARD
	head.rotation = Vector3.FORWARD
	player_rigid_body.global_position = self.global_position
	player_rigid_body.integral = Vector3.ZERO

	#camera._player_rotation = Vector3.FORWARD
	#camera._camera_rotation = Vector3.FORWARD
	#camera._mouse_rotation = Vector3.FORWARD
	#camera.face_DIR = Vector3.FORWARD
	#camera.target_player_rotation = Vector3.FORWARD
	#camera.player_rotation_speed =0


#func damaged(damage: float) -> void:
	#health -= damage
	#if health <= 0:
		#var expl = EXPLODE.instantiate()
		#expl.global_position = global_position
		#expl.explode(explode_damage, explode_radius, explode_force)
		#expl.died_time = 0.4
		#get_node("/root/TestMap").add_child(expl)
		#queue_free()
	#taking_damge = true


func be_hit(attack: HL.Attack) -> void:
	#damaged(attack.damage)
	var force = attack.position.direction_to(global_position) * attack.knockback_force * attack.position.distance_to(global_position) / attack.radius
	knockback_velocity = force / mass
	velocity += knockback_velocity
	#taking_damge = true
	prints("player hit by", attack.source)


func landing_sound_player() -> void:
	if is_on_floor():
		var volume: float = smoothstep(0.0, 3.0, velocity_last_frame.length() * -velocity_last_frame.dot(up_direction))
		landing_audio_3d.volume_db = remap(volume, 0, 1, -80, 0)
		landing_audio_3d.play()


 # Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
func free_view_move(delta: float) -> void:
	if not is_instance_valid(camera):
		print("Camera is not valid.")
		return
	var face_dir = camera._face_dir * -input_dir.y + camera._face_dir.cross(Vector3.UP) * input_dir.x
	var up_down: Vector3 = Vector3(0, int(Input.is_action_pressed("jump")) - int(Input.is_action_pressed("slow")), 0)
	var speed: float = speed_max if Input.is_action_pressed("shift") else speed_normal
	velocity = (face_dir + up_down).normalized() * speed * 2
	self.global_position += velocity * delta


func slow_movement_on_floor(delta: float) -> void:
	self.floor_stop_on_slope = true
	camera.slide_camera_smooth_back_to_origin_y_only = false
	camera.save_camera_pos_for_smoothing()

	var speed = 0.1 if stairs_below_edge_colliding_last_frame else 0.5 * acc_normal
	speed *= delta
	vel2d = Global.exponential_decay(vel2d.length(), speed_slow, speed) * dir2d

	stairs_below_edge_colliding_last_frame = false

	# ↓ 边缘检测
	var current_position = self.global_position
	var next_position = current_position + Vector3(vel2d.x, 0, vel2d.y) * delta * 2
	# 检查下一个位置的地面高度
	snap_stairs.stairs_below_ray.global_position = next_position
	snap_stairs.stairs_below_ray.global_position.y = current_position.y
	snap_stairs.stairs_below_ray.force_update_transform()
	snap_stairs.stairs_below_ray.force_raycast_update()

	# 如果高度差大于射线预设，阻止玩家移动
	if not snap_stairs.stairs_below_ray.is_colliding():
		snap_stairs.stairs_below_edge_ray.global_position = current_position + Vector3(dir2d.x, 0, dir2d.y)
		snap_stairs.stairs_below_edge_ray.global_position.y = current_position.y - 0.05
		# 修复不同输入角度的射线角度
		snap_stairs.stairs_below_edge_ray.rotation.y = Vector3(camera._face_dir.x, 0, camera._face_dir.z).signed_angle_to(Vector3(input_direction.x, 0, input_direction.z), Vector3.UP)

		snap_stairs.stairs_below_edge_ray.force_update_transform()
		snap_stairs.stairs_below_edge_ray.force_raycast_update()

		if snap_stairs.stairs_below_edge_ray.is_colliding():
			var normalV2 = Vector2(snap_stairs.stairs_below_edge_ray.get_collision_normal().x, snap_stairs.stairs_below_edge_ray.get_collision_normal().z)
			var taget_vel2d = vel2d - normalV2 * (1 + current_position.distance_to(snap_stairs.stairs_below_edge_ray.get_collision_point() ) * 3 )
			vel2d = taget_vel2d
			stairs_below_edge_colliding_last_frame = true
		else:
			vel2d = Vector2.ZERO

	stairs_below_edge_colliding = snap_stairs.stairs_below_edge_ray.is_colliding()
	# 还原位置
	if snap_stairs.stairs_below_ray.global_position != Vector3.ZERO:
		snap_stairs.stairs_below_ray.global_position = Vector3.ZERO
		snap_stairs.stairs_below_ray.force_update_transform()

	vel2d = clamp(vel2d.length(), 0, 2) * vel2d.normalized()



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
		and dash_number > 0
		and Input.is_action_just_pressed("shift")
		)


func can_vertical_dash() -> bool: # 没用
	return Input.is_action_pressed("jump")


func can_dash_jump() -> bool: # can_dash_on_floor_jump
	return can_jump() and dash_jump_timer.time_left > 0


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
	return false
