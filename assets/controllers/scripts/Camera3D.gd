#class_name PlayerCamera
extends Camera3D

const TILT_LOWER_LIMIT := deg_to_rad(-89.7) # 将下倾限制转换为弧度
const TILT_UPPER_LIMIT := deg_to_rad( 89.7) # 将上倾限制转换为弧度
# 视角摇晃 bob variables
const BOB_FREQ: float = 1.8 # 频率
const BOB_AMP: float = 0.04 # 振幅
# fov变化
const FOV_CHANGE: float = 1.5

# 左右歪头
@export var MOUSE_SENSITIVITY: float = 0.35 # 导出变量，可以在编辑器中设置鼠标灵敏度
@export var PLAYER: HL.Player
@export var tilt_head_to_body_angle: float = 10.0
@export var tilt_head_to_body_clamp: float = 75.0
@export_range(0, 180) var tilt_angle: float = 1.0
@export_range(0, 1) var lr_tilt_speed: float = 1.0
@export_range(0, 1) var player_rotation_smooth: float = 0.05
@export var tilt_target_angle_multiply : float = 0.5

@export_group("FOV&Zoom")
@export var fov_base: float = 90.0
@export var fov_zoom: float = 5.0
@export var fov_clamp_max: float = 1.2
@export_range(0, 1) var fov_sensitivity : float = 0.1
@export_range(0, 1) var fov_lerp_speed: float = 0.2
@export var camera_extension: float = 5.0


var look_back_rotation: float = 0.0 # 回头
var _up_down_rotation: float = 0.0 # 抬头和低头
# var _fov_air_change : float # fov变化
# 左右歪头
var _target_tilt: float
var _lr_tilt: int
var _left_right_tilt_dash : int
var _target_z : float
# 自瞄
var aiming_aidable_objects: Array = [CharacterBody3D]
var enemy_area_body: Array = [CharacterBody3D]
var enemy_area_radius: float
var player_fp_ui: HL.PlayerFP_UI
#var front_sight: HL.FrontSight
# FOV & Zoom  缩放
var is_zoom: bool = false
var fov_lerp: float = 0.7
# 摄像机位置调整
var head_pos_original: Vector3
var head_bob_pos: Vector3
var stair_smooth_pos: Vector3

var _mouse_input: bool = false # 判断是否有鼠标输入
var _rotation_input: float # 存储旋转输入
var _tilt_input: float # 存储倾斜输入

# 实时变化的
var sensitivity: float #实际的鼠标灵敏度
var player_rotation_speed: float # 玩家旋转速度
var _player_rotation_temp: float # 玩家旋转速度临时变量
var _bob_time: float # 视角摇晃 bob variables
var mouse_tilt_angle: float
var _tilt_target_angle: float
var _mouse_rotation: Vector3 # 存储鼠标旋转值
var _face_dir: Vector3 # 面对方向
var _player_rotation: Vector3 # 存储玩家旋转值
var _camera_rotation: Vector3 # 存储摄像机旋转值

#var previous_position: Vector3 = Vector3.ZERO
#var position_change_threshold: float = 0.1  # 你可以根据实际情况调整这个阈值

@onready var player: HL.Player = $"../.."
@onready var head: Node3D = $".."
@onready var camera_smooth: Node3D = $".."
@onready var hand: GrabFuction = $"../Hand"
@onready var player_transform_marker: Node3D = $"../../PlayerTransformMarker"
@onready var turn_round: CameraTurnRound = $"../../CameraStateMachine/TurnRound"
# 获取状态机
@onready var movement_state_machine: StateMachine = $"../../MovementStateMachine"
@onready var camera_state_machine: StateMachine = $"../../CameraStateMachine"
@onready var weapon_manager: Node3D = $"../../WeaponManager"
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
	player_fp_ui = Global.player_fp_ui

	# 初始化瞄准参数
	eye_ray_cast.target_position.z = -PLAYER.visible_range
	normal_target_marker.position.z = -PLAYER.visible_range
	var edge: Vector3 = project_position(Vector2(get_viewport().get_size().x / 2, 0), PLAYER.auto_aiming_distance)
	auxiliary_end_marker.position.z = -PLAYER.auto_aiming_distance

	# 距离设置
	enemy_area_radius = auxiliary_end_marker.position.distance_to(edge)
	eye_area_collision_shape.shape.radius = enemy_area_radius
	eye_area_collision_shape.shape.height = PLAYER.auto_aiming_distance
	eye_area_collision_shape.position.z = -PLAYER.auto_aiming_distance / 2
	cylinder_xx.mesh.top_radius = enemy_area_radius
	cylinder_xx.mesh.bottom_radius = enemy_area_radius
	cylinder_xx.mesh.height = PLAYER.auto_aiming_distance
	cylinder_xx.position.y = -PLAYER.auto_aiming_distance / 2
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
	if _mouse_input and event:
		var mouse_motion: InputEventMouseMotion = event
		sensitivity = MOUSE_SENSITIVITY
		if is_zoom:
			sensitivity *= clampf(lerp(fov_base, fov_zoom, fov_lerp) / fov_base, 0.15, 1)
		_rotation_input = -mouse_motion.screen_relative.x * sensitivity # 计算旋转输入
		_tilt_input = -mouse_motion.screen_relative.y * sensitivity # 计算倾斜输入
	if event.is_action_pressed("zoom") and not hand.picked_up:
		is_zoom = !is_zoom
		weapon_manager.visible = !weapon_manager.visible
		fov_lerp = 0.6
	if is_zoom:
		_adjust_zoom_level()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Global.is_tool_ui_move_camera():
		var mouse_motion: InputEventMouseMotion = event
		sensitivity = MOUSE_SENSITIVITY
		if mouse_motion.screen_relative.length() > 200:
			return
		_rotation_input = -mouse_motion.screen_relative.x * sensitivity # 计算旋转输入
		_tilt_input = -mouse_motion.screen_relative.y * sensitivity # 计算倾斜输入


func _physics_process(delta: float) -> void:
	_face_dir = -global_transform.basis.z
	_calculate_head_tilt_angle(delta)

	if not hand.view_lock:
		_update_camera_rotation(delta) # 根据鼠标移动更新摄像机位置

	_calculate_player_rotation_speed(delta)

	# Head bob
	_process_head_bob(delta)

	slide_camera_smooth_back_to_origin(delta, slide_camera_smooth_back_to_origin_y_only)
	if _saved_camera_global_pos == null:
		head.position = head_pos_original
	position.z = 0

	_update_fov(delta)
	_apply_head_tilt(delta) # 问题

	# 自瞄
	_process_aiming_system()


func _calculate_player_rotation_speed(delta) -> void:
	player_rotation_speed = (_player_rotation.y - _player_rotation_temp) / delta
	_player_rotation_temp = _player_rotation.y


func _update_camera_rotation(delta) -> void: # 更新摄像机位置
	_mouse_rotation.x += _tilt_input * delta # 更新摄像机的x轴旋转
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT) # 限制摄像机的x轴旋转范围
	_mouse_rotation.y += _rotation_input * delta # 更新摄像机的y轴旋转

	var transform_marker = Vector3(0.0, _mouse_rotation.y + PLAYER.turn_round_rotation, 0.0)
	_player_rotation.y = transform_marker.y
	_player_rotation.x = 0.0
	_player_rotation.z = 0.0

	var difference = _mouse_rotation.y + PLAYER.turn_round_rotation - _player_rotation.y # 计算旋转差值
	_camera_rotation.x = _mouse_rotation.x + _up_down_rotation
	_camera_rotation.x = clamp(_camera_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT) # 防止上下摇头超出
	_camera_rotation.y = look_back_rotation + difference
	_camera_rotation.y = clamp(_camera_rotation.y, -deg_to_rad(180), deg_to_rad(180))

	# 应用
	head.transform.basis = Basis.from_euler(_camera_rotation) # 应用摄头部旋转
	PLAYER.global_transform.basis = Basis.from_euler(_player_rotation) # 应用玩家模型旋转
	player_transform_marker.transform.basis = Basis.from_euler(transform_marker) # 实际上的移动参考
	# 重置
	head.rotation.z = 0.0 # 重置摄像机的z轴旋转
	_rotation_input = 0.0 # 重置旋转输入
	_tilt_input = 0.0 # 重置倾斜输入


func _process_head_bob(delta: float) -> void:
	var should_bob = (
		PLAYER.velocity.length() >= 1 and
		PLAYER.is_on_floor() and
		not movement_state_machine.current_state is PlayerDash and
		not movement_state_machine.current_state is FreeViewMode
	)

	if should_bob:
		_bob_time += delta * PLAYER.velocity.length()
		head_bob_pos = head_bob_pos.lerp(_calculate_headbob_offset(_bob_time), 0.2)
	else:
		head_bob_pos = head_bob_pos.lerp(Vector3.ZERO, 0.08)

	position = position.lerp(head_bob_pos, 0.5)


func _calculate_headbob_offset(time: float) -> Vector3:
	var pos = Vector3.ZERO
	var amp = BOB_AMP
	pos.y = sin(time * BOB_FREQ) * amp
	pos.x = cos(time * BOB_FREQ / 2) * amp
	return pos


func _calculate_head_tilt_angle(_delta) -> void:
	_tilt_target_angle += rad_to_deg(_camera_rotation.y) * tilt_target_angle_multiply
	_tilt_target_angle = clamp(_tilt_target_angle, -tilt_head_to_body_clamp, tilt_head_to_body_clamp)
	_tilt_target_angle = abs(pow(_tilt_target_angle / tilt_head_to_body_clamp, 3)) * sign(_tilt_target_angle)
	mouse_tilt_angle = tilt_head_to_body_angle * _tilt_target_angle# * cos(head.rotation.x)


# z轴摇摄像机
func _apply_head_tilt(_delta) -> void:
	# 计算左右歪头
	_lr_tilt = int(Input.is_action_pressed("move_left")) - int(Input.is_action_pressed("move_right"))
	_target_tilt = deg_to_rad(tilt_angle) * _lr_tilt # 重置目标倾斜角度
	if movement_state_machine.current_state is PlayerDash: # 冲刺状态下不歪头
		_target_tilt = deg_to_rad(tilt_angle) * _left_right_tilt_dash  * 3
	_target_z  = HL.exponential_decay(_target_z , _target_tilt, lr_tilt_speed) # 计算目标摄像机的z轴旋转
	rotation.z = _target_z  + deg_to_rad(mouse_tilt_angle)


func _update_fov(_delta) -> void: # FOV
	# 计算速度的FOV变化
	#var velocity_clamped = clamp(PLAYER.vel_hor.length() - PLAYER.speed_normal, 0.0, PLAYER.speed_max)
	var plaFaceDir = Vector2(_face_dir.x, _face_dir.z).normalized()
	#var dot = PLAYER.vel_hor.normalized().dot(plaFaceDir)

	var lerp_weight = fov_lerp if is_zoom else 0.0
	var target_fov_base: float = HL.exponential_decay(fov_base, fov_zoom, lerp_weight)
	var target_fov: float = target_fov_base
	target_fov += FOV_CHANGE# * velocity_clamped * dot
	target_fov = clamp(target_fov, target_fov_base, fov_base * fov_clamp_max)
	fov = HL.exponential_decay(fov, target_fov, fov_lerp_speed)


func _adjust_zoom_level():
	if Input.is_action_pressed("mouse_wheel_up"):
		fov_lerp += fov_sensitivity
	if Input.is_action_pressed("mouse_wheel_down"):
		fov_lerp -= fov_sensitivity
	fov_lerp = clamp(fov_lerp, 0.2, 1)


func _on_player_dash_start() -> void:
	_left_right_tilt_dash  = int(Input.is_action_pressed("move_left")) - int(Input.is_action_pressed("move_right"))


func _on_eye_area_body_entered(body: Node3D) -> void:
	if not body == self and body is CharacterBody3D and body.collision_layer == 4:
		enemy_area_body.append(body)


func _on_eye_area_body_exited(body: Node3D) -> void:
	if body in enemy_area_body:
		enemy_area_body.remove_at(enemy_area_body.find(body))
	if body in aiming_aidable_objects:
		aiming_aidable_objects.remove_at(aiming_aidable_objects.find(body))


func _process_aiming_system() -> void:
	_update_aiming_targets()
	_process_auto_aim()


func _update_aiming_targets() -> void:
	# 先处理退出区域的物体
	for body in enemy_area_body.duplicate():  # 使用副本避免修改时迭代
		if body is CharacterBody3D and not _is_position_visible_on_screen(body.global_position) and body in aiming_aidable_objects:
			aiming_aidable_objects.erase(body)

	# 再处理新进入的物体
	for body in enemy_area_body:
		if body is CharacterBody3D and _is_position_visible_on_screen(body.global_position) and body not in aiming_aidable_objects:
			aiming_aidable_objects.append(body)


# 位置在屏幕上
# 使用is_position_in_frustum()函数判断对象是否在视锥内，曾经导致实际判定相对于画面向上偏移
func _is_position_visible_on_screen(global_pos: Vector3) -> bool:
	var screen_pos = unproject_position(global_pos)
	if screen_pos == screen_pos.clamp(Vector2(0, 0), get_viewport().get_size()):
		return true
	return false


# 辅助瞄准，用于计算并设置最近的瞄准目标  自瞄
func _process_auto_aim() -> void:
	if not player_fp_ui.front_sight:
		return

	if aiming_aidable_objects.is_empty():
		_reset_auto_aim()
		return

	var nearest_data = _find_nearest_target()
	if nearest_data and nearest_data.distance < get_viewport().get_size().y / 2 * PLAYER.auto_aiming_radius:
		_activate_auto_aim(nearest_data)
	else:
		_reset_auto_aim()

func _find_nearest_target() -> Dictionary:
	var screen_centre = get_viewport().get_size() / 2
	var nearest_data = {}
	var min_distance = INF

	for obj in aiming_aidable_objects:
		if obj is not CharacterBody3D:
			continue

		var screen_pos = unproject_position(obj.global_position)
		var distance = screen_centre.distance_to(screen_pos)

		if distance < min_distance:
			min_distance = distance
			nearest_data = {
				"object": obj,
				"distance": distance,
				"screen_pos": screen_pos
			}

	return nearest_data

func _activate_auto_aim(nearest_data: Dictionary) -> void:
	auxiliary_aiming_ball.visible = true
	auxiliary_aiming_ball.global_position = nearest_data.object.global_position
	PLAYER.eye_ray_cast.look_at(nearest_data.object.global_position)
	player_fp_ui.front_sight.auto_aim_start(nearest_data.screen_pos)

func _reset_auto_aim() -> void:
	auxiliary_aiming_ball.visible = false
	PLAYER.eye_ray_cast.look_at(normal_target_marker.global_position)
	player_fp_ui.front_sight.auto_aim_end()


# 保存用于平滑处理的相机位置
var _saved_camera_global_pos = null
func save_camera_position() -> void:
	if _saved_camera_global_pos == null:
		_saved_camera_global_pos = head.global_position
		_slide_camera_smooth_back_to_origin_ready = true


# 滑动镜头平稳地回到原点
const CROUCH_TRANSLATE = 0.2
const CROUCH_TRANSLATE_XZ = 0.2  # 新增常量，用于x和z坐标的平移量
var _smooth_target_pos
var slide_camera_smooth_back_to_origin_y_only: bool = false
var _slide_camera_smooth_back_to_origin_ready: bool = false
func slide_camera_smooth_back_to_origin(delta: float, y_only: bool = false) -> void:
	if _saved_camera_global_pos == null:
		return

	if y_only:
		head.global_position.y = _saved_camera_global_pos.y
	else:
		head.global_position = _saved_camera_global_pos

	if _slide_camera_smooth_back_to_origin_ready:
		_smooth_target_pos = head.position
		_slide_camera_smooth_back_to_origin_ready = false

	# Clamp incase teleported
	_smooth_target_pos.y = clampf(_smooth_target_pos.y, -CROUCH_TRANSLATE, CROUCH_TRANSLATE)
	if not y_only:
		_smooth_target_pos.x = clampf(_smooth_target_pos.x, -CROUCH_TRANSLATE_XZ, CROUCH_TRANSLATE_XZ)  # 新增x坐标限制
		_smooth_target_pos.z = clampf(_smooth_target_pos.z, -CROUCH_TRANSLATE_XZ, CROUCH_TRANSLATE_XZ)  # 新增z坐标限制

	var move_amount = max(player.velocity.length(), player.speed_normal) * delta * 10
	_smooth_target_pos.y = HL.exponential_decay(_smooth_target_pos.y, 0.0, move_amount*4.6)
	if not y_only:
		_smooth_target_pos.x = HL.exponential_decay(_smooth_target_pos.x, 0.0, move_amount*4.6)  # 新增x坐标平滑
		_smooth_target_pos.z = HL.exponential_decay(_smooth_target_pos.z, 0.0, move_amount*4.6)  # 新增z坐标平滑

	head.position =  head.position.lerp(_smooth_target_pos + head_pos_original, 0.5)
	#prints("head smooth_", head.position)
	_saved_camera_global_pos = head.global_position

	if y_only:
		if is_zero_approx(_smooth_target_pos.y):
			_saved_camera_global_pos = null # Stop smoothing camera
	else:
		if _smooth_target_pos.is_zero_approx():
			_saved_camera_global_pos = null # Stop smoothing camera
