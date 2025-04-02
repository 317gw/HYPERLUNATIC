extends Node3D

#const PROBE = preload("res://assets/systems/water_physics/old/probe.tscn")
const PM = preload("res://assets/systems/water_physics/pm.tscn")

#@export var voxel_point_density: float = 1: # n/m3
	#set(v): voxel_point_distance = pow(1.0/v, 1.0/3.0)
#@export var voxel_point_distance: float = 1 # m
	#set(v): voxel_point_density = 1.0/pow(v, 3.0)

# 抖动调节
#@export var Kd: float = 10 ## 微分系数
var target_pos: Vector3 # 目标位置
var error_pos: Vector3 # 误差位置
var current_error: Vector3 = Vector3.ZERO # 当前误差
var last_error: Vector3 = Vector3.ZERO # 上一次误差

#var is_in_water: bool = false
var is_all_in_water: bool = false
var using_simple_resistance: bool = false

var space_state: PhysicsDirectSpaceState3D
# 计算的参数
var superficial_area: float = 0.0 ## 模型表面积
var body_mass: float = 0.0 ## 质量
var body_volume: float = 0.0 ## 体积
var body_density: float = 0.0 ## 密度
var volume_sphere_radius: float = 0.0001 # 同体积球半径
var probe_buoy_radius: float = 0.0001 # 同体积球半径
var in_water_const: int = 0
#var discharged_density: float = 0.0001 ## 排出液体的体积
var discharged_volume_ratio: float = 0.0
var reynold: float = 0 ## 雷诺数 Reynolds number
var auto_inertia: Vector3

var _velocity: Vector3
var _acceleration: Vector3# = Vector3.ZERO
var _position_last: Vector3
var _velocity_last: Vector3

# 液体 空气
var voxel_points_ready: bool = false
var probe_buoy_pos: PackedVector3Array = []
#var probe_slice_pos: PackedVector3Array = []
var probe_buoy_location: Array = []
#var probe_slice_location: Array = []
var water_meshs: Array = []

var _parent_rigid_body: RigidBody3D
var _gravity: Vector3
var _manager: HL.FluidMechanicsManager
var _mesh_instance_3d: MeshInstance3D

var _mesh: Mesh = null
var _mesh_aabb: AABB
var _mesh_surface: Array
var _mesh_vertices: PackedVector3Array
var _mesh_indices: PackedInt32Array
var _mesh_normals: PackedVector3Array
var _mesh_vertex_count: int = 0

var _thread = Thread.new()
var _mutex := Mutex.new()

var _ppqp_intersect_mesh := PhysicsPointQueryParameters3D.new()
var _ppqp_in_water := PhysicsPointQueryParameters3D.new()
var _prqp := PhysicsRayQueryParameters3D.new()

# 此脚本受力的睡眠
var sleep_threshold_linear: float
var sleep_threshold_angular: float
var time_before_sleep: float
var sleeping: bool = false



func _ready() -> void:
	_parent_rigid_body = self.get_parent()
	#if not _parent_rigid_body.has_meta("fluid_mechanics"):
	_parent_rigid_body.set_meta("fluid_mechanics", self)
	_parent_rigid_body.set_meta("be_picked_up", false)
	_manager = Global.fluid_mechanics_manager

	# 睡眠
	sleep_threshold_linear = ProjectSettings.get_setting("physics/3d/sleep_threshold_linear")
	sleep_threshold_angular = ProjectSettings.get_setting("physics/3d/sleep_threshold_angular")
	time_before_sleep = ProjectSettings.get_setting("physics/3d/time_before_sleep")

	# 点检测
	_ppqp_intersect_mesh.collide_with_bodies = true
	_ppqp_in_water.collide_with_bodies = false
	_ppqp_in_water.collide_with_areas = true
	_ppqp_in_water.set_collision_mask(32)


	# 错误检查
	if not _parent_rigid_body is RigidBody3D:
		push_error("MeshVolume: Parent is not a RigidBody3D!")
		return
	for child in _parent_rigid_body.get_children():
		if child is MeshInstance3D:
			_mesh_instance_3d = child
			_mesh = child.mesh
			break
	if _mesh == null:
		push_error("MeshVolume: No mesh found!")
		return

	# 初始化公用模型参数
	_mesh_aabb = _mesh.get_aabb()
	_mesh_surface = _mesh.surface_get_arrays(0)
	_mesh_vertices = _mesh_surface[Mesh.ARRAY_VERTEX]
	_mesh_indices = _mesh_surface[Mesh.ARRAY_INDEX]
	_mesh_normals = _mesh_surface[Mesh.ARRAY_NORMAL]
	_mesh_vertex_count = _mesh_vertices.size()

	# 处理模型
	calculate_mesh(_mesh_vertices, _mesh_indices, _mesh_normals)
	volume_sphere_radius = pow(body_volume * 0.238732, 0.333333)
	body_mass = _parent_rigid_body.mass
	body_density = body_mass / body_volume

	_position_last = global_position
	target_pos = global_position
	auto_inertia = get_inertia()


func _physics_process(delta: float) -> void:
	_velocity = (global_position - _position_last) / delta
	_position_last = global_position
	_acceleration = (_velocity - _velocity_last) / delta
	_velocity_last = _velocity

	handle_sleep(delta)


func calculate_mesh(vertices: PackedVector3Array, indices: PackedInt32Array, normals: PackedVector3Array) -> void:
	body_volume = 0.0
	superficial_area = 0.0
	for i in range(0, indices.size(), 3):
		var v1 = vertices[indices[i]]
		var v2 = vertices[indices[i + 1]]
		var v3 = vertices[indices[i + 2]]
		# 体积
		var cross_product = v2.cross(v3)
		var dot_product = v1.dot(cross_product)
		var triangle_volume = abs(dot_product)
		body_volume += triangle_volume
		# 表面积
		var edge1 = v2 - v1
		var edge2 = v3 - v1
		var cross_product2 = edge1.cross(edge2)
		var triangle_area = cross_product2.length()
		superficial_area += triangle_area
	body_volume /= 6.0
	superficial_area /= 2.0


func update_voxel_points() -> void:
	for child in get_children():
		child.queue_free()
	generate_voxel_points()


#var full_points: PackedVector3Array
func generate_voxel_points() -> void:
	if body_volume < 0.5:
		_get_probe_buoy_fcc(2)
		return
	if body_volume < 0.9:
		_get_probe_buoy_fcc(3)
		return
	_get_probe_buoy_fcc(4)
	if probe_buoy_pos.size() < 100:
		_get_probe_buoy_fcc(5)

	using_simple_resistance = (
		body_volume < 1.0 and (probe_buoy_pos.size() < 8) #or probe_slice_pos.size() < 6
	) or body_volume < 20

	probe_buoy_radius = pow(body_volume / probe_buoy_pos.size() * 0.238732, 0.333333)


func _get_probe_buoy_fcc(_range: int) -> void:
	_range = max(_range, 2)
	probe_buoy_pos.clear()
	probe_buoy_pos = HL.generate_FCC_lattice(
		_range,
		func(p): return (p - Vector3.ONE * (_range-1) * 0.5) * (_mesh_aabb.size * 1/(_range-1)) * 0.95,
		func(p): return is_point_intersect_mesh(global_basis * p + global_position)
		)


# , type: String, id: int           , "buoy", id
# space_state: PhysicsDirectSpaceState3D,
func is_point_intersect_mesh(point: Vector3) -> bool:
	_ppqp_intersect_mesh.position = point
	var result := space_state.intersect_point(_ppqp_intersect_mesh)
	if not result: return false
	if result.size() == 0: return false

	for i in result.size():
		var collider = result[i].collider
		if result[i].collider == _parent_rigid_body:
			return true
	return false


# 精确位置检测
func is_point_in_water(point: Vector3 = Vector3.ZERO) -> Array: # TODO 批量检测点在模型内的算法
	_ppqp_in_water.position = global_basis * point + global_position
	var result := space_state.intersect_point(_ppqp_in_water, water_meshs.size())
	if not result: return [0, HL.Viscositys.AIR]
	if result.size() == 0: return [0, HL.Viscositys.AIR]

	var _d: float = 0
	var _v: float = 0
	for i in result.size():
		var collider: Node3D = result[i].collider.get_parent()
		_d += collider.density
		_v += collider.viscosity
	return [_d / result.size(), _v / result.size()]


# 在fluid_mechanics.gd中，批量处理物理查询
func batch_query_points(points: Array) -> Array:
	var results = []
	for point in points:
		results.append(is_point_in_water(point))
	return results


# 根据物体形状使用更合适的阻力系数
func get_drag_coefficient(reynold: float, shape: String = "sphere") -> float:
	match shape:
		"sphere": return HL.sphere_Cd_by_reynold(reynold)
		"cube": return 1.05  # 立方体的典型阻力系数
		_: return HL.sphere_Cd_by_reynold(reynold)


func apply_force(_delta: float) -> void:
	var g: Vector3 = Global.gravity
	#if _thread.is_started():
		#_thread.wait_to_finish()
	#_thread.start(_apply_force.bind(_delta, g, rezt0))
	_apply_force(_delta, g)


func _apply_force(_delta: float, g: Vector3) -> void:
	if not is_in_water() or _parent_rigid_body.sleeping or sleeping:
		_parent_rigid_body.linear_damp = 0
		_parent_rigid_body.angular_damp = 0
		return

	# 浮力
	var force_p: Vector3 = -g * body_volume / max(probe_buoy_pos.size(), 1)
	var density_add: float = 0
	var viscosity_add: float = HL.Viscositys.AIR
	var m: Vector3 = Vector3.ZERO

	#var time_start = Time.get_ticks_usec()
	in_water_const = 0
	if is_in_water():
		#update_detection_priority()
		_gravity = _parent_rigid_body.get_gravity()
		var hit = null
		for i in probe_buoy_pos.size():
			var point := probe_buoy_pos[i]
			var rezt: Array = is_point_in_water(point)
			var density: float = rezt[0]
			var viscosity: float = rezt[1]

			# 确定浸入比例
			if i % 3 == 0 and density > 0:
				_prqp.from = point
				_prqp.to = point - _gravity
				hit = space_state.intersect_ray(_prqp)
			var closest_distance = INF
			if hit and hit.size() > 0:
				var dist = point.distance_to(hit.position)
				if dist < closest_distance:
					closest_distance = dist
			# 计算浸入比例（假设晶格点半径为0.5）
			var submergence = clamp(closest_distance / probe_buoy_radius * 1, 0.0, 1.0)

			density_add += density * submergence
			viscosity_add += viscosity * submergence
			in_water_const += int(density > 0)# * submergence
			m += (global_basis * point + _parent_rigid_body.center_of_mass).cross(force_p * density)
	#var time_end = Time.get_ticks_usec()
	#print("took %d microseconds" % (time_end - time_start))

	# 入液比例
	is_all_in_water = in_water_const == probe_buoy_pos.size()
	var in_water_ratio: float = in_water_const / max(probe_buoy_pos.size(), 1)
	discharged_volume_ratio = move_toward(
		discharged_volume_ratio,
		in_water_ratio,
		HL.sigmoid(_velocity.length() - 4),
		)

	density_add /= max(probe_buoy_pos.size(), 1)
	viscosity_add /= max(probe_buoy_pos.size(), 1)
	#in_water_const = max(in_water_const, 1)
	#density_add = max(density_add / in_water_const * discharged_volume_ratio, 0)
	#viscosity_add = max(viscosity_add / in_water_const * discharged_volume_ratio, HL.Viscositys.AIR)

	# 阻力
	var resistance: Vector3 = Vector3.ZERO
	if not _parent_rigid_body.get_meta("be_picked_up"): # using_simple_resistance and
		#resistance = 18.8496 * viscosity * volume_sphere_radius * _velocity
		var Re: float = HL.reynold(density_add, _velocity.length(), volume_sphere_radius * 2, viscosity_add)
		var Cd: float = HL.sphere_Cd_by_reynold(Re)
		resistance = HL.drag_force(Cd, density_add, _velocity, PI*volume_sphere_radius**2)


	var _force: Vector3 = -g * body_volume * density_add
	_force -= resistance.limit_length(body_volume * density_add / discharged_volume_ratio)
	#print(_force)

	# 受力平衡
	#target_pos = HL.exponential_decay_vec3(target_pos, global_position, _delta)
	#current_error = target_pos - global_position
	#if is_in_water() and (body_density < density_add or body_density < rezt0[0]):
		#var _convergence_index = current_error.length()
		#_force = lerp(-g * body_mass, _force, HL.sigmoid(_convergence_index))
		#m = lerp(Vector3.ZERO, m, HL.sigmoid(_convergence_index))

	# 应用
	_parent_rigid_body.call_deferred("apply_central_force", _force)
	_parent_rigid_body.call_deferred("apply_torque", m)
	#_parent_rigid_body.apply_central_force(_force)
	#_parent_rigid_body.apply_torque(m)

	# 阻尼
	var _damp: float = discharged_volume_ratio
	if is_all_in_water:
		_damp = max(_damp*_velocity.normalized().dot(-g.normalized()), 0)
	#_parent_rigid_body.linear_damp = 2 * _damp
	_parent_rigid_body.angular_damp = 0.5 * _damp + pow(viscosity_add, 0.5)





#func get_water_meshs() -> Array:
	#return water_meshs.map(func(id): return _manager.water_mesh_3d_s[id])


func is_in_water() -> bool:
	return not water_meshs.is_empty()


func get_inertia():
	return PhysicsServer3D.body_get_direct_state(_parent_rigid_body.get_rid()).inverse_inertia.inverse()


var time_sleep: float = 0.0
func handle_sleep(_delta: float) -> void:
	if not is_in_water():
		return
	time_sleep = time_sleep - _delta if can_sleep() else time_before_sleep
	sleeping = true if time_sleep <= 0.0 else false

func can_sleep() -> bool:
	return (_velocity.length() < sleep_threshold_linear
		and _parent_rigid_body.angular_velocity.length() < sleep_threshold_angular)


func _exit_tree() -> void:
	_manager.rigid_bodys_fluid_mechanics.erase(self)
	if _thread.is_started():
		_thread.wait_to_finish()

	if _parent_rigid_body.has_meta("fluid_mechanics"):
		_parent_rigid_body.remove_meta("fluid_mechanics")
