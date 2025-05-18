#@tool
extends DanmakuEmitterBase
#class_name DanmakuEmitterMulti
# danmaku_emitter_multi

@export var bullet_scene_multi_node: PackedScene = null
@export var bullet_scene_multi_mesh: PackedScene = null

# 对象池相关
var bullet_pool: IndieBlueprintObjectPool
var bullet_pool_initialized:= false

# multi弹幕
#var bullet_multi_mesh_instances: Array = [] # MultiMeshInstance3D
#var bullet_multi_meshs: Array = [] # MultiMesh
var bullets_multi_mesh_instance: MultiMeshInstance3D
var bullet_count: int = 0
var multi_lifetime: PackedFloat32Array = []
var multi_bullet_mass: PackedFloat32Array = []
var multi_velocity: PackedVector3Array = []
var multi_acceleration: PackedVector3Array = []
var multi_color1: PackedColorArray = []
var multi_color2: PackedColorArray = []
var multi_bullet_radius: PackedFloat32Array = []

var delete_list: Array = []

@onready var disk_mmi_3d: MultiMeshInstance3D = $EmitterMeshDisplay/DiskMMI3D
@onready var stripe_mmi_3d: MultiMeshInstance3D = $EmitterMeshDisplay/StripeMMI3D


func _ready() -> void:
	if not Engine.is_editor_hint():
		# 等待初始化
		self.process_mode = Node.PROCESS_MODE_DISABLED
		await Global.danmaku_manager_ready
		# 异常停用
		var node_ok:= bullet_scene_multi_node and bullet_scene_multi_node.instantiate() is Node3D
		var mesh_ok:= bullet_scene_multi_mesh and bullet_scene_multi_mesh.instantiate() is MultiMeshInstance3D
		if not node_ok or not mesh_ok:
			printerr("The bullet_scene_multi_node has not been set correctly.")
			return
		self.process_mode = Node.PROCESS_MODE_PAUSABLE

		# 实例化 multi_mesh
		bullets_multi_mesh_instance = bullet_scene_multi_mesh.instantiate()
		add_child(bullets_multi_mesh_instance, true)
		# 计算预计数量
		bullet_count = max_bullet + (disk_count * stripe_count) + 1
		bullet_count = HL.next_power_of_two(bullet_count)

		# 初始化对象池
		bullet_pool = IndieBlueprintObjectPool.new()
		bullet_pool.id = "bullet_pool_%s" % self.name
		bullet_pool.scene = bullet_scene_multi_node
		bullet_pool.max_objects_in_pool = bullet_count
		bullet_pool.create_objects_on_ready = true
		add_child(bullet_pool)

		#for wrapper in bullet_pool.pool:
			#bullet_ware.add_child(wrapper.instance)

		bullet_pool_initialized = true

		_set_bullet_count(bullet_count)

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
	_process_bullet(delta)
	_handle_reset(delta)


func _process_bullet(delta: float) -> void:
	var bmmi_multimesh:= bullets_multi_mesh_instance.multimesh
	#bmmi_multimesh.visible_instance_count = bullets.size()
	#if bmmi_multimesh.instance_count < bullets.size():
		#bmmi_multimesh.instance_count = bullets.size()
	bmmi_multimesh.instance_count = bullet_pool.spawned.size()
	for i in bullet_pool.spawned.size():
		var wrapper: IndieBlueprintObjectPoolWrapper = bullet_pool.spawned[i]
		var bullet: Node3D = wrapper.instance
		var index = wrapper.id

		# 移动 move_bullet
		var bullet_velocity:= multi_velocity[index] + multi_acceleration[index] * delta
		multi_velocity[index] = bullet_velocity
		var bullet_up: Vector3 = calculate_bullet_up(bullet_velocity)
		bullet.look_at_from_position(bullet.global_position + bullet_velocity * delta, bullet_velocity.normalized(), bullet_up)

		# 绘制
		bmmi_multimesh.set_instance_transform(i, bullet.transform)
		bmmi_multimesh.set_instance_color(i, multi_color1[index])
		bmmi_multimesh.set_instance_custom_data(i, multi_color2[index])

		# 弹幕寿命
		multi_lifetime[index] -= delta
		if multi_lifetime[index] <= 0:
			delete_list.append(wrapper)

	for wrapper in delete_list:
		_delete_bullet(wrapper)
	delete_list.clear()


func _set_bullet(fire_pos: Vector3, target: Vector3) -> void: # 返回子弹的索引
	_delete_out_cap_bullets()

	# 从对象池获取实例
	var wrapper:= bullet_pool.spawn()
	var bullet_instance: Node3D = wrapper.instance
	var index = wrapper.id
	#bullet_instance.add_to_group("danmaku")
	if bullet_instance.get_parent() != bullet_ware:
		bullet_ware.add_child(bullet_instance)
	bullet_instance.visible = true

	#bullets.append(bullet_instance)

	# 设置位置和朝向
	bullet_instance.global_position = fire_pos
	var bullet_target = fire_pos + target
	var bullet_up: Vector3 = calculate_bullet_up(bullet_target - bullet_instance.global_position)
	bullet_instance.look_at(bullet_target, bullet_up)

	multi_lifetime[index] = bullet_lifetime
	multi_bullet_mass[index] = bullet_mass
	multi_velocity[index] = -bullet_instance.transform.basis.z * bullet_speed
	multi_acceleration[index] = bullet_acceleration
	multi_color1[index] = bullet_color1
	multi_color2[index] = bullet_color2
	set_bullet_scale_and_radius(wrapper, bullet_scale_final)

	number_of_launches_in_this_frame += 1


func _delete_out_cap_bullets() -> void: # 删除超出上限的弹幕
	if exceeding_the_cap_mode == CapMode.DELETE_OLDEST and not bullet_pool.spawned.is_empty() and bullet_pool.spawned.size() > max_bullet:
		_delete_bullet(bullet_pool.spawned.pop_front())


func _delete_bullet(wrapper: IndieBlueprintObjectPoolWrapper) -> void: # 删除指定的弹幕
	var bullet: Node3D = wrapper.instance
	var index = wrapper.id
	Global.danmaku_manager.particles.add_break_group(bullet.global_position, multi_color1[index], multi_bullet_radius[index] * 14)
	bullet.visible = false
	#bullet_ware.remove_child(bullet)
	bullet_pool.kill(wrapper)


func _set_bullet_count(_count: int = bullet_count) -> void:
	bullets_multi_mesh_instance.multimesh.instance_count = _count
	multi_lifetime.resize(_count)
	multi_bullet_mass.resize(_count)
	multi_velocity.resize(_count)
	multi_acceleration.resize(_count)
	multi_color1.resize(_count)
	multi_color2.resize(_count)
	multi_bullet_radius.resize(_count)


func set_bullet_scale_and_radius(wrapper: IndieBlueprintObjectPoolWrapper, _scale: Vector3) -> void:
	var bullet: Node3D = wrapper.instance
	var index = wrapper.id

	var _radius: float = minf(_scale.x, _scale.y)
	self.scale = Vector3.ONE * _radius

	var bullet_radius = _radius * 0.25
	multi_bullet_radius[index] = bullet_radius

	var collisionshape3d: CollisionShape3D = Global.find_child_node_type(bullet, "CollisionShape3D")
	var ss: SphereShape3D = collisionshape3d.shape
	ss.radius = bullet_radius * 0.8
