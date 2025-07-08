extends Node3D

const ACTIVATE = "ACTIVATE"

#const UPDATE_THRESHOLD = 1
const SAVE_PATH = "user://chunks/"
const FOG_CHUNK = preload("res://assets/systems/spatial_partition/fog_chunk.tscn")

@export var view_distance: float = 30
@export var chunk_size: float = 8
@export var strong_radius: int = 1
@export var lod_radius: int = 4


var camera: Camera3D
var chunk_size_v3: Vector3 = Vector3.ONE * chunk_size
var loaded_chunks: Dictionary = {} # pos: [lod, is_strong, is_in_camera]  states

var player : Node3D
var player_chunk_pos: Vector3
var last_player_chunk_pos: Vector3


func _ready():
	player = Global.main_player
	update_chunks()


#func _physics_process(delta: float) -> void:
	#camera = get_viewport().get_camera_3d()
	#player_chunk_pos = get_chunk_position(player.global_position)
	#
	##var distance = player_chunk_pos.distance_to(last_player_chunk_pos)
	##if player_chunk_pos != last_player_chunk_pos:
	#update_chunks()
	#last_player_chunk_pos = player_chunk_pos
	#_draw_loaded_chunks()


func update_chunks():
	loaded_chunks.clear()
	var max_chunks_in_view: int = floori(view_distance / chunk_size)
	for x in range(-max_chunks_in_view, max_chunks_in_view + 1):
		for y in range(-max_chunks_in_view, max_chunks_in_view + 1):
			for z in range(-max_chunks_in_view, max_chunks_in_view + 1):
				if x==0 and y==0 and z==0:
					loaded_chunks[player_chunk_pos] = [0, true, true]
					continue

				var loc_pos:= Vector3(x, y, z)
				var lod_level = loc_pos.distance_to(Vector3.ZERO)
				if lod_level > lod_radius:
					continue

				var chunk_pos:= player_chunk_pos + loc_pos
				var is_strong = (abs(x)<=strong_radius)and(abs(y)<=strong_radius)and(abs(z)<=strong_radius)
				#var is_strong = (player.global_position-chunk_pos).distance_to(Vector3.ZERO) < strong_radius*1.4142
				var is_in_camera = is_chunk_in_frustum(chunk_pos)
				if not is_strong and not is_in_camera:
					continue

				loaded_chunks[chunk_pos] = [lod_level, is_strong, is_in_camera]# [0, false, true]


func get_chunk_position(pos) -> Vector3:
	return (pos / chunk_size).floor()


func get_chunk_path(chunk_pos) -> String:
	return SAVE_PATH + str(chunk_pos) + ".tscn"


func get_intersecting_chunks(center: Vector3, radius: float) -> PackedVector3Array:
	var intersecting_chunks: PackedVector3Array = []
	var min_bound = (center - Vector3(radius, radius, radius)) / chunk_size
	var max_bound = (center + Vector3(radius, radius, radius)) / chunk_size

	for x in range(int(min_bound.x), int(max_bound.x) + 1):
		for y in range(int(min_bound.y), int(max_bound.y) + 1):
			for z in range(int(min_bound.z), int(max_bound.z) + 1):
				var chunk_pos = Vector3(x, y, z)
				if is_chunk_intersecting_sphere(chunk_pos, center, radius):
					intersecting_chunks.append(chunk_pos)

	return intersecting_chunks


func is_chunk_intersecting_sphere(chunk_pos: Vector3, center: Vector3, radius: float) -> bool:
	var chunk_center = chunk_pos * chunk_size + chunk_size_v3 / 2
	var distance = chunk_center.distance_to(center)
	return distance < radius + chunk_size / 2


func is_in_loaded_chunk(pos: Vector3) -> bool:
	return loaded_chunks.has(pos)


func is_chunk_in_frustum(chunk_pos: Vector3) -> bool:
	if not camera:
		return false
	var planes = camera.get_frustum()
	var aabb_min = chunk_pos * chunk_size
	var aabb_max = aabb_min + chunk_size_v3

	for plane in planes:
		# 计算AABB在平面法线方向上的最远点（平面背面方向）
		var p = Vector3(
			aabb_max.x if plane.normal.x >= 0 else aabb_min.x,
			aabb_max.y if plane.normal.y >= 0 else aabb_min.y,
			aabb_max.z if plane.normal.z >= 0 else aabb_min.z
		)
		#print("Plane normal: ", plane.normal)
		#print("Distance to plane: ", plane.distance_to(p))
		# 如果最远点在平面背面，则整个AABB不可见
		if plane.distance_to(p) > chunk_size:
			return false
	return true


func _draw_loaded_chunks():
	DebugDraw.draw_statical.clear_surfaces()
	var transforms: Array[Transform3D]
	for chunk in loaded_chunks:
		var tran = Transform3D(Basis.IDENTITY * chunk_size, chunk * chunk_size)
		if chunk == player_chunk_pos:
			DebugDraw.draw_line_cube(tran)
		else:
			transforms.append(tran)
	DebugDraw.draw_multi_line_cube(transforms)
