extends StaticBody3D

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	collision_shape_3d.shape = mesh_instance_3d.mesh.create_trimesh_shape()


func _process(_delta: float) -> void:
	pass
