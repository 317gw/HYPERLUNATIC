extends Node
# F2开关

const SCALE_FACTOR: float = 100.0 # 设置比例因子为100.0
const EPISILON = 0.00001 # 设置一个极小值
const VERTICES_STRIP_ORDER = [4, 5, 0, 1, 2, 5, 6, 4, 7, 0, 3, 2, 7, 6]

var draw_debug_mesh: ImmediateMesh
var draw_statical: ImmediateMesh
var use_debug_draw: bool = true # 创建一个布尔变量use_debug_draw，默认值为true
var camera: Camera3D
var polylines: Array = []
var multilines: Array = []

@onready var draw_debug: MeshInstance3D = $DrawDebugMesh
@onready var statical_mesh: MeshInstance3D = $StaticalMesh
@onready var draw_debug_control: Control = $DrawDebugControl # 继承自的CanvasItem类可以进行绘制
@onready var multi_mesh_instance: MultiMeshInstance3D = $MultiMeshInstance3D


func _ready() -> void: # 就绪函数
	draw_debug_mesh = draw_debug.mesh # 获取draw_debug的网格
	draw_statical = statical_mesh.mesh
	camera = get_viewport().get_camera_3d()
	draw_debug_control.draw.connect(_draw_canvas)
	multi_mesh_instance.multimesh.mesh = _get_wireframe_cube()


func _init() -> void: # 初始化函数
	if not InputMap.has_action("draw_debug"): # 如果输入映射中没有名为draw_debug的动作
		InputMap.add_action("draw_debug") # 添加名为draw_debug的输入动作
		var event := InputEventKey.new() # 创建一个新的输入事件
		event.keycode = KEY_F2 # 设置输入事件的键码为F2
		InputMap.action_add_event("draw_debug", event) # 将输入事件添加到draw_debug动作中


func _input(event: InputEvent) -> void: # 输入事件处理函数
	if event.is_action_pressed("draw_debug"): # 如果事件是按下draw_debug动作
		use_debug_draw = !use_debug_draw # 将switch的值转换为布尔类型并赋给use_debug_draw


func _physics_process(_delta: float) -> void: # 物理处理函数
	draw_debug_mesh.clear_surfaces() # 清除draw_debug_mesh的表面
	#clearLines() # 调用清除线条函数
	camera = get_viewport().get_camera_3d()
	draw_debug_control.queue_redraw()

func clearLines(): # 清除线条函数
	if draw_debug_mesh is ImmediateMesh: # 如果draw_debug_mesh是ImmediateMesh类型
		draw_debug_mesh.clear_surfaces() # 清除draw_debug_mesh的表面


func draw_line(pointA: Vector3, pointB: Vector3, color: Color = Color.RED, immediate_mesh: ImmediateMesh = draw_debug_mesh): # 画线函数
	if not use_debug_draw or pointA.is_equal_approx(pointB): # 如果不使用调试绘制或者pointA与pointB近似相等
		return # 退出函数
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES) # 开始绘制线条
	immediate_mesh.surface_set_color(color) # 设置线条颜色
	immediate_mesh.surface_add_vertex(pointA) # 添加线条起点
	immediate_mesh.surface_add_vertex(pointB) # 添加线条终点
	immediate_mesh.surface_end() # 结束绘制线条


func draw_line_relative(pointA: Vector3, pointB: Vector3, color: Color=Color.RED): # 画相对线条函数
	draw_line(pointA, pointA + pointB, color) # 调用画线函数，起点为pointA，终点为pointA+pointB


func draw_mesh_line(pointA: Vector3, pointB: Vector3, thickness: float=2.0, color: Color=Color.BLACK, pointyEnd: float=1.0): # 网格线，均匀
	if not use_debug_draw or pointA.is_equal_approx(pointB):
		return
	if draw_debug_mesh is ImmediateMesh:
		draw_debug_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		draw_debug_mesh.surface_set_color(color)
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
			draw_debug_mesh.surface_add_vertex(final_vert) # 添加顶点到表面
		draw_debug_mesh.surface_end() # 结束绘制三角形条带


func draw_mesh_line_relative(pointA: Vector3, pointB: Vector3, thickness: float=2.0, color: Color=Color.BLACK, pointyEnd: float=1.0): # 网格线，均匀
	pointB = pointA + pointB # 计算线条终点
	draw_mesh_line(pointA, pointB, thickness, color, pointyEnd)


func draw_line_cube(transform: Transform3D = Transform3D.IDENTITY, color: Color = Color.RED):
	if not use_debug_draw:
		return

	var cube_vertices := []
	for i in range(MarchingTable.POINTS.size()): # 应用变换
		cube_vertices.append(transform * Vector3(MarchingTable.POINTS[i]))

	for edge in MarchingTable.EDGES: # 绘制立方体的12条边
		var p1 = cube_vertices[edge[0]]
		var p2 = cube_vertices[edge[1]]
		draw_line(p1, p2, color, draw_statical)


func _get_wireframe_cube() -> ArrayMesh:
	var vertices:= PackedVector3Array()

	for edge in MarchingTable.EDGES: # 绘制立方体的12条边
		var p1 = MarchingTable.POINTS[edge[0]]
		var p2 = MarchingTable.POINTS[edge[1]]
		vertices.push_back(p1)
		vertices.push_back(p2)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices

	var array_mesh = ArrayMesh.new()
	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return array_mesh


func draw_multi_line_cube(transforms: Array[Transform3D]):
	multi_mesh_instance.multimesh.set_instance_count(transforms.size())
	for i in transforms.size():
		multi_mesh_instance.multimesh.set_instance_transform(i, transforms[i])





func _draw_canvas():
	if polylines.size() > 0:
		for line in polylines:
			if line["points"].size() > 0:
				draw_debug_control.draw_polyline(line["points"], line["color"], line["width"], line["antialiased"])
		polylines.clear()

	if multilines.size() > 0:
		for line in multilines:
			if line["points"].size() > 0:
				draw_debug_control.draw_multiline(line["points"], line["color"], line["width"], line["antialiased"])
		multilines.clear()


func draw_line_cube_canvas(transform: Transform3D = Transform3D.IDENTITY, color: Color = Color.RED, width: float = -1.0, antialiased: bool = false):
	if not use_debug_draw:
		return
	var cube_vertices := []
	var lines: PackedVector2Array
	for i in range(MarchingTable.POINTS.size()): # 应用变换
		cube_vertices.append(transform * Vector3(MarchingTable.POINTS[i]))

	for edge in MarchingTable.EDGES: # 绘制立方体的12条边
		var p1 = cube_vertices[edge[0]]
		var p2 = cube_vertices[edge[1]]
		#draw_line(p1, p2)
		if is_line3d_behind_camera(p1, p2):
			continue
		p1 = camera.unproject_position(p1)
		p2 = camera.unproject_position(p2)
		lines.append(p1)
		lines.append(p2)
	multilines.append({"points": lines, "color": color, "width": width, "antialiased": antialiased})


func draw_line_canvas(points: PackedVector3Array, color: Color = Color.RED, width: float = -1.0, antialiased: bool = false):
	var lines: PackedVector2Array
	for i in range(len(points) -1):
		if is_line3d_behind_camera(points[i], points[i+1]):
			return
		var p1 = camera.unproject_position(points[i])
		var p2 = camera.unproject_position(points[i+1])
		lines.append(p1)
		lines.append(p2)
	#draw_debug_control.draw_line(p1, p2, color, width, antialiased)
	polylines.append({"points": lines, "color": color, "width": width, "antialiased": antialiased})


func is_line3d_behind_camera(pointA: Vector3, pointB: Vector3) -> bool:
	return camera.is_position_behind(pointA) or camera.is_position_behind(pointB)










































# ↓也许对了 但是更慢
func draw_chunks(chunks: Dictionary, size: Vector3, color: Color = Color.RED, width: float = -1.0, antialiased: bool = false):
	var edges: Array[AxisEdge]
	for i in chunks.keys():
		#edges.append(vectors_to_edge(chunks[i], chunks[i+1]))
		var cube_vertices := []
		var transform = chunks[i].global_transform.scaled_local(size)
		for j in range(MarchingTable.POINTS.size()): # 应用变换
			cube_vertices.append(transform * Vector3(MarchingTable.POINTS[j]))

		for edge in MarchingTable.EDGES: # 绘制立方体的12条边
			var p1 = cube_vertices[edge[0]]
			var p2 = cube_vertices[edge[1]]
			#draw_line(p1, p2)
			if is_line3d_behind_camera(p1, p2):
				continue
			edges.append(AxisEdge.new(p1, p2))

	var edges2 = merge_edges(edges)
	var lines: PackedVector2Array
	for edge in edges2:
		var p1 = edge.to_vertices()[0]
		var p2 = edge.to_vertices()[1]
		p1 = camera.unproject_position(p1)
		p2 = camera.unproject_position(p2)
		lines.append(p1)
		lines.append(p2)
	multilines.append({"points": lines, "color": color, "width": width, "antialiased": antialiased})


# class_name AxisEdge extends RefCounted
class AxisEdge:
	var vertex_a: Vector3  # 边的起点顶点
	var vertex_b: Vector3  # 边的终点顶点
	# 自动计算的元信息（用于合并）
	var dir: String        # 方向 (x/y/z)
	var plane: Vector2     # 平面坐标 (根据方向自动提取)
	var start: float       # 起始坐标
	var end: float         # 结束坐标

	# 构造函数：通过两个顶点初始化
	func _init(a: Vector3, b: Vector3):
		vertex_a = a
		vertex_b = b
		_calculate_properties()

	# 内部方法：根据顶点计算方向、平面、起点和终点
	func _calculate_properties():
		# 确定边的主方向（x/y/z）
		var delta = vertex_b - vertex_a
		if abs(delta.x) > 0:
			dir = "x"
			plane = Vector2(vertex_a.y, vertex_a.z)
		elif abs(delta.y) > 0:
			dir = "y"
			plane = Vector2(vertex_a.x, vertex_a.z)
		else:
			dir = "z"
			plane = Vector2(vertex_a.x, vertex_a.y)

		# 确保起点 < 终点
		if dir == "x":
			start = min(vertex_a.x, vertex_b.x)
			end = max(vertex_a.x, vertex_b.x)
		elif dir == "y":
			start = min(vertex_a.y, vertex_b.y)
			end = max(vertex_a.y, vertex_b.y)
		else:
			start = min(vertex_a.z, vertex_b.z)
			end = max(vertex_a.z, vertex_b.z)

	# 将边转换为两个顶点（直接返回存储的顶点）
	func to_vertices() -> Array[Vector3]:
		return [vertex_a, vertex_b]


func merge_edges(edges: Array[AxisEdge]) -> Array[AxisEdge]:
	var merged = {}  # 分组存储 { "方向_平面坐标": [区间列表] }

	# 按方向和平面分组
	for edge in edges:
		var key = "%s_%s_%s" % [edge.dir, edge.plane.x, edge.plane.y]
		if not merged.has(key):
			merged[key] = []
		merged[key].append([edge.start, edge.end])

	var result: Array[AxisEdge] = []

	# 合并每组区间并生成新边
	for key in merged:
		var dir_plane = key.split("_")
		var dir = dir_plane[0]
		var plane = Vector2(float(dir_plane[1]), float(dir_plane[2]))

		var intervals = merged[key]
		intervals.sort()  # 按起点排序

		var merged_intervals = []
		for interval in intervals:
			if merged_intervals.is_empty():
				merged_intervals.append(interval)
			else:
				var last = merged_intervals[-1]
				if interval[0] <= last[1]:  # 合并重叠或连续的区间
					merged_intervals[-1][1] = max(last[1], interval[1])
				else:
					merged_intervals.append(interval)

		# 生成合并后的边
		for interval in merged_intervals:
			var start = interval[0]
			var end = interval[1]

			# 根据方向和平面重建顶点
			var a: Vector3
			var b: Vector3
			match dir:
				"x":
					a = Vector3(start, plane.x, plane.y)
					b = Vector3(end, plane.x, plane.y)
				"y":
					a = Vector3(plane.x, start, plane.y)
					b = Vector3(plane.x, end, plane.y)
				"z":
					a = Vector3(plane.x, plane.y, start)
					b = Vector3(plane.x, plane.y, end)
			result.append(AxisEdge.new(a, b))

	return result
