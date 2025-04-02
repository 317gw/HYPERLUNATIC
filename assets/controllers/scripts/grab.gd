class_name GrabFuction
extends Node
# 感谢 https://github.com/LunaticReisen/GodotSourceMovement
# 抓取状态不能疾跑，会根据重量减速

@export_group("Grab")
@export var grab_power      :float = 8.0  # 抓取力量
@export var rotation_power  :float = 0.1  # 旋转力量
@export var throw_power     :float = 10   # 投掷力量
@export var push_power      :float = 1    # 推力量
@export var distance_power  :float = 0.25 # 距离调整力量
@export var distance_min    :float = 1    # 最小距离
@export var distance_max    :float = 4    # 最大距离

var hand_to_obj_dis: float              # 手到物体的距离
var hand_to_obj_dir: float              # 手到物体的方向
var hand_original_position: Vector3     # 手的原始位置
var picked_object :RigidBody3D          # 被抓取的物体
var picked_up: bool = false             # 是否已经抓取
var view_lock: bool = false             # 视角是否锁定

@onready var player : HL.Player = $"../.."                           # 玩家控制器
@onready var player_transform_marker: Marker3D = $"../../PlayerTransformMarker" # 玩家变换标记
@onready var camera_3d: HL.Camera = $"../Camera3D"                   # 摄像机
@onready var hand :Marker3D = $Marker3D                                         # 手的标记

@onready var interaction :RayCast3D = $Interaction          # 交互射线
@onready var joint :Generic6DOFJoint3D = $Joint             # 通用6自由度关节
@onready var staticbody :StaticBody3D = $GrabStaticBody     # 静态物体
@onready var righting_timer: Timer = $RightingTimer         # 校正定时器


func _ready() -> void:
	hand_original_position = hand.position  # 初始化手的原始位置


func _unhandled_input(event) -> void:
	if event.is_action_pressed("pick_up") and not player.movement_state_machine.current_state.name == "Climb": # f
		if picked_up:
			dropping_object()
		else:
			pick_object()

	if picked_up:
		if event.is_action_pressed("shoot_left"):
			throwing_object()
		if event.is_action_pressed("shoot_right"):
			dropping_object()
		if Input.is_action_pressed("rotate"):
			righting_object(event)
			view_lock = true
			rotating_object(event)

	if Input.is_action_just_released("rotate"):
		view_lock = false
	if grab_power:
		distance_object()


func _physics_process(_delta):
	if picked_up:
		var hand_position: Vector3 = hand.global_transform.origin
		var picked_obj_position: Vector3 = picked_object.global_position + picked_object.center_of_mass
		picked_object.linear_velocity = (hand_position - picked_obj_position) * grab_power
		hand_to_obj_dis = self.global_position.distance_to(picked_object.global_position)

		var _decelerate: float = remap(picked_object.mass, 0, 2000, 0, 0.5)
		_decelerate = clampf(_decelerate, 0, 0.5)
		player.decelerate_list.append(_decelerate) # 施加玩家减速


func pick_object() -> void:
	var collider: Node3D
	if interaction.is_colliding():
		collider = interaction.get_collider()
	if collider != null and collider is RigidBody3D:
		picked_object = collider
		joint.node_b = picked_object.get_path()
		picked_up = true
		camera_3d.is_zoom = false
		# 过远吸过来 近距离只抬起
		hand_to_obj_dis = self.global_position.distance_to(picked_object.global_position)
		hand.position.z = -min(hand_to_obj_dis, abs(hand_original_position.z))
		if collider.has_meta("be_picked_up"):
			collider.set_meta("be_picked_up", true)


func dropping_object() -> void:
	# TODO 制作相关游戏机制 TODO
	# ↓ 防止物体完全静止触发睡眠
	picked_object.apply_central_impulse(Vector3.DOWN * 0.1)

	if picked_object.has_meta("be_picked_up"):
		picked_object.set_meta("be_picked_up", false)

	picked_object = null
	joint.node_b = NodePath("")
	picked_up = false
	hand.position = hand_original_position
	staticbody.rotation = Vector3.ZERO


func throwing_object() -> void:
	var knockback = self.global_position.direction_to(picked_object.global_position)
	var i: Vector3 = knockback * throw_power * (hand.position.z + distance_max)
	if i.length() < picked_object.mass * throw_power:
		i = i.normalized() * picked_object.mass * throw_power
	picked_object.apply_central_impulse(i)
	dropping_object()


func rotating_object(event) -> void:
	if event is InputEventMouseMotion:
		staticbody.rotate_x(deg_to_rad(event.relative.y * rotation_power))
		staticbody.rotate_y(deg_to_rad(event.relative.x * rotation_power))


func distance_object() -> void:
	if Input.is_action_pressed("mouse_wheel_up"):
		hand.position.z -= distance_power
	if Input.is_action_pressed("mouse_wheel_down"):
		hand.position.z += distance_power
	hand.position.z = -clamp(-hand.position.z, distance_min, distance_max)


func righting_object(event) -> void:
	if righting_timer.time_left > 0 and event.is_action_pressed("rotate"):
		joint.node_b = NodePath("")
		picked_object.look_at(camera_3d.global_position)
		joint.node_b = picked_object.get_path()
		return
	righting_timer.start()
