class_name WaterPhysics
extends Node3D

@export_range(0.0, 1.0) var linear_damp: float = 0.1
@export_range(0.0, 1.0) var angular_damp: float = 0.1

var _mesh: Mesh = null
# 状态
var current_state: String # 当前状态
var water_area: Array = []
var is_in_water: bool = false
var sleeping: bool = true
var should_at_surface: bool = false
var using_simple_simulations: bool = false
var have_surface: bool = false
# 常用力学计算参数
var buoyancy_force: Vector3 = Vector3.ZERO
var resistance_force: Vector3 = Vector3.ZERO
var buoyancy_centre: Vector3 = Vector3.ZERO
var buoyancy_centre_lest_frame: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
var surface_pos: Vector3 = Vector3.ZERO
var liquid_discharged_volume: float = 0.0 ## 排出液体的体积
var volume: float = 0.0 ## 体积
var high_diff: float = 0.0
var high_diff_0_1: float = 0.0
# 计时
var sleeping_time: float = 0.0
var out_water_time: float = 0.0
var at_surface_time: float = 0.0
@export var sleeping_wait_time: float = 5.0
@export var out_water_wait_time: float = 1.0
@export var at_surface_wait_time: float = 1.5

var buoyancy_probe_in_water: Array = []
var resistance_probe_in_water: Array = []
var buoyancy_probe_child_count: float = 0.0
var resistance_probe_child_count: float = 0.0
#var resistance_probe_pos_lest_frame: Array = []
#var resistance_probe_velocity: Array = []
# 其他力学计算参数
var density: float = 0.0 ## 密度
var total_area: float = 0.0 ## 表面积
var similarity_to_sphere: float = -1 ## 和球的相似度，以弃用
var roughness: float = 0.0 ## 粗糙度
var drag_coefficient: float = 0.0
var cross_sectional_area: float = 0.0
var average_resistance_probe_area: float = 0.001
var global_position_lest_frame: Vector3 = Vector3.ZERO
# 同体积球半径
var _mesh_volume_sphere_radius: float = 0.0
var lest_frame_buoyancy_probes_in_water: int = 0
var frames_since_the_last_change: int = 0

var _parent_rigid_body: RigidBody3D
var _mesh_instance_3d: MeshInstance3D
var _mesh_surface: Array
var _mesh_vertices: PackedVector3Array
var _mesh_indices: PackedInt32Array
var _mesh_normals: PackedVector3Array
var _mesh_vertex_count: int = 0

var frame_skiper: FrameSkiper

@onready var buoyancy_probe: Node3D = $BuoyancyProbe
@onready var resistance_probe: Node3D = $ResistanceProbe
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var water_physics_state_machine: StateMachine = $WaterPhysicsStateMachine

#const PROBE = preload("res://assets/systems/water_physics/probe.tscn")
const PROBE = preload("res://assets/systems/water_physics/old/probe.tscn")

func _ready() -> void:
	_parent_rigid_body = self.get_parent()
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
	# 初始化跳帧
	frame_skiper = FrameSkiper.new(60, 12)
	self.add_child(frame_skiper)
	# 初始化公用模型参数
	_mesh_surface = _mesh.surface_get_arrays(0)
	_mesh_vertices = _mesh_surface[Mesh.ARRAY_VERTEX]
	_mesh_indices = _mesh_surface[Mesh.ARRAY_INDEX]
	_mesh_normals = _mesh_surface[Mesh.ARRAY_NORMAL]
	_mesh_vertex_count = _mesh_vertices.size()
	# 处理模型
	calculate_mesh(_mesh_vertices, _mesh_indices, _mesh_normals)
	# 计算其他参数
	density = _parent_rigid_body.mass / volume
	_mesh_volume_sphere_radius = pow(volume * 0.238732, 0.333333) # V = 4/3 πr³  0.238732414637843  3*volume/(4*PI)
	cross_sectional_area = PI * pow(_mesh_volume_sphere_radius, 2.0)
	## 新建球体，计算相似度
	#var sphere_mesh: SphereMesh = create_sphere_mesh(_mesh_volume_sphere_radius, _mesh_volume_sphere_radius*2, _mesh_vertex_count)
	#var sphere_surface = sphere_mesh.surface_get_arrays(0)
	#var sphere_vertices = sphere_surface[Mesh.ARRAY_VERTEX]
	## 计算相似度
	#similarity_to_sphere = calculate_similarity(_mesh_vertices, sphere_vertices)
	#similarity_to_sphere = abs(similarity_to_sphere - 1.0) + 1.0
	# 计算阻力系数
	#drag_coefficient = clamp(similarity_to_sphere * 0.47, 0.0, 2.1) + roughness
	drag_coefficient = 0.8 + roughness
	# 初始化探针
	var max_probe: int = 100
	create_buoyancy_probe(_mesh, min(20 * volume, max_probe) )
	create_resistance_probe(_mesh_vertices, _mesh_indices, min(20 * volume, max_probe) )
	# 如果无法生成足够的探针，则使用简单模拟
	if buoyancy_probe_child_count < 6:
		Global.children_queue_free(buoyancy_probe)
		using_simple_simulations = true
	# 初始化时间
	sleeping_time = sleeping_wait_time
	out_water_time = out_water_wait_time
	at_surface_time = at_surface_wait_time
	# 别的
	#debug_print()
	mesh_instance_3d.global_position = global_position


func _process(_delta: float) -> void:
	current_state = water_physics_state_machine.current_state.name


func _physics_process(delta: float) -> void:
	velocity = _parent_rigid_body.linear_velocity

	sleeping_time -= delta
	out_water_time -= delta
	at_surface_time -= delta

	if velocity.length() > 0.1:
		sleeping_time = sleeping_wait_time
	if is_in_water:
		out_water_time = out_water_wait_time

		if abs(high_diff) > 0.75 * _mesh_volume_sphere_radius or velocity.length() > 1.0:
			at_surface_time = at_surface_wait_time
			should_at_surface = false
		if at_surface_time <= 0:
			#buoyancy_centre = HL.exponential_decay_vec3(buoyancy_centre, Vector3.ZERO, delta*46)
			should_at_surface = true

		#mesh_instance_3d.global_position = buoyancy_centre + global_position
	else:
		mesh_instance_3d.global_position = global_position
		if not water_area.is_empty():
			water_area.clear()


func calculate_velocity(delta: float) -> void:
	global_position = _parent_rigid_body.global_position
	velocity = (global_position - global_position_lest_frame) / delta
	global_position_lest_frame = global_position


func probe_simulations(delta: float, speed: float = 30, power: float = 1, use_high_diff: bool = true) -> void:
	if use_high_diff:
		delta *= speed * (1.0 - high_diff_0_1)
		power *= clamp(1.0 - high_diff_0_1, 0.05, 1.0)
	#var power: float = 30
	var buoyancy_probe_count = buoyancy_probe_in_water.size()
	var buoyancy_centre_in_water_ratio = buoyancy_probe_count / buoyancy_probe_child_count

	if buoyancy_probe_count > 0:
		if buoyancy_centre_in_water_ratio == 1:
			buoyancy_centre = HL.exponential_decay_vec3(buoyancy_centre, Vector3.ZERO, delta)
		else:
			var target_buoyancy_centre = Vector3.ZERO
			if buoyancy_centre_in_water_ratio != 1:
				for i in range(buoyancy_probe_count):
					target_buoyancy_centre += buoyancy_probe_in_water[i].global_position
				target_buoyancy_centre /= float(buoyancy_probe_count)
				target_buoyancy_centre -= global_position
			buoyancy_centre_lest_frame = buoyancy_centre
			buoyancy_centre = HL.exponential_decay_vec3(buoyancy_centre, target_buoyancy_centre, delta)
		liquid_discharged_volume = HL.exponential_decay(liquid_discharged_volume, volume * (buoyancy_centre_in_water_ratio ** 2) * power, delta)
	else:
		buoyancy_centre = Vector3.ZERO
		liquid_discharged_volume = 0.0


func simple_simulations(delta: float, smoothly: bool = false) -> void:
	sleeping = false
	#buoyancy_centre = HL.exponential_decay_vec3(buoyancy_centre, Vector3.ZERO, delta*46)
	buoyancy_centre = Vector3.ZERO
	if smoothly:
		var target_volume: float = volume * clamp(max(high_diff, 0.0) / max(_mesh_volume_sphere_radius, 0.001), 0.0, 1.0)
		liquid_discharged_volume = HL.exponential_decay(liquid_discharged_volume, target_volume, delta*20)
	else:
		liquid_discharged_volume = volume * clamp(max(high_diff, 0.0) / max(_mesh_volume_sphere_radius, 0.001), 0.0, 1.0)
	#if should_at_surface:
		#_parent_rigid_body.linear_velocity *= 0.9
	#mesh_instance_3d.global_position = buoyancy_centre + global_position


func ss_smooth_out() -> bool:
	return is_equal_approx(liquid_discharged_volume, volume * clamp(max(high_diff, 0.0) / max(_mesh_volume_sphere_radius, 0.001), 0.0, 1.0) )


func raycast_surface_pos() -> bool:
	ray_cast_3d.global_position = global_position
	#ray_cast_3d.global_rotation = Vector3.ZERO
	ray_cast_3d.global_position.y += 50
	ray_cast_3d.force_update_transform()
	ray_cast_3d.force_raycast_update()
	if ray_cast_3d.is_colliding():
		if ray_cast_3d.get_collision_normal().dot(Vector3.UP) > 0:
			surface_pos = ray_cast_3d.get_collision_point()
			high_diff = surface_pos.y - global_position.y
			high_diff_0_1 = 1.0/(abs(high_diff) + 1.0)
			#high_diff_0_1 *= max(-ray_cast_3d.get_collision_normal().dot(velocity.normalized() ), 0.0)
			have_surface = true
			return true
	have_surface = false
	return false


@export var Kall: float = 1 ## 总控系数
@export var Kp: float = 0 ## 比例系数

@export var Ki: float = 2 ## 积分系数

@export var Kd: float = 1 ## 微分系数
var last_error: Vector3 = Vector3.ZERO # 上一次误差
var integral: Vector3 = Vector3.ZERO # 积分
func at_surface_pid(delta: float) -> void:
	var target_pos: Vector3 = surface_pos
	var current_error: Vector3 = target_pos - global_position
	integral += current_error * delta # 积分项随时间积累
	var derivative: Vector3 = (current_error - last_error) / delta # 微分项是误差变化率
	last_error = current_error # 更新上一个误差为当前误差，用于下次计算
	#计算PID总输出力
	var force: Vector3 = Kp * current_error + Ki * integral + Kd * derivative * Kall
	_parent_rigid_body.apply_central_force(force)


func in_water_sleeping() -> void:
	_parent_rigid_body.apply_central_force(-Global.gravity * _parent_rigid_body.mass)
	_parent_rigid_body.linear_velocity *= 0.99
	_parent_rigid_body.angular_velocity *= 0.99


func can_in_water_sleeping() -> bool:
	return _parent_rigid_body.sleeping or sleeping_time <= 0.0


func buoyancy_centre_clamp() -> void:
	buoyancy_centre.y = min(buoyancy_centre.y, surface_pos.y - global_position.y - 0.01)


func damp_at_surface() -> void:
	#if velocity.dot(Vector3.UP) > 0:
	#if velocity.length() < 2:
	var v = 1 - smoothstep(1.0, 5.0, velocity.length() ) * 0.9
	_parent_rigid_body.linear_velocity *= lerp(1.0, (1.0 - linear_damp * v), high_diff_0_1)
	_parent_rigid_body.angular_velocity *= lerp(1.0, (1.0 - angular_damp * v), high_diff_0_1)


func is_out_water() -> bool:
	return out_water_time <= 0.0


func is_sleeping() -> bool:
	return sleeping_time <= 0.0


func is_at_surface() -> bool:
	return at_surface_time <= 0.0


func is_using_simple_simulations() -> bool:
	return using_simple_simulations or volume <= 0.3 or density < 1.0


func debug_print() -> void:
	print(" ")
	print("rigid_body: ", _parent_rigid_body)
	print("mesh_volume_sphere_radius: ", _mesh_volume_sphere_radius)
	print("Similarity to sphere: ", similarity_to_sphere)
	print("Roughness: ", roughness)
	print("Drag coefficient: ", drag_coefficient)
	print("buoyancy_probe_child_count: ", buoyancy_probe_child_count)
	print("resistance_probe_child_count: ", resistance_probe_child_count)
	#prints("标准差", calculate_similarity_to_sphere(_mesh_vertices))


func calculate_mesh(vertices: PackedVector3Array, indices: PackedInt32Array, normals: PackedVector3Array) -> void:
	# 标准化所有法线
	var normalized_normals = PackedVector3Array()
	for normal in normals:
		normalized_normals.append(normal.normalized())
	# 计算平均法线
	var sum = Vector3.ZERO
	for normal in normalized_normals:
		sum += normal
	var mean_normal = sum / normals.size()
	mean_normal = mean_normal.normalized()

	volume = 0.0
	total_area = 0.0
	var angle_sum = 0.0
	for i in range(0, indices.size(), 3):
		var v1 = vertices[indices[i]]
		var v2 = vertices[indices[i + 1]]
		var v3 = vertices[indices[i + 2]]
		# 体积
		var cross_product = v2.cross(v3)
		var dot_product = v1.dot(cross_product)
		var triangle_volume = abs(dot_product)
		volume += triangle_volume
		# 表面积
		var edge1 = v2 - v1
		var edge2 = v3 - v1
		var cross_product2 = edge1.cross(edge2)
		var triangle_area = cross_product2.length()
		total_area += triangle_area
		# 计算每个法线与平均法线之间的角度差异
		var normal = normalized_normals[i % 3]
		var dot_product2 = normal.dot(mean_normal)
		var angle = acos(clamp(dot_product2, -1.0, 1.0))
		# 加权角度差异
		angle_sum += angle * triangle_area / 2.0
	volume /= 6.0
	total_area /= 2.0
	# 计算加权平均角度差异
	var weighted_average_angle = angle_sum / total_area
	# 标准化粗糙度
	roughness = weighted_average_angle / PI  # 标准化到 [0, 1] 范围


func calculate_similarity(model_vertices: PackedVector3Array, sphere_vertices: PackedVector3Array) -> float:
	var total_distance = 0.0
	var num_vertices = min(model_vertices.size(), sphere_vertices.size())

	for i in num_vertices:
		var model_vertex = model_vertices[i]
		var sphere_vertex = sphere_vertices[i]
		var distance = model_vertex.distance_to(sphere_vertex)
		total_distance += distance

	var average_distance = total_distance / num_vertices
	return average_distance


# 当顶点过少时可能意外拟合到球上，比如各种方体，屎
func calculate_similarity_to_sphere(model_vertices: PackedVector3Array) -> float:
	if model_vertices.size() < 1:
		push_error("没有顶点")
		return -1
	var center = average_vertex_position(model_vertices)
	var average_distance = 0.0
	for vertex in model_vertices:
		var distance = vertex.distance_to(center)
		average_distance += distance
	average_distance /= model_vertices.size()
	# 方差
	var variance = 0.0
	for vertex in model_vertices:
		var distance = vertex.distance_to(center)
		variance += pow(distance - average_distance, 2.0)
	variance /= model_vertices.size()
	# 标准差
	var standard_deviation = sqrt(variance)
	# 标准差系数
	var standard_deviation_coefficient = standard_deviation / average_distance
	return standard_deviation


func average_vertex_position(vertices: PackedVector3Array) -> Vector3:
	var average_pos: Vector3 = Vector3.ZERO
	for vertice in vertices:
		average_pos += vertice
	average_pos /= vertices.size()
	return average_pos


func create_sphere_mesh(radius: float, height: float, vertex_count: int) -> SphereMesh:
	var rings = int(sqrt(vertex_count / 2.0))
	var radial_segments = int(vertex_count / float(rings) )

	# 确保rings和radial_segments至少为3
	rings = max(rings, 3)
	radial_segments = max(radial_segments, 3)

	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radial_segments = radial_segments
	sphere_mesh.rings = rings
	sphere_mesh.radius = radius
	sphere_mesh.height = height

	return sphere_mesh


func create_buoyancy_probe(mesh: Mesh, probe_number: int = 50) -> void: # , attempts_time: int = 10
	# 计算网格的包围盒
	var aabb: AABB = _parent_rigid_body.global_transform * mesh.get_aabb()
	# 点位的最小间距
	var min_spacing = max(0.1, pow(volume / float(probe_number), 0.333333) )
	# 在包围盒内生成均匀分布的点
	var probe_positions = []
	for i in range(probe_number):
		var probe_pos: Vector3 = random_pos_in_aabb(aabb)
		# = Vector3.ZERO
		#generate_random_point_inside_mesh(aabb, _mesh, probe_positions, min_spacing)
		for j in range(40):
			probe_pos = random_pos_in_aabb(aabb)
			if is_point_inside_mesh(probe_pos, 50) and is_point_not_clustered(probe_positions, probe_pos, min_spacing):
				break
		if not is_point_inside_mesh(probe_pos, 50) or not is_point_not_clustered(probe_positions, probe_pos, min_spacing):
			continue

		probe_positions.append(probe_pos)
		var probe = PROBE.instantiate()
		buoyancy_probe.add_child(probe)
		probe.name = "probe%s" %i
		probe.global_position = probe_pos
	buoyancy_probe_child_count = float(buoyancy_probe.get_child_count() )


func random_pos_in_aabb(aabb: AABB) -> Vector3:
	return Vector3(
			randf_range(aabb.position.x, aabb.end.x),
			randf_range(aabb.position.y, aabb.end.y),
			randf_range(aabb.position.z, aabb.end.z)
		)


# 检查点是否在网格内部
func is_point_inside_mesh(point: Vector3, check_times: int) -> bool:
	var space_state = get_world_3d().direct_space_state
	var ray_direction = Vector3(
		randf_range(-PI, PI),
		randf_range(-PI, PI),
		randf_range(-PI, PI)
		).normalized()  # 选择一个任意的射线方向
	var ray_length = volume * 3  # 选择一个足够长的射线长度

	# 创建 PhysicsRayQueryParameters3D 实例
	var ray_params:PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	ray_params.from = point
	ray_params.to = point + ray_direction * ray_length
	#ray_params.hit_from_inside = true  # 允许从内部开始检测
	ray_params.collide_with_bodies = true

	# 检测交点数量
	var intersection_count = 0
	for i in range(check_times):  # 限制最大投射次数以防止无限循环
		var result = space_state.intersect_ray(ray_params)
		if result and result.collider == _parent_rigid_body:
			intersection_count += 1
			ray_params.from = result.position + ray_direction * 0.001 # 微小偏移以避免重复交点
		else:
			break

	# 如果交点数量为奇数，则点在网格内部
	return intersection_count % 2 != 0


# 创建阻力探针
func create_resistance_probe(vertices: PackedVector3Array, indices: PackedInt32Array, probe_number: int = 50) -> void:
	# 计算每个探针的平均面积
	var average_probe_area = total_area / probe_number
	# 在网格表面生成均匀分布的探针
	var probe_positions = []
	# 点位的最小间距
	var min_spacing = max(0.001, pow(average_probe_area, 0.5) )

	# 泊松盘采样 分布
	for j in range(3):
		if probe_positions.size() < probe_number:
			for i in range(0, indices.size(), 3):
				var v1 = vertices[indices[i]]
				var v2 = vertices[indices[i + 1]]
				var v3 = vertices[indices[i + 2]]
				var edge1 = v2 - v1
				var edge2 = v3 - v1
				var cross_product = edge1.cross(edge2)
				var triangle_area = cross_product.length() / 2.0
				# 计算该三角形需要生成的探针数量
				var probe_count_for_triangle = int(triangle_area / average_probe_area)
				for _j in range(probe_count_for_triangle):
					var r1 = randf()
					var r2 = randf()
					if r1 + r2 > 1:
						r1 = 1 - r1
						r2 = 1 - r2
					var probe_pos = v1 + r1 * (v2 - v1) + r2 * (v3 - v1)
					if probe_positions.find(probe_pos) == -1:
						if is_point_not_clustered(probe_positions, probe_pos, (min_spacing * pow(0.75, j) ) ):
							probe_positions.append(probe_pos)
		else:
			break

	# 如果探针数量不足，直接在顶点上放置探针
	if probe_positions.size() < probe_number:
		for vertex in vertices:
			if probe_positions.size() >= probe_number:
				break
			if probe_positions.find(vertex) == -1:
				if is_point_not_clustered(probe_positions, vertex, min_spacing):
					probe_positions.append(vertex)

	# 实例化探针并设置位置
	for i in range(probe_positions.size()):
		var probe = PROBE.instantiate()
		resistance_probe.add_child(probe)
		probe.name = "probe%s" %i
		probe.position = probe_positions[i]
		# var mesh_instance3d = probe.get_node("MeshInstance3D")
		# mesh_instance3d.mesh.is_hemisphere = true
		# mesh_instance3d.rotation = normals[i % 3]

	average_resistance_probe_area = total_area / float(resistance_probe.get_child_count() )
	resistance_probe_child_count = float(resistance_probe.get_child_count() )


# 判断数组内点位是否拥挤
func is_point_not_clustered(points: Array, point: Vector3, min_spacing: float) -> bool:
	return points.all(func(pos): return (pos - point).length() > min_spacing)
