extends Node
# F2开关

const SCALE_FACTOR: float = 100.0 # 设置比例因子为100.0
const EPISILON = 0.00001 # 设置一个极小值
const VERTICES_STRIP_ORDER = [4, 5, 0, 1, 2, 5, 6, 4, 7, 0, 3, 2, 7, 6]

@export_range(0, 1, 1) var switch: int = 1 # 创建一个整数变量switch，范围为0到1，默认值为1

var draw_debug_mesh: ImmediateMesh
var use_debug_draw: bool = true # 创建一个布尔变量use_debug_draw，默认值为true

@onready var draw_debug: MeshInstance3D = $DrawDebugMesh


func _ready() -> void: # 就绪函数
	draw_debug_mesh = draw_debug.mesh # 获取draw_debug的网格


func _init() -> void: # 初始化函数
	if not InputMap.has_action("draw_debug"): # 如果输入映射中没有名为draw_debug的动作
		InputMap.add_action("draw_debug") # 添加名为draw_debug的输入动作
		var event := InputEventKey.new() # 创建一个新的输入事件
		event.keycode = KEY_F2 # 设置输入事件的键码为F2
		InputMap.action_add_event("draw_debug", event) # 将输入事件添加到draw_debug动作中


func _input(event: InputEvent) -> void: # 输入事件处理函数
	if event.is_action_pressed("draw_debug"): # 如果事件是按下draw_debug动作
		switch = 1 - switch # 切换switch的值
		use_debug_draw = switch as bool # 将switch的值转换为布尔类型并赋给use_debug_draw


func _physics_process(_delta: float) -> void: # 物理处理函数
	clearLines() # 调用清除线条函数


func clearLines(): # 清除线条函数
	if draw_debug_mesh is ImmediateMesh: # 如果draw_debug_mesh是ImmediateMesh类型
		draw_debug_mesh.clear_surfaces() # 清除draw_debug_mesh的表面


func draw_line(pointA: Vector3, pointB: Vector3, color: Color=Color.RED): # 画线函数
	if not use_debug_draw or pointA.is_equal_approx(pointB): # 如果不使用调试绘制或者pointA与pointB近似相等
		return # 退出函数
	if draw_debug_mesh is ImmediateMesh: # 如果draw_debug_mesh是ImmediateMesh类型
		draw_debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES) # 开始绘制线条
		draw_debug_mesh.surface_set_color(color) # 设置线条颜色
		draw_debug_mesh.surface_add_vertex(pointA) # 添加线条起点
		draw_debug_mesh.surface_add_vertex(pointB) # 添加线条终点
		draw_debug_mesh.surface_end() # 结束绘制线条


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
