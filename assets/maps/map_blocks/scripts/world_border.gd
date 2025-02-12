extends MeshInstance3D

@onready var static_body_3d: StaticBody3D = $StaticBody3D


func _ready() -> void:
	await Global.global_scenes_ready
	create_convex_collision()
	for child in get_children():
		if not child is StaticBody3D:
			continue
		for child2 in child.get_children():
			if not child2 is CollisionShape3D:
				continue
			static_body_3d.add_child(child2.duplicate())
