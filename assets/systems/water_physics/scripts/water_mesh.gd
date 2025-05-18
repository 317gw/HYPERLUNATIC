extends MeshInstance3D


@export var density: float = 1000.0 ## 水的密度，单位：kg/m³  1~10000
@export var viscosity: float = 0.001 ## 黏性 kg/(m*s)  0.001~20000
var friction: float = 1.0 - Global.get_water_friction(density, viscosity):
	get():
		friction = 1.0 - Global.get_water_friction(density, viscosity)
		return friction

"""
viscosity
20.2°c
水	0.001
空气	0.0000178
水银	0.00155
玄武岩溶体
700°c	160434.155
869.12°c	20000

1200°c	373.765
1210°c	320.041
1250°c	176.702
1290°c	100.106
1300°c	88.318
1350°c	49.633
1400°c	29.535
1470°c	17.055
1488°c	18.543

700 —— 870 —— 1200 —— 1470
887439835.9864781 * e^(-0.012311732x)
"""

var id: String
var underwater_objects: Array = [] # 在水中的物体
var aabb: AABB
#var approximate_water_level: Plane


@onready var swimmable_area_3d: Area3D = $SwimmableArea3D
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D


func _ready() -> void:
	await Global.global_scenes_ready

	underwater_objects.clear()
	apply_collision()

	var wm_dic: Dictionary = Global.fluid_mechanics_manager.water_mesh_3d_s
	id = String(self.get_path())
	wm_dic[id] = self
	#gpu_particles_3d.amount =
	aabb = mesh.get_aabb()


# 曲线救国创建碰撞
func apply_collision() -> void:
	self.create_convex_collision()
	for child in get_children():
		if not child is StaticBody3D:
			continue
		for c2 in child.get_children():
			if not c2 is CollisionShape3D:
				continue
			swimmable_area_3d.add_child(c2.duplicate(), true)
		child.queue_free()


func _on_swimmable_area_3d_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and not body in underwater_objects:
		if body.has_meta("fluid_mechanics"):
			underwater_objects.append(body)
			var fluid_mechanics: HL.FluidMechanics = body.get_meta("fluid_mechanics")
			#fluid_mechanics.water_meshs.append(id)
			fluid_mechanics.water_meshs.append(self)

	if body is HL.Player:
		body.water_meshs.append(self)
		body.now_in_water.emit()


func _on_swimmable_area_3d_body_exited(body: Node3D) -> void:
	if body is RigidBody3D and body in underwater_objects:
		if body.has_meta("fluid_mechanics"):
			var fluid_mechanics: HL.FluidMechanics = body.get_meta("fluid_mechanics")
			#fluid_mechanics.water_meshs.erase(id)
			fluid_mechanics.water_meshs.erase(self)
		underwater_objects.erase(body)

	if body is HL.Player:
		body.water_meshs.erase(self)
		body.now_out_water.emit()
