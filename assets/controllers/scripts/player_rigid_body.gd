class_name PlayerRigidBody3D
extends RigidBody3D

@export var player: HL.Controller.Player
@export var ues_player_rigid_body: bool = true ## 是否使用
@export var point_visible: bool = false ## 是否显示轨迹点
@export var trace_force: float = 100 ## 轨迹的力大小,废弃
@export var linear_damp_max = 10 ## 最大线性阻尼,废弃
@export var sorption_distance: float = 0.05 ## 吸附距离,废弃
@export var limit_distance: float = 0.2 ## 限制距离,废弃
@export_category("PID Settings")
@export var Kall: float = 500 ## 总控系数
@export var Kp: float = 30 ## 比例系数
@export var Ki: float = 2 ## 积分系数
@export var Kd: float = 1 ## 微分系数
@export var Kdash: float = 1.5 ## 冲刺系数

var target_pos: Vector3 # 目标位置
var error_pos: Vector3 # 误差位置

var current_error: Vector3 = Vector3.ZERO # 当前误差
var last_error: Vector3 = Vector3.ZERO # 上一次误差
var integral: Vector3 = Vector3.ZERO # 积分

var k_amend: float = 1.0

var collision: CollisionShape3D

var knockback_velocity: Vector3 = Vector3.ZERO

#@onready var player: HL.Controller.Player = $"../Player"
@onready var marker_3d: Marker3D = $Marker3D
@onready var placeholder_mesh: MeshInstance3D = $PlaceholderMesh
@onready var target: MeshInstance3D = $Target


func _ready() -> void:
	await owner.ready
	if ues_player_rigid_body and player:
		self.global_position = player.global_position
	if player:
		collision = player.collision_shape_3d


func _physics_process(delta: float) -> void:
	placeholder_mesh.visible = true if point_visible else false # 显示轨迹点
	target.visible = true if point_visible else false # 显示轨迹点

	if ues_player_rigid_body:
		# 目标位置为碰撞体的全局位置加上玩家方向和冲刺方向的向量
		error_pos = player.input_direction + player.dash_dir3d
		# 限制误差位置的长度从而限制目标位置到以limit_distance为半径的球内
		if error_pos.length() > limit_distance:
			error_pos = error_pos.normalized() * limit_distance
		target_pos = collision.global_position + error_pos

		target.global_position = target_pos

		# var target_force = aligning_velocity_direction(direction, delta) # 对齐速度方向
		var target_force = update_pid(target_pos, global_position, delta) + knockback_velocity # 更新PID

		# 限制在碰撞体的平面内
		var collision_Plane = Plane(player.up_direction, collision.global_position)
		if not collision_Plane.is_point_over(global_position):
			global_position = global_position - collision_Plane.distance_to(global_position) * collision_Plane.normal

		# 如果目标力不是nan且不为零，设置恒定力为目标力减去玩家的加速度
		if not is_nan(target_force.length()) and target_force:
			constant_force = target_force # - player.acceleration

		if player.movement_state_machine.current_state.name == "Idle":
			integral = integral.move_toward(Vector3.ZERO, 0.2 * delta)


# 对齐速度方向
func aligning_velocity_direction(direction: Vector3, delta: float) -> Vector3:
	if - marker_3d.basis.z != direction and global_position != target_pos and target_pos.angle_to(Vector3(0, 1, 0)) > 0:
		marker_3d.look_at(target_pos) # 调整朝向至目标位置  buggggggggg
	var velocity_direction_basis = linear_velocity * marker_3d.basis # 轴向对齐坐标系

	# 计算加速度
	var acceleration_x = -velocity_direction_basis.x / delta
	var acceleration_y = -velocity_direction_basis.y / delta
	var acceleration_z = 0
	var acceleration_z_max = 0

	if abs(acceleration_x) + abs(acceleration_y) >= trace_force: # 限制最大加速度
		acceleration_x = acceleration_x / (abs(acceleration_x) + abs(acceleration_y)) * trace_force
		acceleration_y = acceleration_y / (abs(acceleration_x) + abs(acceleration_y)) * trace_force
	else:
		acceleration_z_max = -(trace_force - abs(acceleration_x) - abs(acceleration_y)) # 目标方向的力是剩下来的

	acceleration_z = acceleration_z_max
	acceleration_z = clamp(acceleration_z, -acceleration_z_max, acceleration_z_max)
	return Vector3(acceleration_x, acceleration_y, acceleration_z) * marker_3d.basis.inverse() # 返回坐标系


func update_pid(target_position: Vector3, current_position: Vector3, delta: float) -> Vector3:
	current_error = target_position - current_position
	integral += current_error * delta # 积分项随时间积累
	var derivative: Vector3 = (current_error - last_error) / delta # 微分项是误差变化率
	last_error = current_error # 更新上一个误差为当前误差，用于下次计算

	#计算PID总输出力
	var force: Vector3 = Kp * current_error + Ki * integral + Kd * derivative
	if player.dash_dir3d:
		force = force * Kall# * Kdash
	return force * Kall * k_amend


func be_hit(attack: HL.Attack) -> void:
	#damaged(attack.damage)
	var force = attack.position.direction_to(global_position) * attack.knockback_force * attack.position.distance_to(global_position) / attack.radius
	knockback_velocity = force / mass
