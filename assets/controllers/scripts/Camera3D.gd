#class_name PlayerCamera
extends Camera3D

const TILT_LOWER_LIMIT := deg_to_rad(-89.7) # 将下倾限制转换为弧度
const TILT_UPPER_LIMIT := deg_to_rad( 89.7) # 将上倾限制转换为弧度
# 视角摇晃 bob variables
const BOB_FREQ: float = 1.8 # 频率
const BOB_AMP: float = 0.03 # 振幅
# fov变化
const FOV_CHANGE: float = 1.5

# 左右歪头
@export var MOUSE_SENSITIVITY: float = 0.35 # 导出变量，可以在编辑器中设置鼠标灵敏度
@export var PLAYER: HL.Controller.Player
@export var tilt_head_to_body_angle: float = 10.0
@export var tilt_head_to_body_clamp: float = 75.0
@export_range(0, 180) var tilt_angle: float = 1.0
@export_range(0, 1) var lr_tilt_speed: float = 1.0
@export_range(0, 1) var player_rotation_smooth: float = 0.05
@export var tilt_target_angle_multiply : float = 0.5

@export_group("FOV&Zoom")
@export var fov_base: float = 75.0
@export var fov_zoom: float = 10.0
@export var fov_clamp_max: float = 1.2
@export_range(0, 1) var fov_sensitivity : float = 0.1
@export_range(0, 1) var fov_lerp_speed: float = 0.2
@export var camera_extension: float = 5.0



var look_back_rotation: float = 0.0 # 回头
var up_down_rotation: float = 0.0 # 抬头和低头
var fov_air_chang: float # fov变化
# 左右歪头
var target_tilt: float
var lr_tilt: int
var left_right_tilt_desh: int
var targetZ: float
# 自瞄
var aiming_aidable_objects: Array = [CharacterBody3D]
var enemy_area_body: Array = [CharacterBody3D]
var enemy_area_radius: float
var ui: CanvasLayer
# FOV & Zoom  缩放
var is_zoom: bool = false
var fov_lerp: float = 0.7
# 摄像机位置调整
var head_pos_original: Vector3
var head_bob_pos: Vector3
var stair_smooth_pos: Vector3

var _mouse_input: bool = false # 私有变量，用于判断是否有鼠标输入
var _rotation_input: float # 私有变量，用于存储旋转输入
var _tilt_input: float # 私有变量，用于存储倾斜输入

# 实时变化的
var sensitivity: float #实际的鼠标灵敏度
var player_rotation_speed: float # 玩家旋转速度
var player_rotation_temp: float # 玩家旋转速度临时变量
var bob_time: float # 视角摇晃 bob variables
var mouse_tilt_angle: float
var tilt_target_angle: float
var _mouse_rotation: Vector3 # 私有变量，用于存储鼠标旋转值
var _face_dir: Vector3 # 面对方向
var _player_rotation: Vector3 # 私有变量，用于存储玩家旋转值
var _camera_rotation: Vector3 # 私有变量，用于存储摄像机旋转值


#var previous_position: Vector3 = Vector3.ZERO
#var position_change_threshold: float = 0.1  # 你可以根据实际情况调整这个阈值

@onready var player: HL.Controller.Player = $"../.."
@onready var head: Node3D = $".."
@onready var camera_smooth: Node3D = $".."
@onready var hand: GrabFuction = $"../Hand"
@onready var player_transform_marker: Node3D = $"../../PlayerTransformMarker"
@onready var turn_round: CameraTurnRound = $"../../CameraStateMachine/TurnRound"
# 获取状态机
@onready var movement_state_machine: StateMachine = $"../../MovementStateMachine"
@onready var camera_state_machine: StateMachine = $"../../CameraStateMachine"
# 瞄准
@onready var eye_ray_cast: RayCast3D = $EyeRayCast
@onready var eye_area: Area3D = $EyeArea
@onready var eye_area_collision_shape: CollisionShape3D = $EyeArea/EyeAreaCollisionShape
@onready var normal_target_marker: Marker3D = $NormalTargetMarker
@onready var auxiliary_end_marker: Marker3D = $AuxiliaryEndMarker
@onready var cylinder_xx: MeshInstance3D = $EyeArea/CylinderXX
@onready var auxiliary_aiming_ball: MeshInstance3D = $AuxiliaryAimingBall


func _ready() -> void: # 节点准备好时执行
	await owner.ready
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # 捕获鼠标
	ui = PLAYER.ui
	# 初始化瞄准参数
	eye_ray_cast.target_position.z = -PLAYER.visible_range
	normal_target_marker.position.z = -PLAYER.visible_range
	var edge: Vector3 = project_position(Vector2(get_viewport().get_size().x / 2, 0), PLAYER.auxiliary_aiming_distance)
	auxiliary_end_marker.position.z = -PLAYER.auxiliary_aiming_distance
	# 距离设置
	enemy_area_radius = auxiliary_end_marker.position.distance_to(edge)
	eye_area_collision_shape.shape.radius = enemy_area_radius
	eye_area_collision_shape.shape.height = PLAYER.auxiliary_aiming_distance
	eye_area_collision_shape.position.z = -PLAYER.auxiliary_aiming_distance / 2
	cylinder_xx.mesh.top_radius = enemy_area_radius
	cylinder_xx.mesh.bottom_radius = enemy_area_radius
	cylinder_xx.mesh.height = PLAYER.auxiliary_aiming_distance
	cylinder_xx.position.y = -PLAYER.auxiliary_aiming_distance / 2
	enemy_area_body.clear()
	aiming_aidable_objects.clear()
	head_pos_original = head.position
	# 初始化摄像旋转
	_mouse_rotation = self.global_rotation
	_camera_rotation = self.global_rotation
	_player_rotation = player.global_rotation
	player_transform_marker.global_rotation = _player_rotation
	auxiliary_aiming_ball.position = Vector3.ZERO
	head.global_rotation = _player_rotation
	#transform_marker


func _unhandled_input(event: InputEvent) -> void: # 处理未处理的输入事件
	# 判断是否为鼠标移动事件且鼠标模式为捕获模式
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		var mouse_motion: InputEventMouseMotion = event
		sensitivity = MOUSE_SENSITIVITY
		if is_zoom:
			sensitivity *= lerp(fov_base, fov_zoom, fov_lerp) / fov_base
		_rotation_input = -mouse_motion.screen_relative.x * sensitivity # 计算旋转输入
		_tilt_input = -mouse_motion.screen_relative.y * sensitivity # 计算倾斜输入
	if event.is_action_pressed("zoom") and not hand.picked_up:
		is_zoom = !is_zoom
		fov_lerp = 0.7
	if is_zoom:
		fov_lerp_change()


func _physics_process(delta: float) -> void:
	_face_dir = -global_transform.basis.z
	tilt_head_to_body(delta)
	if not hand.view_lock:
		_update_camera(delta) # 根据鼠标移动更新摄像机位置
	calculate_player_rotation_speed(delta)

	# Head bob
	if PLAYER.velocity.length() < 1 or not PLAYER.is_on_floor() or movement_state_machine.current_state is PlayerDash:
		head_bob_pos = head_bob_pos.lerp(Vector3.ZERO, 0.08)
	else:
		bob_time += delta * PLAYER.velocity.length() * float(PLAYER.is_on_floor())
		head_bob_pos = head_bob_pos.lerp(headbob(bob_time), 0.2)
	position = position.lerp(head_bob_pos, 0.5)


	slide_camera_smooth_back_to_origin(delta, slide_camera_smooth_back_to_origin_y_only)
	if saved_camera_global_pos == null:
		head.position = head_pos_original
	position.z = 0

	fov_change(delta)
	tilt_head(delta) # 问题
	aiming_aidable_objects_in_out()
	auxiliary_aiming()

	#var current_position = self.global_position
	#var position_change = current_position - previous_position
	#var position_change_magnitude = position_change.length()
	#if position_change_magnitude < position_change_threshold:
		#print("位置向量在小幅度抖动")
	#else:
		#print("位置向量在大幅度变化")
	#previous_position = current_position


func _update_camera(delta) -> void: # 更新摄像机位置
	_mouse_rotation.x += _tilt_input * delta # 更新摄像机的x轴旋转
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT) # 限制摄像机的x轴旋转范围
	_mouse_rotation.y += _rotation_input * delta # 更新摄像机的y轴旋转

	var transform_marker = Vector3(0.0, _mouse_rotation.y + PLAYER.turn_round_rotation, 0.0)
	#var last_player_rotation = _player_rotation
	# 模型旋转平滑 删除这行↑ 头的运动将进行迭代导致左右摇摆
	#_player_rotation.y = Global.exponential_decay(last_player_rotation.y, transform_marker.y, 6 * delta) # 6.155
	_player_rotation.y = transform_marker.y
	_player_rotation.x = 0.0
	_player_rotation.z = 0.0

	var difference = _mouse_rotation.y + PLAYER.turn_round_rotation - _player_rotation.y # 计算旋转差值
	_camera_rotation.x = _mouse_rotation.x + up_down_rotation
	_camera_rotation.x = clamp(_camera_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT) # 防止上下摇头超出
	_camera_rotation.y = look_back_rotation + difference
	# 脖子角度左右旋转极限为80度
	#var yy = smoothstep(deg_to_rad(80), deg_to_rad(180), abs(_camera_rotation.y))
	#_player_rotation.y = Global.exponential_decay(last_player_rotation.y, transform_marker.y, (yy*4 + 6) * delta)
	_camera_rotation.y = clamp(_camera_rotation.y, -deg_to_rad(180), deg_to_rad(180))
	# 应用
	head.transform.basis = Basis.from_euler(_camera_rotation) # 应用摄头部旋转
	PLAYER.global_transform.basis = Basis.from_euler(_player_rotation) # 应用玩家模型旋转
	player_transform_marker.transform.basis = Basis.from_euler(transform_marker) # 实际上的移动参考
	# 重置
	head.rotation.z = 0.0 # 重置摄像机的z轴旋转
	_rotation_input = 0.0 # 重置旋转输入
	_tilt_input = 0.0 # 重置倾斜输入



func headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	var amp = BOB_AMP
	pos.y = sin(time * BOB_FREQ) * amp
	pos.x = cos(time * BOB_FREQ / 2) * amp
	return pos


func fov_change(_delta) -> void: # FOV
	# 计算速度的FOV变化
	var velocity_clamped = clamp(PLAYER.vel2d.length() - PLAYER.speed_normal, 0.0, PLAYER.speed_max)
	var plaFaceDir = Vector2(_face_dir.x, _face_dir.z).normalized()
	var dot = PLAYER.vel2d.normalized().dot(plaFaceDir)

	var lerp_weight = fov_lerp if is_zoom else 0.0
	var target_fov_base: float = Global.exponential_decay(fov_base, fov_zoom, lerp_weight)
	var target_fov: float = target_fov_base
	target_fov += FOV_CHANGE# * velocity_clamped * dot
	target_fov = clamp(target_fov, target_fov_base, fov_base * fov_clamp_max)
	fov = Global.exponential_decay(fov, target_fov, fov_lerp_speed)


func fov_lerp_change():
	if Input.is_action_pressed("mouse_wheel_up"):
		fov_lerp += fov_sensitivity
	if Input.is_action_pressed("mouse_wheel_down"):
		fov_lerp -= fov_sensitivity
	fov_lerp = clamp(fov_lerp, 0.2, 1)


func tilt_head_to_body(_delta) -> void:
	tilt_target_angle += rad_to_deg(_camera_rotation.y) * tilt_target_angle_multiply
	tilt_target_angle = clamp(tilt_target_angle, -tilt_head_to_body_clamp, tilt_head_to_body_clamp)
	tilt_target_angle = abs(pow(tilt_target_angle / tilt_head_to_body_clamp, 3)) * sign(tilt_target_angle)
	mouse_tilt_angle = tilt_head_to_body_angle * tilt_target_angle# * cos(head.rotation.x)


# z轴摇摄像机
func tilt_head(_delta) -> void:
	# 计算左右歪头
	lr_tilt = int(Input.is_action_pressed("move_left")) - int(Input.is_action_pressed("move_right"))
	target_tilt = deg_to_rad(tilt_angle) * lr_tilt # 重置目标倾斜角度
	if movement_state_machine.current_state is PlayerDash: # 冲刺状态下不歪头
		target_tilt = deg_to_rad(tilt_angle) * left_right_tilt_desh * 3
	targetZ = Global.exponential_decay(targetZ, target_tilt, lr_tilt_speed) # 计算目标摄像机的z轴旋转
	rotation.z = targetZ + deg_to_rad(mouse_tilt_angle)


func _on_player_dash_start() -> void:
	left_right_tilt_desh = int(Input.is_action_pressed("move_left")) - int(Input.is_action_pressed("move_right"))


func calculate_player_rotation_speed(delta) -> void:
	player_rotation_speed = (_player_rotation.y - player_rotation_temp) / delta
	player_rotation_temp = _player_rotation.y


func _on_eye_area_body_entered(body: Node3D) -> void:
	if not body == self and body is CharacterBody3D and body.collision_layer == 4:
		enemy_area_body.append(body)


func _on_eye_area_body_exited(body: Node3D) -> void:
	if body in enemy_area_body:
		enemy_area_body.remove_at(enemy_area_body.find(body))
	if body in aiming_aidable_objects:
		aiming_aidable_objects.remove_at(aiming_aidable_objects.find(body))


func aiming_aidable_objects_in_out() -> void:
	for body in enemy_area_body:
		if body is CharacterBody3D:
			# 使用is_position_in_frustum()函数判断对象是否在视锥内，曾经导致实际判定相对于画面向上便宜
			if is_position_on_screen(body.global_position) and not body in aiming_aidable_objects:
				aiming_aidable_objects.append(body)
			if not is_position_on_screen(body.global_position) and body in aiming_aidable_objects:
				aiming_aidable_objects.remove_at(aiming_aidable_objects.find(body))


func is_position_on_screen(global_pos: Vector3) -> bool:
	var screen_pos = unproject_position(global_pos)
	if screen_pos == screen_pos.clamp(Vector2(0, 0), get_viewport().get_size()):
		return true
	return false


# 辅助瞄准，用于计算并设置最近的瞄准目标  自瞄
func auxiliary_aiming() -> void:
	# var look_at_target: Vector3 = normal_target_marker.global_position
	if aiming_aidable_objects.size() > 0:
		var screen_centre = Vector2(get_viewport().get_size().x / 2, get_viewport().get_size().y / 2)
		var distance_list = []
		for obj in aiming_aidable_objects:
			var screen_pos = unproject_position(obj.global_position)
			var distance = screen_centre.distance_to(screen_pos)
			distance_list.append({"object": obj,
									"distance": distance,
									"screen_pos": screen_pos})

		if distance_list.size() > 0:
			var min_distance = distance_list[0]["distance"]
			var nearest_obj = distance_list[0]["object"]
			var tag_screen_pos = distance_list[0]["screen_pos"]
			for i in range(1, distance_list.size()):
				if distance_list[i]["distance"] < min_distance:
					min_distance = distance_list[i]["distance"]
					nearest_obj = distance_list[i]["object"]
					tag_screen_pos = distance_list[i]["screen_pos"]
			if nearest_obj and min_distance < get_viewport().get_size().y / 2 * PLAYER.auxiliary_aiming_radius:
				auxiliary_aiming_ball.visible = true
				auxiliary_aiming_ball.global_position = nearest_obj.global_position
				# 设置瞄准
				PLAYER.eye_ray_cast.look_at(nearest_obj.global_position)
				ui.normal_crosshair = false
				ui.crosshair.position = tag_screen_pos + ui.amend
			else:
				PLAYER.eye_ray_cast.look_at(normal_target_marker.global_position)
				ui.normal_crosshair = true
				auxiliary_aiming_ball.visible = false
	else:
		#PLAYER.eye_ray_cast.look_at(normal_target_marker.global_position)
		ui.normal_crosshair = true
		auxiliary_aiming_ball.visible = false

# PLAYER.auxiliary_aiming_radius



var saved_camera_global_pos = null
func save_camera_pos_for_smoothing() -> void:
	if saved_camera_global_pos == null:
		saved_camera_global_pos = head.global_position
		slide_camera_smooth_back_to_origin_ready = true


var smooth_target_pos
const CROUCH_TRANSLATE = 0.2
const CROUCH_TRANSLATE_XZ = 0.2  # 新增常量，用于x和z坐标的平移量
var slide_camera_smooth_back_to_origin_y_only: bool = false
var slide_camera_smooth_back_to_origin_ready: bool = false
func slide_camera_smooth_back_to_origin(delta: float, y_only: bool = false) -> void:
	if saved_camera_global_pos == null: 
		return
		
	if y_only:
		head.global_position.y = saved_camera_global_pos.y
	else:
		head.global_position = saved_camera_global_pos
	
	if slide_camera_smooth_back_to_origin_ready:
		smooth_target_pos = head.position
		slide_camera_smooth_back_to_origin_ready = false
		
	# Clamp incase teleported
	smooth_target_pos.y = clampf(smooth_target_pos.y, -CROUCH_TRANSLATE, CROUCH_TRANSLATE)
	if not y_only:
		smooth_target_pos.x = clampf(smooth_target_pos.x, -CROUCH_TRANSLATE_XZ, CROUCH_TRANSLATE_XZ)  # 新增x坐标限制
		smooth_target_pos.z = clampf(smooth_target_pos.z, -CROUCH_TRANSLATE_XZ, CROUCH_TRANSLATE_XZ)  # 新增z坐标限制

	var move_amount = max(player.velocity.length(), player.speed_normal) * delta * 10
	smooth_target_pos.y = Global.exponential_decay(smooth_target_pos.y, 0.0, move_amount*4.6)
	if not y_only:
		smooth_target_pos.x = Global.exponential_decay(smooth_target_pos.x, 0.0, move_amount*4.6)  # 新增x坐标平滑
		smooth_target_pos.z = Global.exponential_decay(smooth_target_pos.z, 0.0, move_amount*4.6)  # 新增z坐标平滑

	head.position =  head.position.lerp(smooth_target_pos + head_pos_original, 0.5)
	#prints("head smooth_", head.position)
	saved_camera_global_pos = head.global_position

	if y_only:
		if is_zero_approx(smooth_target_pos.y):
			saved_camera_global_pos = null # Stop smoothing camera
	else:
		if smooth_target_pos.is_zero_approx():
			saved_camera_global_pos = null # Stop smoothing camera
