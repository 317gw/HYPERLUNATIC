@tool
class_name Dispenser
extends MeshInstance3D


const FRAME_RATE: float = 60.0 # 每秒发射周期数
# DebugDisplay
const SCALE_FACTOR: float = 100.0 # 设置比例因子为100.0
const EPISILON: float = 0.00001 # 设置一个极小值
const VERTICES_STRIP_ORDER: Array = [4, 5, 0, 1, 2, 5, 6, 4, 7, 0, 3, 2, 7, 6, 0]
const GOLDEN_RATIO: float = 0.618033988749895 ## 黄金分割率

enum ResetMode {
	TIME,
	COUNT,
	}

enum ResetDelayMode {
	AFTER, ## 后
	BEFORE, ## 前
	RESET_COUNT, ## 重置次数 之后
	}

enum CapMode {
	STOP_LAUNCHING,
	DELETE_OLDEST,
	}

# 发射器
@export_group("Dispenser")
@export var velocity: Vector3 = Vector3.ZERO ## 速度
@export var acceleration: Vector3 = Vector3.ZERO ## 加速度
@export var center_position: Vector3 = Vector3.ZERO ## 发射中心坐标
# 射
@export_group("Fire")
@export var firing: bool = true ## 是否开火,射弹幕
@export var fire_period: int = 6 ## 发射周期 帧 1秒60帧
@export_range(0, 10, 1) var fire_count: int = 1 ## 发射次数 按照发射周期，同一发射帧的发射次数
@export var interpolate_position: bool = false ## 同一帧发射，发射位置是否插值
@export var start_fire_once: bool = true ## 是否开始时发射一次
# 重置
@export_group("Reset")
@export var only_reset_Dispenser_class: bool = false ## 只重置本类属性，不重置派生
@export var reset_mode: ResetMode = ResetMode.TIME ## 重置模式
@export var time_for_reset: float = 0 ## 按照时间重置，为则0不启用
@export var count_for_reset: int = 0 ## 按照发射次数重置，为0不启用
@export var reset_delay_mode: ResetDelayMode = ResetDelayMode.AFTER ## 重置延迟模式
@export var reset_delay_time: float = 0 ## 重置延迟时间
# 发射盘
@export_group("Disk", "disk_")
@export_range(0, 100, 1) var disk_count: int = 1 ## 发射盘数量
@export var disk_angle: float = 0.0 ## 发射盘环角度
@export var disk_range: float = 360.0 ## 发射盘范围 角度单位
@export var disk_radius: float = 0.0 ## 发射盘半径
# 发射条
@export_group("Stripe", "stripe_")
@export_range(0, 100, 1) var stripe_count: int = 1 ## 发射条数量
@export var stripe_angle: float = 0.0 ## 发射条角度
@export var stripe_range: float = 360.0 ## 发射条范围 角度单位
@export var stripe_radius: float = 0.0 ## 发射条半径
# 球面均匀分布 Spherical uniform distribution
@export_group("Spherical")
@export var ues_spherical: bool = false ## 使用球面均匀分布
@export_range(1, 1000, 1) var spherical_count: float = 100 ## 球面发射数量
@export var ratio: float = 1.0 ## 公比 黄金分割
# 弹幕
@export_group("Bullet")
@export var bullet_scene: PackedScene = preload("res://assets/danmaku/bullet/test_bullet.tscn") ## 类型 发射的弹幕预制体
@export var bullet_mass: float = 1.0 ## 质量
# 消除处理
@export_range(0, 20000) var bullet_max_node: int = 2000 ## 下属的最大弹幕数量
@export var bullet_lifetime: float = 10.0 ## 生存时间 秒
@export var bullet_collision_enabled: bool = true ## 碰撞消除
@export var exceeding_the_cap_mode: CapMode = CapMode.STOP_LAUNCHING ## 超出容量处理模式
# 移动
@export var bullet_speed: float = 1.0 ## 弹幕速度
@export var bullet_acceleration: Vector3 = Vector3.ZERO ## 弹幕加速度
@export var bullet_rotation: Vector3 = Vector3.ZERO ## 弹幕旋转
# 特效
@export_color_no_alpha var bullet_color: Color = Color(1, 1, 1) ## 颜色
@export var bullet_scale: Vector3 = Vector3.ONE ## 缩放
@export var bullet_blend_mode: int = 0 ## 混合模式
@export var spawn_effect: PackedScene = null ## 生成特效
@export var destroy_effect: PackedScene = null ## 消除特效
@export var trail_effect: PackedScene = null ## 拖影特效
# @export var  ## 忽略……
@export_group("DebugDisplay")
@export var disk_debug_display: bool = true ## 显示发射盘
@export var stripe_debug_display: bool = true ## 显示发射条
@export var display_radius: float = 2.0 ## Debug显示半径


# 弹幕绘制
var bullet_multi_mesh_instances: Array = [] # MultiMeshInstance3D
var bullet_multi_meshs: Array = [] # MultiMesh
# 其他全局变量或属性...
var is_first_fire: bool = true ## 是否是第一帧
var direction_vector: Vector3 ## 发射器朝向 方向向量
var bullets: Array = [] ## 存储发射的弹幕
var number_of_launches_in_this_frame: int = 0 ## 这一帧内的发射次数
# 计时，计数
var time_since_last_fire: float = 0.0 ## 自上次发射以来的时间
var time_since_last_reset: float = 0.0 ## 自上次重置以来的时间
var count_since_last_reset: int = 0 ## 自上次重置以来的次数
# 发射位置数组
var disk_positions: Array = []
var rotation_matrixs: Array = []
var curve_points: Array = []
var stripe_fire_positions: Array = []
var stripe_targets: Array = []
# 球形均匀分布数组
var spherical_targets: Array = []
# DebugDisplay
#var debug_display: DebugDisplay
#var use_debug_draw: bool = true

var reset_data: Dictionary
"""
danmaku_break
DANMAKU_BREAK
"""
const DANMAKU_BREAK = preload("res://assets/special_effects/danmaku_break.tscn")
const BULLETS_MULTI_MESH_INSTANCE_3D = preload("res://assets/danmaku/bullets_multi_mesh_instance_3d.tscn")
const BULLET_BASE_AREA_3D = preload("res://assets/danmaku/bullet_base_area_3d.tscn")

func _ready() -> void:
	if not Engine.is_editor_hint():
		bullet_multi_mesh_instances.clear()
		bullet_multi_meshs.clear()

		# 获取要绘制的mesh
		var bullet_meshs = []
		var bullet = bullet_scene.instantiate()
		if bullet is MeshInstance3D:
			bullet_meshs.append(bullet.mesh)
		for child in bullet.get_children():
			if child is MeshInstance3D:
				bullet_meshs.append(child.mesh)

		# 配置绘制的mesh
		for i in bullet_meshs.size():
			var bullets_multi_mesh_instance = BULLETS_MULTI_MESH_INSTANCE_3D.instantiate()#.duplicate(DUPLICATE_USE_INSTANTIATION)
			bullet_multi_mesh_instances.append(bullets_multi_mesh_instance)
			self.add_child(bullets_multi_mesh_instance)
			bullets_multi_mesh_instance.multimesh.mesh = bullet_meshs[i]
			bullet_multi_meshs.append(bullets_multi_mesh_instance.multimesh)


		save_properties()
		ready()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		if ues_spherical:
			calculate_spherical_uniform_distribution()
		else:
			calculate_stripe_rotation()
		debug_display()

	if not Engine.is_editor_hint():
		process_in_geme(delta)


# 要覆盖用的
func ready() -> void:
	pass
func bullet_event(_delta: float) -> void:
	pass


func process_in_geme(delta: float) -> void:
	# 更新基本属性
	direction_vector = -self.transform.basis.z
	velocity += acceleration * delta
	self.global_position += velocity * delta

	if firing:
		in_firing(delta)

	move_bullet(delta)
	draw_bullet(delta)
	delete_expired_bullets(delta)# 检查并删除超时的弹幕

	# 处理重置
	if reset_mode == ResetMode.TIME and time_for_reset > 0 and time_since_last_reset >= time_for_reset:
		time_since_last_reset = 0.0
		reset(delta)
	if reset_mode == ResetMode.COUNT and count_for_reset > 0 and count_since_last_reset >= count_for_reset:
		count_since_last_reset = 0
		reset(delta)


func reset(delta: float) -> void:
	load_properties()
	if reset_delay_mode == ResetDelayMode.AFTER and reset_delay_time > 0:
		var t = floor(reset_delay_time / delta) * delta
		time_since_last_fire -= t
		time_since_last_reset -= t


func in_firing(delta: float) -> void:
	# 处理初次发射
	if is_first_fire:
		is_first_fire = false
		if start_fire_once:
			time_since_last_fire += fire_period / FRAME_RATE
		if reset_delay_mode == ResetDelayMode.BEFORE and reset_delay_time > 0:
			var t = floor(reset_delay_time / delta) * delta # 没用
			time_since_last_fire -= t
			time_since_last_reset -= t

	if time_since_last_reset > 0:
		bullet_event(delta)
		spherical_count = clamp(spherical_count, 1, 1000)

	# 计数
	time_since_last_fire += delta
	time_since_last_reset += delta
	# 检查是否可以发射弹幕
	if time_since_last_fire >= fire_period / FRAME_RATE:
		time_since_last_fire = 0.0
		if ues_spherical:
			calculate_spherical_uniform_distribution()
		else:
			calculate_stripe_rotation()
		debug_display() # debug显示
		match exceeding_the_cap_mode: # 发射弹幕
			CapMode.STOP_LAUNCHING:
				if get_child_count(true) < bullet_max_node: # bullets.size()
					fire_bullet()
			CapMode.DELETE_OLDEST:
				#while bullets.size() > bullet_max_node:
					#var bullet = bullets.front()
					#bullets.erase(bullet)
					#bullet.queue_free()
				fire_bullet()
		count_since_last_reset += 1


# 移动弹幕
func move_bullet(delta: float) -> void:
	for bullet: Node3D in bullets:
		bullet.global_position += -bullet.global_transform.basis.z * bullet.speed * delta # 更新弹幕位置


func draw_bullet(delta: float) -> void:
	for i in bullet_multi_meshs.size():
		var multi_mesh: MultiMesh = bullet_multi_meshs[i]
		if multi_mesh.mesh == null:
			print("bullets_multi_mesh.mesh == null")
			return

		multi_mesh.instance_count = bullets.size()
		for j in range(bullets.size()):
			var bullet_pos = Transform3D()
			bullet_pos = bullet_pos.translated(bullets[j].global_position)
			multi_mesh.set_instance_transform(j, bullet_pos)


# 发射弹幕的函数
func fire_bullet() -> void:
	number_of_launches_in_this_frame = 0
	if ues_spherical:
		for i in range(1, int(spherical_count) + 1):
			var target: Vector3 = spherical_targets[i-1]
			set_bullet(center_position, target)
	else:
		for i in stripe_targets.size():
			var fire_pos: Vector3 = stripe_fire_positions[i]
			var target: Vector3 = stripe_targets[i]
			set_bullet(fire_pos, target)


func set_bullet(fire_pos: Vector3, target: Vector3) -> void:
	delete_out_cap_bullets()


	#var bullet_node = Node3D.new() # 制作空壳弹幕
	var bullet_node = BULLET_BASE_AREA_3D.instantiate() # 制作area3d弹幕
	bullet_node.set_script(bullet_scene.instantiate().get_script())
	var bullet_instance: Bullet = bullet_node # 实例化弹幕
	#var bullet_instance: Bullet = bullet_scene.instantiate() # 实例化弹幕 老的  用于单独的mesh实例

	add_child(bullet_instance)
	bullets.append(bullet_instance) # 存储已发射的弹幕
	number_of_launches_in_this_frame += 1

	var bullet_target = target + self.global_position + fire_pos
	if Vector3.UP.cross(bullet_target - bullet_instance.global_position) == Vector3.ZERO:
		bullet_instance.look_at(bullet_target, Vector3.FORWARD)
	else:
		bullet_instance.look_at(bullet_target)

	bullet_instance.position = fire_pos # 设定弹幕位置
	bullet_instance.speed = bullet_speed # 需要在弹幕脚本中定义speed属性
	bullet_instance.lifetime = bullet_lifetime # 设定弹幕的生存时间
	bullet_instance.scale = bullet_scale


func delete_out_cap_bullets() -> void:
	if exceeding_the_cap_mode == CapMode.DELETE_OLDEST:
		if get_child_count(true) > bullet_max_node and bullets.size() > 0:
			var bullet = bullets.front()
			delete_bullet(bullet)


func delete_expired_bullets(delta: float) -> void:
	for bullet: Node in bullets:
		if bullet.lifetime > 0:
			bullet.lifetime -= delta
		else:
			delete_bullet(bullet)


func delete_bullet(bullet: Bullet) -> void:
	bullets.erase(bullet)
	if not destroy_effect:
		bullet.queue_free()
		return
	var danmaku_break: AnimatedSprite3D = destroy_effect.instantiate()
	Global.effects.add_child(danmaku_break)
	danmaku_break.global_position = bullet.global_position
	bullet.queue_free()
	# ↓消失特效
	var rand_size: float = 0.1
	danmaku_break.global_position += (
		Vector3(randf(), randf(), randf() )
		- Vector3(rand_size, rand_size, rand_size)
		* 0.5
		) * rand_size

	danmaku_break.modulate = bullet_color
	danmaku_break.modulate.s = 0.8
	danmaku_break.modulate.v = 1.0

	danmaku_break.flip_h = randi_range(0, 1)
	danmaku_break.flip_v = randi_range(0, 1)
	danmaku_break.speed_scale += randf_range(-1, 1) * 0.1

	danmaku_break.scale *= bullet.bullet_radius
	await danmaku_break.animation_finished
	danmaku_break.queue_free()



func calculate_stripe_rotation() -> void:
	disk_positions.clear()
	rotation_matrixs.clear()
	curve_points.clear()
	stripe_fire_positions.clear()
	stripe_targets.clear()

	var range_angle = abs(stripe_range)
	var a = 270 - range_angle / 2.0  + stripe_angle
	var disk_offset = disk_range / 2.0

	for i: float in disk_count:
		var rota = Vector3.ZERO
		rota.z = (disk_range / disk_count) * (i+0.5)
		rota.z += disk_angle - disk_offset
		rota.z = deg_to_rad(rota.z)
		var rotation_matrix = Transform3D(Basis.from_euler(rota), Vector3.ZERO)
		var rotated_normal = Vector3.UP.rotated(Vector3.UP, a) * disk_radius
		var disk_pos = center_position + rotated_normal
		disk_positions.append(disk_pos)
		rotation_matrixs.append(rotation_matrix)

	for j: float in stripe_count:
		var angle = a + (range_angle / stripe_count) * (j+0.5) # 计算当前角度
		angle = deg_to_rad(angle)
		var curve_point = center_position + Vector3(cos(angle), 0, sin(angle) ) # 计算每个点
		curve_points.append(curve_point)

	for i in disk_count:
		for j in stripe_count:
			var fire_pos = disk_positions[i] + stripe_radius * (curve_points[j] - center_position)
			stripe_fire_positions.append(fire_pos * rotation_matrixs[i] )
			stripe_targets.append(curve_points[j] * rotation_matrixs[i] )


func calculate_spherical_uniform_distribution() -> void:
	if not ues_spherical:
		return
	spherical_targets.clear()

	for i in range(1, int(spherical_count) + 1):
		var high: float = (2*i -1) / floor(spherical_count) - 1
		var radius = sqrt(1-pow(high, 2))
		var theta = TAU * i * pow(GOLDEN_RATIO, ratio)

		var point: Vector3 = Vector3(
			radius * cos(theta),
			high,
			radius * sin(theta)
			) * display_radius

		spherical_targets.append(point)

	#方型造型术？
	#radius * cos(theta)**2 * sign(cos(theta)),
	#0, #sqrt(abs(1 - pow(radius, 2) ) ) * pow(-1, i),
	#radius * sin(theta)**2 * sign(sin(theta))


var Here_is_the_last_one
func save_properties() -> void:
	reset_data.clear()
	reset_data = inst_to_dict(self).duplicate()
	reset_data.erase("reset_data")
	for key in reset_data.keys():
		if key is String:
			if "@" in key or key.begins_with("_") or "count_since_last_reset" in key:
				reset_data.erase(key)

	# 可选杀了继承的
	if only_reset_Dispenser_class:
		var keys_to_remove: Array = []
		var found = false
		for key in reset_data.keys():
			if found:
				keys_to_remove.append(key)
			if key == "Here_is_the_last_one":
				found = true
		for key in keys_to_remove:
			reset_data.erase(key)


func load_properties() -> void:
	for propertie in reset_data:
		if reset_data.has(propertie):
			self.set(propertie, reset_data[propertie])



"""
下面是debug_display，画画的
"""



func debug_display() -> void:
	clear_mesh(mesh) # 调用清除线条函数

	if ues_spherical and spherical_targets.size() > 0:
		var pointsA: PackedVector3Array = []
		var pointsB: PackedVector3Array = []
		for p in int(spherical_count):
			var point: Vector3 = spherical_targets[p] * display_radius
			pointsA.append(point)
			pointsB.append(spherical_targets[p].normalized() * 0.1)
		draw_mesh_line_repet_relative(mesh, pointsA, pointsB, Color.RED, 10, 0)
		return

	if disk_debug_display and disk_positions.size() > 0:
		var range_angle = abs(stripe_range)
		var a = 270 - range_angle / 2.0  + stripe_angle
		for i in disk_count:
			draw_pie_slice(mesh, disk_positions[i], display_radius, a, range_angle, Color.ORANGE_RED, rotation_matrixs[i])
	if stripe_debug_display and stripe_fire_positions.size() > 0:
		for j in stripe_targets.size():
			draw_mesh_line_relative(mesh, stripe_fire_positions[j], stripe_targets[j] * display_radius, Color.BLUE, 3, 0.2)


func clear_mesh(immediatemesh) -> void:
	if not immediatemesh is ImmediateMesh:
		return
	immediatemesh.clear_surfaces()


func draw_mesh_line_relative(immediatemesh, pointA: Vector3, pointB: Vector3, color: Color = Color.BLACK, thickness: float = 2, pointyEnd: float = 1) -> void: # 网格线，均匀
	if not immediatemesh is ImmediateMesh:
		return
	var imesh: ImmediateMesh = immediatemesh
	pointB = pointA + pointB # 计算线条终点
	if pointA.is_equal_approx(pointB):
		return
	imesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	imesh.surface_set_color(color)
	# 开始绘制线条
	var dir: Vector3 = pointA.direction_to(pointB) # 计算pointA指向pointB的方向
	var normal: Vector3 = Vector3( - dir.y, dir.x, 0).normalized() \
		if (abs(dir.x) + abs(dir.y) > EPISILON) \
		else Vector3(0, -dir.z, dir.y).normalized() # 计算法线向量
	normal *= thickness / SCALE_FACTOR # 计算法线向量的长度
	# 定义一个顶点顺序数组，用于绘制三角形条带
	var localB = (pointB - pointA) # 计算线段的局部方向
	for v in range(14): # 遍历顶点顺序数组
		var vertex = normal \
			if VERTICES_STRIP_ORDER[v] < 4 \
			else normal * pointyEnd + localB # 根据顶点顺序数组的值，计算顶点的位置
		var final_vert = vertex.rotated(dir, PI * (0.5 * (VERTICES_STRIP_ORDER[v] % 4) + 0.25)) # 将顶点绕dir旋转
		final_vert += pointA # 将顶点移动到正确的位置
		imesh.surface_add_vertex(final_vert) # 添加顶点到表面
	imesh.surface_end() # 结束绘制三角形条带


func draw_mesh_line_repet_relative(immediatemesh, pointsA: PackedVector3Array, pointsB: PackedVector3Array, color: Color = Color.BLACK, thickness: float = 2, pointyEnd: float = 1) -> void: # 网格线，均匀
	if not immediatemesh is ImmediateMesh:
		print_debug("not immediatemesh is ImmediateMesh")
		return
	if not pointsA.size() == pointsB.size():
		print_debug("not pointsA.size() == pointsB.size()")
		return

	var imesh: ImmediateMesh = immediatemesh
	imesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	imesh.surface_set_color(color)

	for i in pointsA.size():
		var pointA = pointsA[i]
		var pointB = pointsB[i]
		pointB = pointA + pointB # 计算线条终点
		if pointA.is_equal_approx(pointB):
			continue
		# 开始绘制线条
		var dir: Vector3 = pointA.direction_to(pointB) # 计算pointA指向pointB的方向
		var normal: Vector3 # 计算法线向量
		if abs(dir.x) + abs(dir.y) > EPISILON:
			normal = Vector3(-dir.y, dir.x, 0).normalized()
		else:
			normal = Vector3(0, -dir.z, dir.y).normalized()
		normal *= thickness / SCALE_FACTOR # 计算法线向量的长度
		# 定义一个顶点顺序数组，用于绘制三角形条带
		var localB = (pointB - pointA) # 计算线段的局部方向

		for v in range(14): # 遍历顶点顺序数组
			var vertex: Vector3 # 根据顶点顺序数组的值，计算顶点的位置
			if VERTICES_STRIP_ORDER[v] < 4:
				vertex = normal
			else:
				vertex = normal * pointyEnd + localB
			var final_vert = vertex.rotated(dir, PI * (0.5 * (VERTICES_STRIP_ORDER[v] % 4) + 0.25)) # 将顶点绕dir旋转
			final_vert += pointA # 将顶点移动到正确的位置
			imesh.surface_add_vertex(final_vert) # 添加顶点到表面
	imesh.surface_end() # 结束绘制三角形条带


func draw_pie_slice(immediatemesh, center: Vector3, radius: float, start_angle: float, angle_span: float, color: Color, rotation_matrix: Transform3D = Transform3D.IDENTITY) -> void: # 添加旋转向量参数
	if not immediatemesh is ImmediateMesh:
		return
	radius = abs(radius)
	start_angle = deg_to_rad(start_angle)
	angle_span = deg_to_rad(angle_span)

	# 填充扇形
	immediatemesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP) # 开始绘制三角形扇
	immediatemesh.surface_set_color(color) # 设置颜色
	immediatemesh.surface_add_vertex(center * rotation_matrix) # 添加圆心经过旋转变换后的位置

	# 添加沿着扇形边界的点
	var num_segments = max(int(angle_span / (PI / 18)), 1)
	var angle_increment = angle_span / num_segments # 每段的角度增量
	for i in range(num_segments + 1):
		var angle = start_angle + angle_increment * i # 计算当前角度
		var curve_point = center + Vector3(radius * cos(angle), 0, radius * sin(angle)) # 计算每个点
		# 应用旋转
		immediatemesh.surface_add_vertex(curve_point * rotation_matrix) # 添加当前点经过旋转变换后的位置
		immediatemesh.surface_add_vertex(center * rotation_matrix) # 添加圆心经过旋转变换后的位置
	immediatemesh.surface_end() # 结束绘制


func draw_line(immediatemesh, pointA: Vector3, pointB: Vector3, color: Color = Color.RED) -> void: # 画线函数
	if not immediatemesh is ImmediateMesh:
		return
	if pointA.is_equal_approx(pointB):
		return # 退出函数
	immediatemesh.surface_begin(Mesh.PRIMITIVE_LINES) # 开始绘制线条
	immediatemesh.surface_set_color(color) # 设置线条颜色
	immediatemesh.surface_add_vertex(pointA) # 添加线条起点
	immediatemesh.surface_add_vertex(pointB) # 添加线条终点
	immediatemesh.surface_end() # 结束绘制线条


func draw_line_relative(immediatemesh, pointA: Vector3, pointB: Vector3, color: Color = Color.RED) -> void: # 画相对线条函数
	if not immediatemesh is ImmediateMesh:
		return
	draw_line(immediatemesh, pointA, pointA + pointB, color) # 调用画线函数，起点为pointA，终点为pointA+pointB
