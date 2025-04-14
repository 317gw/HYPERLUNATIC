#class_name TexturePellet
extends Bullet



func set_albedo(_albedo: Color) -> void:
	var _mesh: QuadMesh = self.mesh
	var _material: ShaderMaterial = _mesh.material
	_material.set_shader_parameter("albedo_opacity", _albedo)
	#_material.set_shader_parameter("albedo_lucency", _albedo)


func set_radius(_radius) -> void:
	var _mesh: QuadMesh = self.mesh
	_mesh.size = Vector2.ONE * bullet_radius * 2.0
	var ss: SphereShape3D = $Area3D/CollisionShape3D.shape
	ss.radius = bullet_radius * 0.8


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is HL.Player:
		print("het", body)
