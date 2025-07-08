
extends Bullet

#@onready var area_3d: Area3D = $Area3D
#func _ready() -> void:
	#area_3d.queue_free()


func set_radius(_radius: float) -> void:
	var ss: SphereShape3D = $Area3D/CollisionShape3D.shape
	ss.radius = bullet_radius * 0.8

func set_bullet_scale(_scale: Vector3) -> void:
	var _radius: float = minf(_scale.x, _scale.y)
	self.scale = Vector3.ONE * _radius
	bullet_radius = _radius * 0.25

func _on_texture_pellet_body_entered(body: Node3D) -> void:
	if body is HL.Player:
		print("het", body)
