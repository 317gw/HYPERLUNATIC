#class_name Global Code
extends Node

signal main_player_ready
signal global_scenes_ready

const explod_max_speed: float = 100.0 ## m

# 注意大小写对应
const EFFECTS = preload("res://assets/global/Effects.tscn")
const POST_PROCESSING = preload("res://assets/global/post-processing.tscn")
const FLUID_MECHANICS_MANAGER = preload("res://assets/systems/water_physics/fluid_mechanics_manager.tscn")
const WAR_FOG = preload("res://assets/systems/marching_cubes/war_fog.tscn")
const CHUNK_MANAGER = preload("res://assets/systems/chunk/chunk_manager.tscn")

var GLOBAL_SCENES_LIST_START = "GLOBAL_SCENES_LIST_START"

var effects: Node3D
var post_processing: Node3D
var fluid_mechanics_manager: HL.FluidMechanicsManager
var war_fog: Node3D
var chunk_manager: HL.ChunkManager

var GLOBAL_SCENES_LIST_END = "GLOBAL_SCENES_LIST_END"

var _current_scene_add_global_scenes: bool = false
var global_scenes_list: Array = []

var global_nodes: Array = []
var main_player: HL.Player = null

var gravity_value: float
var gravity_vector: Vector3
var gravity: Vector3:
	get():
		return gravity_vector * gravity_value

	#var time_start = Time.get_ticks_usec()
	#var time_end = Time.get_ticks_usec()
	#print("took %d microseconds" % (time_end - time_start))

#ProjectSettings.get_setting("") 
func _ready() -> void:
	gravity_value = ProjectSettings.get_setting("physics/3d/default_gravity") 
	gravity_vector = ProjectSettings.get_setting("physics/3d/default_gravity_vector")

	if not get_tree().current_scene.is_in_group("Normal3DGameScene") : # 防止其他节点
		return
	var _list = get_property_list()
	global_scenes_list = get_dicts_between_start_end(_list, GLOBAL_SCENES_LIST_START, GLOBAL_SCENES_LIST_END)

	ready_global_scenes()


func _process(delta: float) -> void:
	if _current_scene_add_global_scenes and get_tree().current_scene:
		for scene_dir in global_scenes_list:
			var scene_name: String = scene_dir["name"]
			var scene = self.get(scene_name)
			get_tree().current_scene.add_child(scene)
		_current_scene_add_global_scenes = false
		global_scenes_ready.emit()


func ready_global_scenes() -> void:
	for scene_dir in global_scenes_list:
		var scene_name: String = scene_dir["name"]
		var scene: Node3D = self.get(scene_name)
		var SCENE: PackedScene = self.get(scene_name.to_upper())

		if scene: scene.queue_free()
		self.set(scene_name, SCENE.instantiate())
		self.get(scene_name).process_mode = Node.PROCESS_MODE_PAUSABLE
	
	_current_scene_add_global_scenes = true


func reload_current_scene() -> void:
	get_tree().reload_current_scene()
	#await get_tree().current_scene.ready
	ready_global_scenes()



func get_delta_time() -> float:
	if Engine.is_in_physics_frame():
		return get_physics_process_delta_time()
	return get_process_delta_time()


# 计算mesh体积
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


static func children_queue_free(node: Node) -> void:
	if node:
		if node.get_child_count() > 0:
			for child in node.get_children():
				child.queue_free()


static func clamping_accuracy(n: float, precision: int = 6) -> float:
	if precision < 1:
		return n
	return int(n * precision) / float(precision)


static func clamping_accuracy_vector3(vector3: Vector3, precision: int = 6) -> Vector3:
	if precision < 1:
		return vector3
	vector3.x = clamping_accuracy(vector3.x, precision)
	vector3.y = clamping_accuracy(vector3.y, precision)
	vector3.z = clamping_accuracy(vector3.z, precision)
	return vector3


#递归查找节点下特定类型的子节点
static func find_child_node_type(node: Node, child_type: String) -> Node:
	if node.get_class() == child_type:
		return node
	for i in range(node.get_child_count()):
		var child_node = node.get_child(i)
		var result = find_child_node_type(child_node, child_type)
		if result:
			return result
	return null


# 返回两个标识名称(键"name"为"START"和"END")中间字典的数组
static func get_dicts_between_start_end(dict_array: Array, start: String = "START", end: String = "END") -> Array:
	var result := []
	var started := false

	for dict in dict_array:
		if dict.name == start:
			started = true
			continue
		if dict.name == end:
			break
		if started:
			result.append(dict)

	return result



# 曲线救国创建碰撞 # 废了
static func create_CollisionShape3D_from_mesh(collision_father: Node, source_mesh: Mesh, settings: MeshConvexDecompositionSettings = null) -> void:
	var mesh_instance_3d: MeshInstance3D = MeshInstance3D.new()
	collision_father.add_child(mesh_instance_3d)
	mesh_instance_3d.set_mesh(source_mesh)
	mesh_instance_3d.create_multiple_convex_collisions(settings)
	var new_collision_shape_3d: CollisionShape3D = find_child_node_type(mesh_instance_3d, "CollisionShape3D").duplicate()
	collision_father.add_child(new_collision_shape_3d, true)
	mesh_instance_3d.queue_free()


# 弹性碰撞的那个
static func impact_velocity(m1:float, m2:float, v1:float, v2:float) -> float:
	return (m1-m2)/(m1+m2)*v1 + 2*m2/(m1+m2)*v2


#func 













pass
