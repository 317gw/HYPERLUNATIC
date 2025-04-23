#class_name TexturePellet
extends Bullet


@onready var _mesh: QuadMesh = $MeshInstance3D.mesh

func set_color(_color1: Color, _color2: Color) -> void:
	var _material: ShaderMaterial = _mesh.material
	_material.set_shader_parameter("albedo_opacity", _color1)
	_material.set_shader_parameter("albedo_lucency", _color2)

func set_radius(_radius: float) -> void:
	#_mesh.size = Vector2.ONE * bullet_radius * 2.0
	var ss: SphereShape3D = $Area3D/CollisionShape3D.shape
	ss.radius = bullet_radius * 0.8

func set_bullet_scale(_scale: Vector3) -> void:
	_mesh.size.x = _scale.x
	_mesh.size.y = _scale.y
	#var average = (_scale.x + _scale.y + _scale.z)/3
	var _radius: float = minf(_scale.x, _scale.y)
	self.scale = Vector3.ONE * _radius
	bullet_radius = _radius * 0.25


func _on_texture_pellet_body_entered(body: Node3D) -> void:
	if body is HL.Player:
		print("het", body)
