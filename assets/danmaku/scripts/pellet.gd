class_name Pellet
extends Bullet

@onready var mesh_shader_material: StandardMaterial3D = $MeshInstance3D.get_material_override()
@onready var ring_shader_material: ShaderMaterial = $Ring.get_material_override()

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var ring: MeshInstance3D = $Ring



func set_albedo(_albedo: Color) -> void:
	#mesh_shader_material.albedo_color = albedo
	ring_shader_material.set_shader_parameter("albedo", _albedo)


func set_radius(radius) -> void:
	mesh_instance_3d.mesh.radius = bullet_radius
	mesh_instance_3d.mesh.height = bullet_radius * 2
	ring.mesh.size = bullet_radius/0.25
