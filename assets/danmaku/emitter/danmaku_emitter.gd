@tool
extends DanmakuEmitterBase
class_name DanmakuEmitter
# danmaku_emitter

@export var bullet_scene: PackedScene = preload("res://assets/danmaku/bullet/bullet_test.tscn") ## 类型 发射的弹幕预制体

@onready var disk_mmi_3d: MultiMeshInstance3D = $EmitterMeshDisplay/DiskMMI3D
@onready var stripe_mmi_3d: MultiMeshInstance3D = $EmitterMeshDisplay/StripeMMI3D


func _ready() -> void:
	if not Engine.is_editor_hint():
		# 等待初始化和异常停用
		self.process_mode = Node.PROCESS_MODE_DISABLED
		await Global.danmaku_manager_ready
		if not bullet_scene or bullet_scene.instantiate() is not Bullet:
			printerr("The bullet_scene has not been set correctly.")
			return
		self.process_mode = Node.PROCESS_MODE_PAUSABLE

		#await Global.danmaku_manager.ready
		_save_properties()
		_emitter_ready()


func _process_in_geme(delta: float) -> void:
	# 更新基本属性
	direction_vector = -self.transform.basis.z
	emitter_velocity += emitter_acceleration * delta
	self.global_position += emitter_velocity * delta

	if firing:
		_in_firing(delta)
	_move_bullet(delta)
	_delete_expired_bullets(delta)# 检查并删除超时的弹幕
	_handle_reset(delta)


# 移动弹幕
# 100
# 1~70+  2~60+?  4~80
func _move_bullet(delta: float) -> void:
	for bullet: Bullet in bullets:
		bullet.velocity += bullet.acceleration * delta
		var bullet_up: Vector3 = calculate_bullet_up(bullet.velocity)
		bullet.look_at_from_position(bullet.global_position + bullet.velocity * delta, bullet.velocity, bullet_up)


func _set_bullet(fire_pos: Vector3, target: Vector3) -> void: # 定义_set_bullet函数，用于设置弹幕的属性和发射
	_delete_out_cap_bullets()

	var bullet_instance: Bullet = bullet_scene.instantiate()  # 实例化弹幕
	bullet_instance.add_to_group("danmaku")

	#Global.danmaku_manager.bullet_and_collision.add_child(bullet_instance)
	bullet_ware.add_child(bullet_instance)
	bullets.append(bullet_instance) # 存储已发射的弹幕
	number_of_launches_in_this_frame += 1


	# 设置朝向
	var bullet_target = fire_pos + target
	#var bullet_target = target
	var bullet_up: Vector3 = calculate_bullet_up(bullet_target - bullet_instance.global_position)
	bullet_instance.look_at(bullet_target, bullet_up)


	# 设置其他
	bullet_instance.global_position = fire_pos # 设定弹幕位置
	bullet_instance.velocity = -bullet_instance.transform.basis.z * bullet_speed # 需要在弹幕脚本中定义speed属性
	bullet_instance.lifetime = bullet_lifetime # 设定弹幕的生存时间
	#bullet_instance.scale = Vector3.ONE*0.001 if bullet_scale.is_zero_approx() else bullet_scale
	bullet_instance.color1 = bullet_color1
	bullet_instance.color2 = bullet_color2

	bullet_instance.set_bullet_scale(bullet_scale_final)

	#if ues_multi_mesh_instance_3d:
		#var bullet_transform: Transform3D = Transform3D()


func _delete_out_cap_bullets() -> void: # 删除超出上限的弹幕
	if exceeding_the_cap_mode == CapMode.DELETE_OLDEST and bullets.size() > 0 and bullet_ware.get_child_count() > max_bullet:
		var bullet = bullets.front()
		_delete_bullet(bullet)


func _delete_expired_bullets(delta: float) -> void: # 删除过期的弹幕
	for bullet: Node in bullets:
		if bullet.lifetime > 0:
			bullet.lifetime -= delta
		else:
			_delete_bullet(bullet)


func _delete_bullet(bullet: Bullet) -> void: # 删除指定的弹幕
	bullets.erase(bullet)
	Global.danmaku_manager.particles.add_break_group(bullet.global_position, bullet.color1, bullet.bullet_radius*14)
	bullet.queue_free()
