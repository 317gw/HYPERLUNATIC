@tool
extends Node3D


const SCALE_FACTOR: float = 100.0 # 设置比例因子为100.0
const EPISILON: float = 0.00001 # 设置一个极小值
const VERTICES_STRIP_ORDER: Array = [4, 5, 0, 1, 2, 5, 6, 4, 7, 0, 3, 2, 7, 6, 0]

var pie_mash: ImmediateMesh

@onready var frameskiper: FrameSkiper = FrameSkiper.new(30)
@onready var emitter: DanmakuEmitter = $".."
@onready var disk_mmi: MultiMeshInstance3D = $DiskMMI3D
@onready var stripe_mmi: MultiMeshInstance3D = $StripeMMI3D
@onready var spherical_mmi: MultiMeshInstance3D = $SphericalMMI3D



func debug_display() -> void:
	if frameskiper.skip_frame():
		return

	# 球面
	if emitter.ues_spherical and emitter.spherical_targets.size() > 0:
		disk_mmi.multimesh.instance_count = 0
		stripe_mmi.multimesh.instance_count = 0
		spherical_mmi.multimesh.instance_count = int(emitter.spherical_count)
		for p in int(emitter.spherical_count):
			var pointA: Vector3 = emitter.spherical_targets[p] * emitter.display_radius
			var pointB: Vector3 = emitter.spherical_targets[p].normalized() * 0.1
			var trans:= Transform3D.IDENTITY
			trans.origin = pointA
			trans = trans.looking_at(pointA+pointB, Vector3.UP+0.01*Vector3.FORWARD)
			#trans.origin += -trans.basis.z*0.5*emitter.display_radius
			#trans = trans.scaled_local(Vector3(1, 1, emitter.display_radius))
			spherical_mmi.multimesh.set_instance_transform(p, trans)
		return
	else:
		spherical_mmi.multimesh.instance_count = 0

	# 碟片
	if emitter.disk_debug_display and emitter.disk_positions.size() > 0:
		var range_angle = abs(emitter.stripe_range)
		var a = 270 - range_angle / 2.0  + emitter.stripe_angle
		pie_mash = draw_pie_slice(emitter.display_radius, a, range_angle, Color.ORANGE_RED)
		disk_mmi.multimesh.instance_count = 0
		disk_mmi.multimesh.mesh = pie_mash
		disk_mmi.multimesh.instance_count = emitter.disk_count
		for i in emitter.disk_count:
			var trans:= Transform3D.IDENTITY
			trans.origin = emitter.disk_positions[i] * emitter.rotation_matrixs[i]
			trans.basis = emitter.rotation_matrixs[i].basis.inverse()#.orthonormalized().scaled(Vector3(emitter.display_radius, emitter.display_radius, emitter.display_radius))
			disk_mmi.multimesh.set_instance_transform(i, trans)
	else:
		disk_mmi.multimesh.instance_count = 0

	# 条
	if emitter.stripe_debug_display and emitter.stripe_fire_positions.size() > 0:
		stripe_mmi.multimesh.instance_count = emitter.stripe_targets.size()
		for j in emitter.stripe_targets.size():
			var trans:= Transform3D.IDENTITY
			trans = trans.looking_at(emitter.stripe_targets[j], Vector3.UP+0.01*Vector3.FORWARD)
			trans.origin = emitter.stripe_fire_positions[j]
			trans.origin += -trans.basis.z*0.5*emitter.display_radius
			trans = trans.scaled_local(Vector3(1, 1, emitter.display_radius))
			stripe_mmi.multimesh.set_instance_transform(j, trans)
	else:
		stripe_mmi.multimesh.instance_count = 0


func draw_pie_slice(radius: float, start_angle: float, angle_span: float, color: Color) -> ImmediateMesh: # 添加旋转向量参数
	radius = abs(radius)
	start_angle = deg_to_rad(start_angle)
	angle_span = deg_to_rad(angle_span)
	var center:= Vector3.ZERO

	# 填充扇形
	var immediatemesh:= ImmediateMesh.new()
	immediatemesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP) # 开始绘制三角形扇
	immediatemesh.surface_set_color(color) # 设置颜色
	immediatemesh.surface_add_vertex(center) # 添加圆心经过旋转变换后的位置

	# 添加沿着扇形边界的点
	var num_segments = max(int(angle_span / (PI / 18)), 1)
	var angle_increment = angle_span / num_segments # 每段的角度增量
	for i in range(num_segments + 1):
		var angle = start_angle + angle_increment * i # 计算当前角度
		var curve_point = center + Vector3(radius * cos(angle), 0, radius * sin(angle)) # 计算每个点
		# 应用旋转
		immediatemesh.surface_add_vertex(curve_point) # 添加当前点经过旋转变换后的位置
		immediatemesh.surface_add_vertex(center) # 添加圆心经过旋转变换后的位置
	immediatemesh.surface_end() # 结束绘制
	return immediatemesh
