class_name Pellet
extends Bullet

@onready var mesh_shader_material: StandardMaterial3D = $MeshInstance3D.get_material_override()
@onready var ring_shader_material: ShaderMaterial = $Ring.get_material_override()

func set_albedo(albedo: Color) -> void:
	#mesh_shader_material.albedo_color = albedo
	ring_shader_material.set_shader_parameter("albedo", albedo)
