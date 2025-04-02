extends RigidBody3D

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	#collision_shape_3d.shape = Global.get_random_resource("res://assets/models/low_prefabricate/", [Shape3D])
	collision_shape_3d.shape = HL.shape_3d_array[randi_range(0, HL.shape_3d_array.size())]
