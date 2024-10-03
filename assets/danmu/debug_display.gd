@tool
class_name DebugDisplay
extends MeshInstance3D

const SCALE_FACTOR: float = 100.0 # 设置比例因子为100.0
const EPISILON = 0.00001 # 设置一个极小值
const VERTICES_STRIP_ORDER = [4, 5, 0, 1, 2, 5, 6, 4, 7, 0, 3, 2, 7, 6]

@export var display_disk: bool = true
@export var display_stripe: bool = true

#var dispenser: Dispenser
#var immediatemesh: ImmediateMesh
var use_debug_draw: bool = true # 创建一个布尔变量use_debug_draw，默认值为true

var center_pos: Vector3
var up: Vector3
var right: Vector3
var forward: Vector3


#func _ready() -> void:
	#pass
#
#func _process(delta: float) -> void:
	#if not self.mesh is ImmediateMesh:
		#self.mesh = ImmediateMesh.new()
	#if not immediatemesh == self.mesh:
		#immediatemesh = self.mesh


#func _physics_process(delta: float) -> void:
	#debug_display()


func debug_display(dispenser: Dispenser) -> void:
	clear_mesh(mesh) # 调用清除线条函数
	center_pos = dispenser.center_position
	up = dispenser.global_transform.basis.y
	right = dispenser.global_transform.basis.x
	forward = -dispenser.global_transform.basis.z
	# 发射器方向
	draw_mesh_line_relative(mesh, center_pos, forward * 2, Color.GREEN, 3, 0.1)

	# 发射盘
	if not display_disk and not display_stripe:
		return
	var range_angle = abs(dispenser.stripe_range)
	var a = 270 - range_angle / 2.0  + dispenser.stripe_angle
	var disk_offset = dispenser.disk_range / 2.0
	var radius = 2.0

	if Engine.is_editor_hint():
		for i: float in dispenser.disk_count:
			var rota = Vector3.ZERO
			rota.z = (dispenser.disk_range / dispenser.disk_count) * (i+0.5)
			rota.z += dispenser.disk_angle - disk_offset
			rota.z = deg_to_rad(rota.z)

			var rotation_matrix = Transform3D(Basis.from_euler(rota), Vector3.ZERO)
			var rotated_normal = Vector3.UP.rotated(Vector3.UP, a) * dispenser.disk_radius
			var disk_pos = center_pos + rotated_normal

			if display_disk:
				draw_pie_slice(mesh, disk_pos, radius, a, range_angle, Color.ORANGE_RED, rotation_matrix)

			if display_stripe:
				for j in range(dispenser.stripe_count):
					var angle = a + (range_angle / dispenser.stripe_count) * (j+0.5) # 计算当前角度
					angle = deg_to_rad(angle)
					var curve_point = center_pos + Vector3(radius * cos(angle), 0, radius * sin(angle) )
					var fire_pos = disk_pos + dispenser.stripe_radius * (curve_point - center_pos)
					draw_mesh_line_relative(mesh, fire_pos * rotation_matrix, curve_point * rotation_matrix, Color.BLUE, 3, 0.2)
	else:
		dispenser.calculate_stripe_rotation()
		if display_disk:
			for i in dispenser.disk_count:
				draw_pie_slice(mesh, dispenser.disk_positions[i], radius, a, range_angle, Color.ORANGE_RED, dispenser.rotation_matrixs[i])
		if display_stripe:
			for j in dispenser.stripe_targets.size():
				draw_mesh_line_relative(mesh, dispenser.stripe_fire_positions[j], dispenser.stripe_targets[j] * radius, Color.BLUE, 3, 0.2)


func clear_mesh(immediatemesh: ImmediateMesh) -> void:
	immediatemesh.clear_surfaces() # 清除draw_debug_mesh的表面


func draw_mesh_line_relative(immediatemesh: ImmediateMesh, pointA: Vector3, pointB: Vector3, color: Color = Color.BLACK, thickness: float = 2, pointyEnd: float = 1) -> void: # 网格线，均匀
	pointB = pointA + pointB # 计算线条终点
	if not use_debug_draw or pointA.is_equal_approx(pointB):
		return
	immediatemesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	immediatemesh.surface_set_color(color)
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
		immediatemesh.surface_add_vertex(final_vert) # 添加顶点到表面
	immediatemesh.surface_end() # 结束绘制三角形条带


func draw_pie_slice(immediatemesh: ImmediateMesh, center: Vector3, radius: float, start_angle: float, angle_span: float, color: Color, rotation_matrix: Transform3D = Transform3D.IDENTITY) -> void: # 添加旋转向量参数
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


#func draw_line(pointA: Vector3, pointB: Vector3, color: Color = Color.RED) -> void: # 画线函数
	#if not use_debug_draw or pointA.is_equal_approx(pointB): # 如果不使用调试绘制或者pointA与pointB近似相等
		#return # 退出函数
	#immediatemesh.surface_begin(Mesh.PRIMITIVE_LINES) # 开始绘制线条
	#immediatemesh.surface_set_color(color) # 设置线条颜色
	#immediatemesh.surface_add_vertex(pointA) # 添加线条起点
	#immediatemesh.surface_add_vertex(pointB) # 添加线条终点
	#immediatemesh.surface_end() # 结束绘制线条


#func draw_line_relative(pointA: Vector3, pointB: Vector3, color: Color = Color.RED) -> void: # 画相对线条函数
	#draw_line(pointA, pointA + pointB, color) # 调用画线函数，起点为pointA，终点为pointA+pointB


#func draw_circle(center: Vector3, radius: float, color: Color=Color.RED, segments: int=32) -> void: # 绘制圆的函数
	#var angle_step = (2 * PI) / segments # 计算每段的角度
	#for i in range(segments): # 遍历每一个段
		#var angle_a = angle_step * i # 当前段的起始角度
		#var angle_b = angle_step * (i + 1) # 当前段的结束角度
		#var pointA = center + Vector3(radius * cos(angle_a), 0, radius * sin(angle_a)) # 计算起点
		#var pointB = center + Vector3(radius * cos(angle_b), 0, radius * sin(angle_b)) # 计算终点
		#draw_line(pointA, pointB, color) # 绘制线条连接起点和终点
