extends CharacterBody3D # 继承 CharacterBody3D 类
#class_name Player

var DELTA = get_physics_process_delta_time()
@onready var head = $Head
@onready var ray_cast_3d = $Head/Camera3D/RayCast3D
@onready var coyote_timer = $Timers/CoyoteTimer # 0.08
@onready var jump_request_timer = $Timers/JumpRequestTimer # 0.08
@export var CAMERA_CONTROLLER: Camera3D # 导出变量，可以在编辑器中设置摄像机控制器

# 跳跃
@export_category("Jump Parameters")
@export var Jump_Peak_Time: float = 0.75 # 跳跃峰值时间
@export var Jump_Fall_Time: float = 0.75 # 下落时间
@export var Jump_Height: float = 5.5 # 跳跃高度
@export var Jump_Distance_Min: float = 10.0 # 最小跳跃距离
@export var Jump_Distance_Max: float = 16.5 # 跳跃距离
var Jump_Distance: float
var Jump_Velocity: float
# 跳跃中
var Jumping: bool = false
var JumpingTimer: SceneTreeTimer
var JumpingHeight: float = 0.0
var JumpingHeight_Max: float = 0.0
var JumpingHeight_Temp: float = 0.0
# 空中
var Air_Speed: float
var Air_Acceleration: float # 空中加速度 60.0
var Air_ACC_Time: float = 0.1 # 空中加速度 60.0
var Air_ACC_Target: float # 目标空中加速度
var Gravity_Jump: float # 跳跃重力
var Gravity_Fall: float # 下降重力

# 地面移动
@export_category("Movement Parameters")
@export var Speed_Normal: float = 6.0
@export var Speed_Max: float = 10.0
@export var Acceleration_Normal_Time: float = 0.1
@export var Acceleration_Max_Time: float = 6.0
var Acceleration_Normal: float # 加速度
var Acceleration_Max: float # 加速度
# 方向向量
var Velocity2D: Vector2
var Velocity2D_Dir: Vector2
var Velocity2D_Speed: float
var Direction2D: Vector2 # horizontal

# 冲刺
@export_category("Dash Parameters")
@export var Dash_Distance: float = 6.0
@export var Dash_Time: float = 0.12
@onready var dash_timer := $Timers/DashTimer # 0.12
@onready var dash_cd_timer = $Timers/DashCDTimer # 0.2
@onready var dash_audio := $Audios/DashAudio
signal dash_start
const Dash_Number_Max:int = 1
var Dash_Number: int
var Dash_Speed: float # 冲刺速度
var is_dash: bool = false
# 冲刺类型
var dash2D: bool = false
var dash_dir2D: Vector2
var dash3D: bool = false
var dash_dir3D: Vector3

# 转身
@onready var turn_round_timer = $Timers/TurnRoundTimer # 0.8
var turn_round_rotation: float = 0.0
var is_turn_round: bool = false

# 子弹 武器
@export var ShootMarker3D: Marker3D
var Bullet = preload("res://weapons/bullet.tscn")
@onready var gun_audio_3d = $Audios/GunAudio3D

# 落地音效
@onready var fall_ground_audio_3d = $Audios/FallGroundAudio3D
var fall_ground:bool = false



func _ready(): # 节点准备好时执行
	Calculate_Movement_Parameters()


func _input(event):
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	if event.is_action_pressed("shoot_left"):
		var bullet = Bullet.instantiate()
		gun_audio_3d.play()
		ShootMarker3D.add_child(bullet)
		bullet.global_position = ShootMarker3D.global_position


func _process(_delta: float) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED: # 进入角色时绑定鼠标
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	DELTA = delta
	if Input.is_action_just_pressed("jump") and is_on_floor(): # debug数值
		JumpingHeight = 0
		JumpingHeight_Max = 0
		JumpingHeight_Temp = position.y

	if not (dash2D or dash3D):
		Turn_round()


	var was_on_floor = is_on_floor()
	Get_Direction2D_Velocity2D()
	if not (dash2D or dash3D):
		Movement()
		Air_and_Jump()
	Dash()


	velocity.x = Velocity2D.x
	velocity.z = Velocity2D.y

	move_and_slide() # 使用滑动移动方法应用速度和处理碰撞

	if is_on_floor() and not was_on_floor:
		#fall_ground_audio_3d.position.y = -30 + velocity.length()
		fall_ground_audio_3d.play()

	if was_on_floor and not Jumping:
		coyote_timer.start()


func Calculate_Movement_Parameters() -> void:
	Gravity_Jump = (2*Jump_Height)/ Jump_Peak_Time **2
	Gravity_Fall = (2*Jump_Height)/ Jump_Fall_Time **2
	Jump_Velocity = Gravity_Jump * Jump_Peak_Time
	Acceleration_Normal = Speed_Normal / Acceleration_Normal_Time
	Acceleration_Max = Speed_Max / Acceleration_Max_Time
	#Air_Speed = Jump_Distance_Min/ (Jump_Peak_Time+ Jump_Fall_Time)
	#Air_Acceleration = Air_Speed / Air_ACC_Time
	Dash_Speed = Dash_Distance / Dash_Time


func Calculate_Jump_Distance() -> void: # 动态计算跳跃距离
	Jump_Distance = Air_Speed * (Jump_Peak_Time + Jump_Fall_Time)
	if Velocity2D_Speed <= Speed_Normal:
		Jump_Distance = Jump_Distance_Min
	elif Input.is_action_pressed("move_forward"): # 速度大于Speed_Normal时，Jump_Distance随速度变化
		Jump_Distance = lerp(
			Jump_Distance_Min, Jump_Distance_Max,
			inverse_lerp(Speed_Normal, Speed_Max, Velocity2D_Speed))
	var new_air_speed: float = Jump_Distance/ (Jump_Peak_Time+ Jump_Fall_Time)
	if new_air_speed > Jump_Distance_Max:
		Air_Speed = Jump_Distance_Max + (new_air_speed - Jump_Distance_Max) * 0.255
	else:
		Air_Speed = new_air_speed
	Air_Speed = clamp(Air_Speed, 0.0, 12.0)
	Air_Acceleration = Air_Speed / Air_ACC_Time
	#print(Jump_Distance)


func Get_Direction2D_Velocity2D():
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward") # 获取输入方向
	var direction :=(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() # 计算移动方向
	Direction2D = Vector2(direction.x, direction.z) # 归一化的
	Velocity2D = Vector2(velocity.x, velocity.z) # 水平速度
	Velocity2D_Dir = Velocity2D.normalized()
	Velocity2D_Speed = Velocity2D.length()


func Movement():
	if Direction2D: # 如果有移动方向
		if is_on_floor(): #  有方向输入 地上
			if Velocity2D_Speed >= Speed_Normal - 0.01 and Input.is_action_pressed("move_forward"):
				Velocity2D_Dir = Velocity2D_Dir.lerp(Direction2D, Acceleration_Max *12* DELTA)
				if Velocity2D_Speed > Speed_Max:
					Velocity2D_Speed = move_toward(Velocity2D_Speed, Speed_Max, Acceleration_Max *3* DELTA)
				else:
					Velocity2D_Speed = move_toward(Velocity2D_Speed, Speed_Max, Acceleration_Max * DELTA)
				if is_equal_approx(Velocity2D_Speed, Speed_Max):
					Velocity2D_Speed = Speed_Max
				Velocity2D = Velocity2D_Dir * Velocity2D_Speed
			else:
				Velocity2D = Velocity2D.move_toward(Direction2D * Speed_Normal, Acceleration_Normal * DELTA)
		else: # 有方向输入 空中
			if Velocity2D_Speed < Air_Speed and Velocity2D_Speed < Speed_Max:
				Air_Acceleration = Velocity2D_Speed / Air_ACC_Time
			else:
				Air_Acceleration = Air_Speed / Air_ACC_Time
			Air_Acceleration = clamp(Air_Acceleration, 30, 200) # 为了优化贴墙对着墙跳前移动
			Air_ACC_Target = move_toward(Air_ACC_Target, Air_Acceleration, Air_Acceleration / 1.2 * DELTA)
			Velocity2D = Velocity2D.move_toward(Direction2D * Air_Speed, Air_ACC_Target * DELTA)
	if not Direction2D and is_on_floor(): # 无方向输入 地面
		Velocity2D = Velocity2D.move_toward(Vector2.ZERO, Velocity2D_Speed / 0.08 * DELTA) # 平面速度减速到0
		Air_ACC_Target = 0
	if not (Direction2D and is_on_floor()): # 无方向输入 空中
		Velocity2D = Velocity2D.move_toward(Vector2.ZERO, Velocity2D_Speed / 1.0 * DELTA) # 速度减速到0


func Air_and_Jump():
	# 添加重力效果
	if not is_on_floor(): # 如果不在地面上
		JumpingHeight = position.y - JumpingHeight_Temp # debug数值
		if Jumping:
			Air_ACC_Target = Air_Acceleration
			if JumpingHeight_Max < JumpingHeight:
				JumpingHeight_Max = JumpingHeight
			if velocity.y < 0: # 如果玩家正在正在下落
				Jumping = false
				velocity.y -= Gravity_Jump * DELTA # 应用正常的重力
			else:
				velocity.y -= Gravity_Jump * DELTA # 应用正常的重力
			if Input.is_action_just_released("jump") and velocity.y > Jump_Velocity / 2: # 如果玩家松开了跳跃键
				velocity.y = Jump_Velocity / 2
				Jumping = false
		else:
			velocity.y -= Gravity_Fall * DELTA # 应用重力
	elif is_on_floor() and Jumping:
		Jumping = false

	# 处理跳跃
	var can_jump = is_on_floor() or coyote_timer.time_left * velocity.length() / Speed_Normal > 0 # 地面上 威力狼跳
	if can_jump and jump_request_timer.time_left > 0: # 时间预输入 小跳有问题
		Jumping = true
		Calculate_Jump_Distance()
		velocity.y = Jump_Velocity # 设置跳跃速度
		jump_request_timer.stop()
		coyote_timer.stop()
		JumpingTimer = get_tree().create_timer(Jump_Peak_Time + Jump_Fall_Time, false, true, false) # debug


func Turn_round():
	if Input.is_action_just_pressed("turn_round") and turn_round_timer.time_left == 0:
		turn_round_timer.start()
		is_turn_round = true
	if is_turn_round:
		turn_round_rotation = lerp(turn_round_rotation, PI, PI*DELTA / 0.18)
		if is_equal_approx(turn_round_rotation, PI):
			turn_round_rotation = 0.0
			CAMERA_CONTROLLER._mouse_rotation.y += PI
			is_turn_round = false


func Dash():
	if Dash_Number != Dash_Number_Max and is_on_floor():
		Dash_Number = Dash_Number_Max

	if (dash2D or dash3D) and move_and_slide(): # 调整冲刺到墙壁的速度
		if get_slide_collision(0): # 检测是否冲刺到墙壁
			var wall_normal = get_slide_collision(0).get_normal()
			if wall_normal != Vector3.ZERO: # 如果冲刺到墙壁，减小速度
				var slide_speed_reduction = abs(velocity.dot(wall_normal))
				Dash_Speed = move_toward(Dash_Speed, 0, Velocity2D_Speed * slide_speed_reduction * DELTA)
				velocity.y = (velocity.normalized() * Speed_Normal).y

	var can_dash = dash_cd_timer.time_left == 0 and dash_timer.time_left == 0 and Dash_Number > 0
	if Input.is_action_just_pressed("shift") and can_dash:
		if Direction2D and not Input.is_action_pressed("move_forward"):
			dash2D = true
			dash_dir2D = Direction2D
		else:
			dash3D = true
			var CameraRot = CAMERA_CONTROLLER._mouse_rotation.x
			# var Face2Dlength = Vector2(CAMERA_CONTROLLER.Face_Direction.x, CAMERA_CONTROLLER.Face_Direction.z).length()
			if is_on_floor():
				if CameraRot < deg_to_rad(91) and CameraRot > deg_to_rad(67):
					dash_dir3D = Vector3(0, 1, 0)
				elif CameraRot < deg_to_rad(-70) and CameraRot > deg_to_rad(-91):
					dash_dir3D = Vector3(0, 0, 0)
				else:
					dash_dir3D = -transform.basis.z
			else:
				dash_dir3D = CAMERA_CONTROLLER.Face_Direction

		dash_start.emit()
		Dash_Speed = Dash_Distance / Dash_Time
		dash_timer.start()
		dash_cd_timer.start()
		Dash_Number -= 1
		dash_audio.play()
		safe_margin = 0.001
		FreezeTickManager.tick_freeze_short()

	if dash2D:
		Velocity2D = dash_dir2D * Dash_Speed
		velocity.y = 0
	if dash3D:
		var Vel3D = dash_dir3D.normalized() * Dash_Speed # Velocity3D
		Velocity2D = Vector2(Vel3D.x, Vel3D.z)
		velocity.y = Vel3D.y

	if dash2D or dash3D:
		var can_jump = is_on_floor() or coyote_timer.time_left * velocity.length() / Speed_Normal > 0 # 地面上 威力狼跳
		if can_jump and jump_request_timer.time_left > 0: # 时间预输入 小跳有问题
			velocity.y += Jump_Velocity
		if dash_timer.time_left == 0:
			if velocity.y >= -Dash_Speed*0.5: # 空中斜向下45不减速
				Velocity2D = Velocity2D.normalized() * Speed_Normal
				velocity.y = (velocity.normalized() * Speed_Normal).y
			dash2D = false
			dash3D = false
			safe_margin = 0.001





