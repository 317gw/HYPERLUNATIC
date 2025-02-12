class_name PlayerDash
extends State

signal dash_started

# 冲刺
@export_group("Dash Parameters")
@export var  dash_number_max: int = 1 # 冲刺次数
@export var dash_distance: float = 5.0
@export var dash_time: float = 0.16
# 冲刺跳跃
@export_group("Dash Jump Parameters")
@export var dashjump_height: float = 1.25 ## 冲刺跳跃高度
@export var dashjump_distance: float = 15.0 ## 冲刺跳跃距离

enum Dash_Type {DASH2D, DASH3D}
var dash_type = null

var dash_number: int
var dash_speed: float # 冲刺速度
var dash_dir3d: Vector3
var dashjump_time: float = 0.0 # 冲刺跳跃总时间
var dashjump_speed: float = 0.0 # 冲刺跳跃速度
var dashjump_vel: float = 0.0 # 冲刺跳跃速度
var dashjump_gravity: float = 0.0 # 冲刺跳跃重力
var is_vertical_dash: bool = false # 没用


@onready var PLAYER: HL.Player = $"../.."
@onready var camera: HL.Camera = $"../../Head/Camera3D"
#@onready var dash_jump: PlayerDashJump = $"../DashJump"

@onready var dash_timer: Timer = $"../../Timers/DashTimer" # 0.12
@onready var dash_cd_timer: Timer = $"../../Timers/DashCDTimer"
@onready var dash_jump_timer: Timer = $"../../Timers/DashJumpTimer"
@onready var dash_audio: AudioStreamPlayer = $"../../Audios/DashAudio"


func Enter():
	dash_started.emit()

	if Input.is_action_pressed("jump"):
		dash_type = Dash_Type.DASH3D
		#dash_on_air()
		dash_dir3d = Vector3(0, 1, 0)
		dash_ready()
		is_vertical_dash = false # 没用
		return

	if PLAYER.dir_hor and not Input.is_action_pressed("move_forward"):
		dash_type = Dash_Type.DASH2D
		dash_on_floor()
		# print("Dash2D")
	else:
		dash_type = Dash_Type.DASH3D
		dash_on_air()
		# print("Dash3D")
	dash_ready()


func Exit():
	PLAYER.safe_margin = PLAYER.SAFE_MARGIN # 碰撞优化


func Physics_Update(_delta: float) -> void:
	match dash_type:
		Dash_Type.DASH2D:
			dashing_on_floor()
		Dash_Type.DASH3D:
			dashing_on_air()
	
	dash_on_wall(_delta)
	dash_velocity_clamp()
	#reset_dash_number()

	PLAYER.apply_velocity(true, false)

	if dash_timer.time_left == 0:
		dash_out()
		if PLAYER.is_on_floor(): # 地面
			if PLAYER.dir_hor:
				Transitioned.emit(self, "Run")
				return
			else:
				Transitioned.emit(self, "Idle")
				return
		#elif PLAYER.is_swimming():
			#Transitioned.emit(self, "Swim")
			#return
		else:
			Transitioned.emit(self, "Fall")
			return

	if PLAYER.can_dash_jump():
		Transitioned.emit(self, "DashJump")
		return


func Handle_Input(_event: InputEvent) -> void:
	if _event.is_action_pressed("free_view_mode"):
		Transitioned.emit(self, "FreeViewMode")
		return




func _ready() -> void:
	dash_timer.wait_time = dash_time
	dash_number = dash_number_max


func dash_on_floor() -> void: # 冲刺启动
	dash_dir3d = PLAYER.dir_hor


func dash_on_air() -> void: # 调整冲刺方向
	dash_dir3d = camera._face_dir #-transform.basis.z # 视角滞后  不对
	if not PLAYER.is_on_floor():
		return

	var CameraRot = camera._mouse_rotation.x
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
	PLAYER.safe_margin = 0.025
	FreezeTickManager.tick_freeze_short()
	#camera.smooth_target_pos = Vector3.ZERO


func reset_dash_number() -> void: # 冲刺次数
	if dash_number != dash_number_max and PLAYER.is_on_floor():
		dash_number = dash_number_max


func dashing_on_floor() -> void:
	PLAYER.vel_hor = PLAYER.dir_hor * dash_speed
	PLAYER.vel_up = 0


func dashing_on_air() -> void:
	var vel3d = dash_dir3d * dash_speed # vel3d
	PLAYER.vel_hor = vel3d
	PLAYER.vel_up = vel3d.y


func dash_on_wall(delta: float) -> void: # 调整冲刺到墙壁的速度
	if not (PLAYER.is_on_wall() and PLAYER.get_last_slide_collision() ): # 检测是否冲刺到墙壁
		return

	var v: Vector3
	v.x = PLAYER.vel_hor.x
	v.z = PLAYER.vel_hor.y
	if Input.is_action_pressed("slow"):
		if PLAYER.push_rigidbody3D(v, PLAYER.push_power * 8, 1):
			return
	if PLAYER.push_rigidbody3D(v, PLAYER.push_power * 4):
		return

	var wall_normal = PLAYER.get_last_slide_collision().get_normal()
	# var angle = velocity.angle_to(wall_normal)
	if wall_normal != Vector3.ZERO and wall_normal != Vector3.UP: # 如果冲刺到墙壁，减小速度
		var slide_speed_reduction = dash_dir3d.normalized().dot(wall_normal) + 1
		slide_speed_reduction = clamp(slide_speed_reduction, 0, 1)
		dash_speed = move_toward(dash_speed, dash_speed * slide_speed_reduction, delta * 100)
		PLAYER.vel_up = (PLAYER.velocity.normalized() * PLAYER.speed_normal).y


func dash_velocity_clamp() -> void:
	PLAYER.velocity = PLAYER.velocity.normalized() * clamp(PLAYER.velocity.length(), 0.0, dash_speed)


func dash_out() -> void:
	#if velocity.y >= -dash_speed*0.5: # 空中斜向下45不减速
		#vel_hor = vel_hor.normalized() * speed_normal
		#velocity.y = (velocity.normalized() * speed_normal).y
		#print("空中斜向下45不减速")

	PLAYER.velocity = PLAYER.velocity.normalized() * clamp(PLAYER.velocity.length(), 0, PLAYER.speed_normal)
	dash_dir3d = Vector3.ZERO


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
	dashjump_gravity = PLAYER.gravity_fall * 1.5
	dashjump_vel = sqrt(2 * dashjump_height * dashjump_gravity)
	dashjump_speed = dashjump_vel * dashjump_distance / dashjump_height / 4
	dashjump_time = dashjump_distance / dashjump_speed

	# print("dashjump_time:", dashjump_time)
	# print("dashjump_speed:", dashjump_speed)
	# print("dashjump_gravity:", dashjump_gravity)
	# print("dashjump_vel:", dashjump_vel)


func vertical_dash() -> void: # 没用
	is_vertical_dash = true


# func Calculate_dashjump_distance() -> void: # 动态计算冲刺跳跃距离
# 	var new_dashjump_speed: float = dashjump_distance / (dashjump_Peak_time + dashjump_fall_time)
# 	if new_dashjump_speed > jump_distance_max:
# 		dashjump_vel = jump_distance_max + (new_dashjump_speed - jump_distance_max) * 0.255
# 	else:
# 		dashjump_vel = new_dashjump_speed
# 	dashjump_vel = clamp(dashjump_vel, 0.0, air_speed_max)
