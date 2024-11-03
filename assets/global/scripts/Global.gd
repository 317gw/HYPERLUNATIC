#class_name GlobalCode
extends Node


const explod_max_speed: float = 100.0 ## m
const EFFECTS = preload("res://assets/global/Effects.tscn")

var effects: Node3D = null # Global.effects.add_child()

func _ready() -> void:
	effects = EFFECTS.instantiate()
	self.add_child(effects)




	#var from = 0.0
	#var to = 100.0
	#var target = from + 0.99 * (to - from)
	#var delta = 1.0/120.0  # 根据需要调整
	#var required_time = time_to_reach(target, from, to, 2.0*delta)
	#print("从0到99%的目标值所需帧数:", required_time)

#func time_to_reach(target: float, from: float, to: float, delta: float) -> int:
	#var current_value = from
	#var time = 0
	#while current_value < target:
		#current_value = exponential_decay(current_value, to, delta)
		#time += 1  # 每次迭代代表一帧
	#return time



# 用于代替lerp在 _process 等中每帧调用平滑数据  4.6秒到达99%  x乘delta缩短x倍时间 __By 317GW 2024 8 31 半夜
func exponential_decay(from: float, to: float, delta: float) -> float:
	var x0 = log(abs(to - from) )
	return to - exp(x0 - delta) * sign(to - from)

	#if from == to:
		#return to
	#var diff: float = to - from
	#var x0: float = log(abs(diff) )
	#return to - exp(x0 - delta) * sign(diff)
"""
var x0 = log(abs(to - from) )
return to - exp(x0 - delta) * sign(to - from)

var diff = to - from
if diff == 0:
	return to
var x0 = log(abs(diff))
var exp_val = exp(x0 - delta)
return to - exp_val * sign(diff)
"""

func exponential_decay_vec2(from: Vector2, to: Vector2, delta: float) -> Vector2:
	return Vector2(
		exponential_decay(from.x, to.x, delta),
		exponential_decay(from.y, to.y, delta)
		)

func exponential_decay_vec3(from: Vector3, to: Vector3, delta: float) -> Vector3:
	return Vector3(
		exponential_decay(from.x, to.x, delta),
		exponential_decay(from.y, to.y, delta),
		exponential_decay(from.z, to.z, delta)
		)


# 计算mesh体积
func calculate_mesh_volume(mesh: Mesh) -> float:
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


func children_queue_free(node: Node) -> void:
	if node:
		if node.get_child_count() > 0:
			for child in node.get_children():
				child.queue_free()


func clamping_accuracy(n: float, precision: int = 6) -> float:
	if precision < 1:
		return n
	return int(n * precision) / float(precision)


func clamping_accuracy_vector3(vector3: Vector3, precision: int = 6) -> Vector3:
	if precision < 1:
		return vector3
	vector3.x = clamping_accuracy(vector3.x, precision)
	vector3.y = clamping_accuracy(vector3.y, precision)
	vector3.z = clamping_accuracy(vector3.z, precision)
	return vector3


#递归查找节点下特定类型的子节点
func find_child_node(node: Node, child_type: String) -> Node:
	if node.get_class() == child_type:
		return node
	for i in range(node.get_child_count()):
		var child_node = node.get_child(i)
		var result = find_child_node(child_node, child_type)
		if result:
			return result
	return null


# 曲线救国创建碰撞
# 废了
func create_CollisionShape3D_from_mesh(collision_father: Node, source_mesh: Mesh, settings: MeshConvexDecompositionSettings = null) -> void:
	var mesh_instance_3d: MeshInstance3D = MeshInstance3D.new()
	collision_father.add_child(mesh_instance_3d)
	mesh_instance_3d.set_mesh(source_mesh)
	mesh_instance_3d.create_multiple_convex_collisions(settings)
	var new_collision_shape_3d: CollisionShape3D = find_child_node(mesh_instance_3d, "CollisionShape3D").duplicate()
	collision_father.add_child(new_collision_shape_3d, true)
	mesh_instance_3d.queue_free()







pass
