#class_name Global Code
extends Node

signal main_player_ready
signal global_scenes_ready
signal sky_limit_ready
signal danmaku_manager_ready

const explod_max_speed: float = 100.0 ## m
const default_gravity: float = 9.8
const Hl = preload("res://assets/global/scripts/HL.gd")


###
# 自动场景初始化
# 注意大小写对应
const EFFECTS = preload("res://assets/global/Effects.tscn")
const POST_PROCESSING = preload("res://assets/global/post-processing.tscn")
const FLUID_MECHANICS_MANAGER = preload("res://assets/systems/water_physics/fluid_mechanics_manager.tscn")
const WAR_FOG = preload("res://assets/systems/marching_cubes/war_fog.tscn")
const CHUNK_MANAGER = preload("res://assets/systems/chunk/chunk_manager.tscn")

const DEBUG_MENU = preload("res://assets/arts_graphic/ui/debug_menu/debug_menu.tscn")
const PLAYER_FP_UI = preload("res://assets/arts_graphic/ui/player_ui/PlayerFP_UI.tscn")
const MAIN_MENUS = preload("res://assets/arts_graphic/ui/menu/main_menus.tscn")

const DANMAKU_MANAGER = preload("res://assets/danmaku/danmaku_manager.tscn")


###
var GLOBAL_SCENES_LIST_START = "GLOBAL_SCENES_LIST_START"
#
var effects: Node3D
var fluid_mechanics_manager: HL.FluidMechanicsManager
var war_fog: Node3D
var chunk_manager: HL.ChunkManager
# ui
var post_processing: CanvasLayer
var debug_menu: HL.DebugMenu
var player_fp_ui: HL.PlayerFP_UI
var main_menus: HL.MainMenus
#弹幕
var danmaku_manager: HL.DanmakuManager
#
var GLOBAL_SCENES_LIST_END = "GLOBAL_SCENES_LIST_END"
###
var global_scenes_list: Array = []


# 其他
#var global_nodes: Array = []

var main_player: HL.Player = null
var main_player_camera: HL.Camera = null
var sky_limit: HL.SkyLimit = null

var paused_time_process: float = 0.0
var paused_time_physics_process: float = 0.0

var gravity_value: float
var gravity_vector: Vector3
var gravity: Vector3:
	get():
		return gravity_vector * gravity_value


func _ready() -> void:
	gravity_value = ProjectSettings.get_setting("physics/3d/default_gravity")
	gravity_vector = ProjectSettings.get_setting("physics/3d/default_gravity_vector")

	if not get_tree().current_scene.is_in_group("Normal3DGameScene") : # 防止其他节点
		return
	var _list = get_property_list()
	global_scenes_list = get_dicts_between_start_end(_list, GLOBAL_SCENES_LIST_START, GLOBAL_SCENES_LIST_END)

	ready_global_scenes()
	add_child(GetReady.new(func(): return get_tree().current_scene, _global_scenes_ready))


func _process(_delta: float) -> void:
	if not get_tree().paused:
		paused_time_process += _delta


func _physics_process(_delta: float) -> void:
	if not get_tree().paused:
		paused_time_physics_process += _delta


func _global_scenes_ready() -> void:
	for scene_dir in global_scenes_list:
		var scene_name: String = scene_dir["name"]
		var scene = self.get(scene_name)
		get_tree().current_scene.add_child(scene)
	paused_time_process = 0.0
	paused_time_physics_process = 0.0
	global_scenes_ready.emit()


func ready_global_scenes() -> void:
	for scene_dir in global_scenes_list:
		var scene_name: String = scene_dir["name"]
		var old_scene: Node = self.get(scene_name)
		if old_scene:
			old_scene.queue_free()

		var SCENE: PackedScene = self.get(scene_name.to_upper())
		self.set(scene_name, SCENE.instantiate())
		var new_scene: Node = self.get(scene_name)
		if new_scene.has_method("_ready_process_mode"):
			new_scene.process_mode = new_scene._ready_process_mode()
		else:
			new_scene.process_mode = Node.PROCESS_MODE_PAUSABLE


func reload_current_scene() -> void:
	get_tree().reload_current_scene()
	#await get_tree().current_scene.ready
	ready_global_scenes()
	add_child(GetReady.new(func(): return get_tree().current_scene, _global_scenes_ready))



func get_delta_time() -> float:
	if Engine.is_in_physics_frame():
		return get_physics_process_delta_time()
	return get_process_delta_time()


# Global.set_mouse_mode()
# 鼠标模式控制逻辑
func set_mouse_mode() -> void:
	if tool_ui_visible():  # 如果工具UI可见
		if player_fp_ui.tool_ui.is_mouse_wheel_pressed:  # 且鼠标滚轮被按下
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED  # 限制鼠标在窗口内
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # 否则显示自由鼠标

	elif main_player and not main_menus.visible:  # 如果主角色存在且主菜单不可见
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # 捕获鼠标(通常用于第一人称视角)

	else:  # 其他所有情况
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # 显示自由鼠标


func is_tool_ui_move_camera() -> bool:
	return tool_ui_visible() and player_fp_ui.tool_ui.is_mouse_wheel_pressed


func tool_ui_visible() -> bool:
	return player_fp_ui and player_fp_ui.tool_ui and player_fp_ui.tool_ui.visible


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


## 算液体阻力   空阻   0 -> 1
static func get_water_friction(_density: float, _viscosity: float) -> float:
		var _d: float = clampf(remap(_density, 1000, 10000, 0.1, 0.5) , 0.0, 0.5)
		var _v: float = clampf(remap(_viscosity, 0, 20000, 0.0, 0.5) , 0.0, 0.5)
		return snappedf(_d + _v, 0.001)



# 获取指定文件夹下特定类型的随机资源
# folder_path: 文件夹路径（如"res://assets/sounds"）
# allowed_types: 允许的资源类型数组（如["PackedScene", "Texture2D"]），留空则允许所有类型
func get_random_resource(folder_path: String, allowed_types: Array = []) -> Resource:
	# 用于存储符合条件的资源路径
	var valid_resources := []

	# 检查文件夹是否存在
	if not DirAccess.dir_exists_absolute(folder_path):
		push_error("Folder does not exist: " + folder_path)
		return null

	# 遍历目录
	var dir := DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			# 跳过目录和隐藏文件
			if not dir.current_is_dir() and not file_name.begins_with("."):
				var full_path := folder_path.path_join(file_name)
				# 检查文件扩展名是否是资源类型
				if ResourceLoader.exists(full_path):
					# 如果指定了类型限制，则检查类型
					if allowed_types.is_empty():
						valid_resources.append(full_path)
					else:
						var rfl := ResourceFormatLoader.new()
						var resource_type := rfl._get_resource_type(full_path) # buggggggg
						if resource_type in allowed_types:
							valid_resources.append(full_path)
			file_name = dir.get_next()
	else:
		push_error("Failed to open directory: " + folder_path)
		return null

	# 如果没有找到符合条件的资源
	if valid_resources.is_empty():
		push_error("No valid resources found in: " + folder_path)
		return null

	# 随机选择一个资源并加载
	var random_index := randi() % valid_resources.size()
	var selected_resource := ResourceLoader.load(valid_resources[random_index])

	return selected_resource



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





"""
update
calculate
create
process
global
start
end
position
count

# await get_tree().physics_frame

	#var time_start = Time.get_ticks_usec()
	#var time_end = Time.get_ticks_usec()
	#print("took %d microseconds" % (time_end - time_start))

#ProjectSettings.get_setting("")



"""






pass
