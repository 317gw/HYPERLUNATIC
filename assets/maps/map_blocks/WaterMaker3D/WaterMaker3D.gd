#@tool
class_name WaterMaker3D
extends CSGMesh3D

#@export var water_speed1:= Vector3(0.005, 0.005, 0.005)
#@export var water_speed2:= Vector3(0.001, 0.003, 0.005)
#@export var water_texture_uv_scale1:= 0.04
#@export var water_texture_uv_scale2:= 0.04
#@export var water_color:= Color(0.3098, 0.5411765, 0.8666667, 0.3882353)
#@export var noise_move_speed:= Vector3(0.0, 0.0, 1.0)
#@export var fog_color:= Color(0, 0.04313725605607, 0.15686275064945)
#@export_range(0.0, 250.0) var fog_fade_dist:= 5.0

@export_group("Float")
@export var density: float = 1000.0 # 水的密度，单位：kg/m³

var uv1_offset: Vector3 = Vector3.ZERO
var uv2_offset: Vector3 = Vector3.ZERO
#var collision_shape
var frame_skiper: FrameSkiper
var underwater_objects: Array = [] # 在水中的物体
# var objects_volume: Array = [] # 物体体积
var in_water_material: ShaderMaterial

var check_camera_underwater: bool = false

static var last_frame_drew_underwater_effect : int = -999


@export var wrosp_in_value: float = 2.0
var wrosp_trg: float
var wrosp_ori: float
var wrosp_in: float
class WROSP: # WaterRippleOverlay shader_parameter
	var color: Color     # = Color.html("80eaff")
	var ripple_speed: float
	var ripple_density: float
	var ripple_strength: float
	var blur_radius: float
	var blur_count: float



@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var swimmable_area_3d: Area3D = $SwimmableArea3D
#@onready var collision_shape_3d: CollisionShape3D = $SwimmableArea3D/CollisionShape3D
@onready var camera_pos_shape_cast_3d: ShapeCast3D = $CameraPosShapeCast3D
#@onready var fog_volume: FogVolume = $FogVolume
@onready var water_ripple_overlay: TextureRect = $WaterRippleOverlay


func _ready() -> void:
	await owner.ready
	underwater_objects.clear()
	#self.process_priority = 999 # Call _process last to update move after any camera movement
	# 跳帧
	frame_skiper = FrameSkiper.new(60)
	self.add_child(frame_skiper)

	#if collision_shape_3d.shape is ConcavePolygonShape3D:
		#var collision_shape: ConcavePolygonShape3D = collision_shape_3d.shape
		#collision_shape.set_faces(self.mesh.get_faces() )

	# 曲线救国创建碰撞
	mesh_instance_3d.set_mesh(self.mesh)
	mesh_instance_3d.create_multiple_convex_collisions()
	# 递归查找mesh_instance_3d的子节点直到找到CollisionShape3D类型
	var new_collision_shape_3d: CollisionShape3D = Global.find_child_node(mesh_instance_3d, "CollisionShape3D").duplicate()
	swimmable_area_3d.add_child(new_collision_shape_3d, true)
	mesh_instance_3d.queue_free()

	in_water_material = water_ripple_overlay.material
	#wrosp_ori = WROSP.new()
	#wrosp_ori.ripple_speed = in_water_material.get_shader_parameter("ripple_speed")
	#wrosp_ori.ripple_density = in_water_material.get_shader_parameter("ripple_density")
	#wrosp_ori.ripple_strength = in_water_material.get_shader_parameter("ripple_strength")
	#wrosp_ori.blur_radius = in_water_material.get_shader_parameter("blur_radius")
	#wrosp_ori.blur_count = in_water_material.get_shader_parameter("blur_count")
	#wrosp_in = wrosp_ori
	#wrosp_in.ripple_speed *= wrosp_in_value
	#wrosp_in.ripple_density *= wrosp_in_value
	#wrosp_in.ripple_strength *= wrosp_in_value
	#wrosp_in.blur_radius *= wrosp_in_value
	#wrosp_in.blur_count *= wrosp_in_value
	#wrosp_trg = wrosp_in

	wrosp_ori = in_water_material.get_shader_parameter("value_all")
	wrosp_in = wrosp_ori * wrosp_in_value
	wrosp_trg = wrosp_in




func _physics_process(delta: float) -> void:
	underwater_physics_process(delta)
	if check_camera_underwater:
		if should_draw_camera_underwater_effect():
			water_ripple_overlay.process_mode = Node.PROCESS_MODE_INHERIT
			water_ripple_overlay.visible = true
		else:
			water_ripple_overlay.visible = false
			water_ripple_overlay.process_mode = Node.PROCESS_MODE_DISABLED

		wrosp_trg = MathUtils.exponential_decay(wrosp_trg, wrosp_ori, delta*1.53333)
		in_water_material.set_shader_parameter("value_all", wrosp_trg)


# Track the current camera with an area so we can check if it is inside the water
func should_draw_camera_underwater_effect() -> bool:
	var camera:= get_viewport().get_camera_3d() if get_viewport() else null
	if not camera:
		print("not camera")
		return false

	# Don't draw multiple overlays at once, incase 2 water bodies overlap
	if last_frame_drew_underwater_effect == Engine.get_process_frames():
		print("not last_frame_drew_underwater_effect == Engine.get_process_frames()")
		return false

	camera_pos_shape_cast_3d.global_position = camera.global_position
	camera_pos_shape_cast_3d.force_update_transform()
	camera_pos_shape_cast_3d.force_shapecast_update()
	for i in camera_pos_shape_cast_3d.get_collision_count():
		if camera_pos_shape_cast_3d.get_collider(i) == swimmable_area_3d:
			return true
	camera_pos_shape_cast_3d.global_position = self.global_position
	print("not not not camera")
	return false


func underwater_physics_process(delta: float) -> void:
	for obj: RigidBody3D in underwater_objects:
		var water_physics: WaterPhysics = obj.get_node("water_physics")
		if water_physics.sleeping:
			continue

		# 计算浮力
		if frame_skiper.is_in_executable_frame():
			if water_physics.should_at_surface:
				water_physics.liquid_discharged_volume = obj.mass / self.density / frame_skiper.skiped_delta
			var volume: float = water_physics.liquid_discharged_volume
			var buoyancy_force: Vector3 = self.density * -Global.gravity * volume
			buoyancy_force *= frame_skiper.skiped_delta
			water_physics.buoyancy_force = buoyancy_force

		obj.apply_force(water_physics.buoyancy_force, water_physics.buoyancy_centre)
		DebugDraw.draw_mesh_line_relative(
			water_physics.buoyancy_centre + obj.global_position,
			water_physics.buoyancy_force * 0.1, 3.0, Color(0, 1, 0, 1) )

		# 计算阻力
		water_physics.resistance_force = Vector3.ZERO
		var is_drag_force: bool = false
		for i in range(water_physics.resistance_probe_in_water.size() ):
			var probe: Probe = water_physics.resistance_probe_in_water[i]
			var point_velocity: Vector3 = probe.velocity
			if point_velocity.length() == 0: # 当速度为零时，跳过计算
				continue
			var drag_force: Vector3 = (
				density
				* water_physics.drag_coefficient
				* water_physics.average_resistance_probe_area
				* pow(point_velocity.length(), 2.0) * point_velocity.normalized()
				) / 2.0
			drag_force = drag_force / water_physics.resistance_probe_in_water.size()
			drag_force *= delta
			drag_force = min(drag_force.length(), (Global.gravity * obj.mass).length() ) * drag_force.normalized()
			obj.apply_force(-drag_force, probe.global_position - obj.global_position)
			DebugDraw.draw_line_relative(probe.global_position, -drag_force, Color(0.5, 0, 0, 1) )
			water_physics.resistance_force += drag_force
			if drag_force.length() > 1:
				is_drag_force = true

		if water_physics.buoyancy_force.length() > 1 or is_drag_force:
			water_physics.sleeping = false


func _on_swimmable_area_3d_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and not body in underwater_objects:
		for child in body.get_children():
			if child.name == "water_physics":
				underwater_objects.append(body)
				child.is_in_water = true
				if not self in child.water_area:
					child.water_area.append(self)
				break

	if body is HL.Player:
		check_camera_underwater = true


func _on_swimmable_area_3d_body_exited(body: Node3D) -> void:
	if body is RigidBody3D and body in underwater_objects:
		for child in body.get_children():
			if child.name == "water_physics":
				child.buoyancy_probe_in_water.clear()
				child.resistance_probe_in_water.clear()
				child.buoyancy_force = Vector3.ZERO
				child.resistance_force = Vector3.ZERO
				child.is_in_water = false
				if self in child.water_area:
					child.water_area.erase(self)
				break
		underwater_objects.erase(body)

	if body is HL.Player:
		check_camera_underwater = false
		water_ripple_overlay.visible = false
		water_ripple_overlay.process_mode = Node.PROCESS_MODE_DISABLED
		wrosp_trg = wrosp_in
		in_water_material.set_shader_parameter("value_all", wrosp_ori)


func _on_swimmable_area_3d_area_entered(area: Area3D) -> void:
	#print(area)
	if area.get_parent().get_parent().get_parent() in underwater_objects:
		if area.get_parent().get_parent() is WaterPhysics:
			var waterphysics: WaterPhysics = area.get_parent().get_parent()
			if area.get_parent().name == "BuoyancyProbe":
				if not area in waterphysics.buoyancy_probe_in_water:
					if waterphysics.buoyancy_probe_in_water.is_empty():
						waterphysics.buoyancy_centre = area.global_position - waterphysics.global_position
					waterphysics.buoyancy_probe_in_water.append(area)
			if area.get_parent().name == "ResistanceProbe":
				if not area in waterphysics.resistance_probe_in_water:
					waterphysics.resistance_probe_in_water.append(area)


func _on_swimmable_area_3d_area_exited(area: Area3D) -> void:
	if area.get_parent().get_parent().get_parent() in underwater_objects:
		if area.get_parent().get_parent() is WaterPhysics:
			var waterphysics: WaterPhysics = area.get_parent().get_parent()
			if area.get_parent().name == "BuoyancyProbe":
				if area in waterphysics.buoyancy_probe_in_water:
					waterphysics.buoyancy_probe_in_water.erase(area)
			if area.get_parent().name == "ResistanceProbe":
				if area in waterphysics.resistance_probe_in_water:
					waterphysics.resistance_probe_in_water.erase(area)
