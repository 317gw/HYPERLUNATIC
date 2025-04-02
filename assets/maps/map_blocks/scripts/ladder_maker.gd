@tool
extends Node3D

@export var reset: bool = false
@export var ladder_thickness: float = 0.1 # 总体梯子的厚度
@export var ladder_width: float = 0.7 # 梯子的宽度
@export var step_count: int = 7 # 阶梯数量
@export var step_space: float = 0.4 # 阶梯间距
@export var step_length_multi: float = 1.2 # 阶梯长度
@export var step_thickness: float = 0.04 # 阶梯厚度
@export var pole_radius_add: float = 0.02 # 两侧圆柱半径

var ladder_height: float

@onready var ladder_mi_3d: MeshInstance3D = $LadderMI3D


func _ready() -> void:
	if not Engine.is_editor_hint():
		generate_ladder()

		# 生成碰撞
		ladder_mi_3d.create_trimesh_collision()
		for child in ladder_mi_3d.get_children():
			if not child is StaticBody3D:
				continue
			for c2 in child.get_children():
				if not c2 is CollisionShape3D:
					continue
				var collsion: CollisionShape3D = c2.duplicate()
				self.add_child(collsion, true)
				collsion.transform = ladder_mi_3d.transform
			child.queue_free()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():

		if reset:
			reset = false
			generate_ladder()
			pass


func generate_ladder() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	ladder_height = step_count * step_space
	# 生成两侧圆柱
	generate_pole(st, -ladder_width/2, ladder_thickness/2 + pole_radius_add, ladder_height)
	generate_pole(st, ladder_width/2, ladder_thickness/2 + pole_radius_add, ladder_height)

	st.set_smooth_group(-1)
	# 生成阶梯
	var step_spacing = ladder_height / (step_count + 1)
	for i in range(step_count):
		var z_pos = -ladder_height/2 + (i + 1) * step_spacing
		generate_step(st, z_pos)

	# 创建网格
	st.generate_normals()
	ladder_mi_3d.mesh = st.commit()
	ladder_mi_3d.position.y = ladder_height/2


# 生成单根圆柱
func generate_pole(st: SurfaceTool, x_pos: float, radius: float, height: float) -> void:
	var segments = 8  # 圆柱分段数
	var angle_step = TAU / segments

	# 圆柱侧面
	for i in range(segments):
		var angle1 = i * angle_step
		var angle2 = (i + 1) % segments * angle_step

		var x1 = radius * cos(angle1)
		var y1 = radius * sin(angle1)
		var x2 = radius * cos(angle2)
		var y2 = radius * sin(angle2)

		# 底部顶点
		var bottom1 = Vector3(x_pos + x1, y1, -height/2)
		var bottom2 = Vector3(x_pos + x2, y2, -height/2)

		# 顶部顶点
		var top1 = Vector3(x_pos + x1, y1, height/2)
		var top2 = Vector3(x_pos + x2, y2, height/2)

		st.set_smooth_group(0)
		# 侧面四边形（两个三角形）
		st.add_vertex(bottom1)
		st.add_vertex(top1)
		st.add_vertex(top2)

		st.add_vertex(bottom1)
		st.add_vertex(top2)
		st.add_vertex(bottom2)

		st.set_smooth_group(-1)
		# 添加底面
		st.add_vertex(bottom1)
		st.add_vertex(bottom2)
		st.add_vertex(Vector3(x_pos, 0, -height/2))

		# 添加顶面
		st.add_vertex(top1)
		st.add_vertex(Vector3(x_pos, 0, height/2))
		st.add_vertex(top2)


# 生成单个阶梯
func generate_step(st: SurfaceTool, z_pos: float) -> void:
	var half_thickness = step_thickness / 2
	var half_length = ladder_thickness / 2
	var half_width = (ladder_width / 2 - (ladder_thickness/2 + pole_radius_add)) * step_length_multi  # 稍微向内缩进

	# 阶梯的8个顶点
	var vertices = [
		# 前面
		Vector3(-half_width, -half_length, z_pos - half_thickness),
		Vector3(half_width, -half_length, z_pos - half_thickness),
		Vector3(half_width, half_length, z_pos - half_thickness),
		Vector3(-half_width, half_length, z_pos - half_thickness),
		# 后面
		Vector3(-half_width, -half_length, z_pos + half_thickness),
		Vector3(half_width, -half_length, z_pos + half_thickness),
		Vector3(half_width, half_length, z_pos + half_thickness),
		Vector3(-half_width, half_length, z_pos + half_thickness)
	]

	# 定义立方体的6个面（每个面2个三角形）
	var faces = [
		# 前面
		[0, 1, 2], [0, 2, 3],
		# 后面
		[5, 4, 7], [5, 7, 6],
		# 上面
		[3, 2, 6], [3, 6, 7],
		# 下面
		[4, 5, 1], [4, 1, 0],
		# 左面
		[4, 0, 3], [4, 3, 7],
		# 右面
		[1, 5, 6], [1, 6, 2]
	]

	# 添加所有面
	for face in faces:
		for index in face:
			st.add_vertex(vertices[index])
