class_name MeshUtils
extends NAMESPACE



## 计算mesh体积
static func calculate_mesh_volume(mesh: Mesh) -> float:
	var arrays = mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	var indices = arrays[Mesh.ARRAY_INDEX]

	var volume = 0.0

	for i in range(0, indices.size(), 3):
		var v1 = vertices[indices[i]]
		var v2 = vertices[indices[i + 1]]
		var v3 = vertices[indices[i + 2]]

		var cross_product = v2.cross(v3)
		var dot_product = v1.dot(cross_product)
		var triangle_volume = abs(dot_product)

		volume += triangle_volume

	return volume / 6.0



## 曲线救国创建碰撞
## 废弃
static func create_collision_shape3d_from_mesh(collision_father: Node, source_mesh: Mesh, settings: MeshConvexDecompositionSettings = null) -> void:
	var mesh_instance_3d: MeshInstance3D = MeshInstance3D.new()
	collision_father.add_child(mesh_instance_3d)
	mesh_instance_3d.set_mesh(source_mesh)
	mesh_instance_3d.create_multiple_convex_collisions(settings)
	var new_collision_shape_3d: CollisionShape3D = GeneralUtils.find_child_node_type(mesh_instance_3d, "CollisionShape3D").duplicate()
	collision_father.add_child(new_collision_shape_3d, true)
	mesh_instance_3d.queue_free()
