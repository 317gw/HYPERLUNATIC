@tool
extends DanmakuEmitterBase
class_name DanmakuEmitterMulti
# danmaku_emitter_multi

@export var bullet_multi_node: PackedScene = null
@export var bullet_multi_mesh: PackedScene = null

# multi弹幕
var bullets_multi_mesh_instance: MultiMeshInstance3D
var bullet_count: int = 0
var delete_list: Array = []


@onready var disk_mmi_3d: MultiMeshInstance3D = $EmitterMeshDisplay/DiskMMI3D
@onready var stripe_mmi_3d: MultiMeshInstance3D = $EmitterMeshDisplay/StripeMMI3D


func _ready() -> void:
	if not Engine.is_editor_hint():
		# 等待初始化
		self.process_mode = Node.PROCESS_MODE_DISABLED
		await Global.danmaku_manager_ready
		# 异常停用
		var node_ok:= bullet_multi_node and bullet_multi_node.instantiate() is Node3D
		var mesh_ok:= bullet_multi_mesh and bullet_multi_mesh.instantiate() is MultiMeshInstance3D
		if not node_ok or not mesh_ok:
			printerr("The bullet_multi_node has not been set correctly.")
			return
		self.process_mode = Node.PROCESS_MODE_PAUSABLE

		# 实例化 multi_mesh
		bullets_multi_mesh_instance = bullet_multi_mesh.instantiate()
		add_child(bullets_multi_mesh_instance, true)
		# 计算预计数量
		bullet_count = max_bullet + (disk_count * stripe_count) + 1
		bullet_count = MathUtils.next_power_of_two(bullet_count)

		_save_properties()
		_emitter_ready()


func _process_in_geme(delta: float) -> void:
	# 更新基本属性
	direction_vector = -self.transform.basis.z
	emitter_velocity += emitter_acceleration * delta
	self.global_position += emitter_velocity * delta

	if firing:
		_in_firing(delta)
	_process_bullet(delta)
	_handle_reset(delta)


func _process_bullet(delta: float) -> void:
	var bmmi_multimesh:= bullets_multi_mesh_instance.multimesh
	#bmmi_multimesh.visible_instance_count = bullets.size()
	#if bmmi_multimesh.instance_count < bullets.size():
		#bmmi_multimesh.instance_count = bullets.size()
	bmmi_multimesh.instance_count = bullets.size()


	for i in bullets.size():
		var bullet: Bullet = bullets[i]

		# 移动 move_bullet
		var bullet_velocity:= bullet.velocity + bullet.acceleration * delta
		bullet.velocity = bullet_velocity
		var bullet_up: Vector3 = calculate_bullet_up(bullet_velocity)
		bullet.look_at_from_position(bullet.global_position + bullet_velocity * delta, bullet_velocity.normalized(), bullet_up)

		# 绘制
		bmmi_multimesh.set_instance_transform(i, bullet.transform)
		bmmi_multimesh.set_instance_color(i, bullet.color1)
		bmmi_multimesh.set_instance_custom_data(i, bullet.color2)

		# 弹幕寿命
		bullet.lifetime -= delta
		if bullet.lifetime <= 0:
			delete_list.append(bullet)

	for wrapper in delete_list:
		_delete_bullet(wrapper)
	delete_list.clear()


func _set_bullet(fire_pos: Vector3, target: Vector3) -> void: # 返回子弹的索引
	_delete_out_cap_bullets()

	var bullet_instance: Bullet = bullet_multi_node.instantiate()  # 实例化弹幕
	bullet_ware.add_child(bullet_instance)
	bullet_instance.add_to_group("danmaku")
	bullets.append(bullet_instance)

	# 设置位置和朝向
	bullet_instance.global_position = fire_pos
	var bullet_target = fire_pos + target
	var bullet_up: Vector3 = calculate_bullet_up(bullet_target - bullet_instance.global_position)
	bullet_instance.look_at(bullet_target, bullet_up)

	bullet_instance.global_position = fire_pos # 设定弹幕位置
	bullet_instance.velocity = -bullet_instance.transform.basis.z * bullet_speed # 需要在弹幕脚本中定义speed属性
	bullet_instance.lifetime = bullet_lifetime # 设定弹幕的生存时间
	bullet_instance.color1 = bullet_color1
	bullet_instance.color2 = bullet_color2

	bullet_instance.set_bullet_scale(bullet_scale_final)

	number_of_launches_in_this_frame += 1


func _delete_out_cap_bullets() -> void: # 删除超出上限的弹幕
	if exceeding_the_cap_mode == CapMode.DELETE_OLDEST and not bullets.is_empty() and bullets.size() >= max_bullet:
		_delete_bullet(bullets.pop_front())


func _delete_bullet(bullet: Bullet) -> void: # 删除指定的弹幕
	bullets.erase(bullet)
	Global.danmaku_manager.particles.add_break_group(bullet.global_position, bullet.color1, bullet.bullet_radius*14)
	bullet.queue_free()
