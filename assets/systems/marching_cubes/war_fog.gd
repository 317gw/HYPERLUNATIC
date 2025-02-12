extends Node3D

const FOG_CHUNK = preload("res://assets/systems/chunk/fog_chunk.tscn")

@export var visible_range: float = 3.0
@export var resolution: float = 1.0  # 单位立方体边长
@export var threshold: float = 1.0   # 表面判定阈值
@export var tracked_object: Array = []
@export var visited_cells: Dictionary = {}

var visited_cells_latest: Array = []
var density_field: Dictionary = {}
var voxel_grids: Dictionary = {} # pos: voxel_grid

var chunk_manager: HL.ChunkManager
var chunk_size: int
var chunk_size_v3: Vector3
var visited_chunk_latest: PackedVector3Array = []

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var mesh_instance_3d_2: HL.MarchingCubes = $MeshInstance3D2
@onready var mesh_instance_3d_4: MeshInstance3D = $MeshInstance3D4


func _ready() -> void:
	await Global.global_scenes_ready
	chunk_manager = Global.chunk_manager
	chunk_size = Global.chunk_manager.chunk_size
	chunk_size_v3 = Global.chunk_manager.chunk_size_v3


#var t: float = 0
#func _process(delta: float) -> void:
	#t += delta
#
#
#func _physics_process(delta: float) -> void:
	#Engine.get_physics_frames()
#
	#_track_object()# 位置记录

	
	#build_density_field(visited_cells_latest)

	#if t > 1.0:
		#t = 0.0
		#var time = Time.get_ticks_msec()
		#mesh_instance_3d.mesh =  mesh_instance_3d_2.generate(func(x, y, z): return density_field.get(Vector3i(x, y, z), 0))
		##mesh_instance_3d.mesh =  mesh_instance_3d_2.generate(density_field)
		##if voxel_grids.has(chunk_manager.player_chunk_pos):
			##mesh_instance_3d_4.voxel_grid = voxel_grids[chunk_manager.player_chunk_pos]
			##mesh_instance_3d_4.compute()
		#var elapsed = (Time.get_ticks_msec()-time)/1000.0
		#print("All Terrain generated in: " + str(elapsed) + "s")
	##mesh_instance_3d.mesh = generate_mesh(density_field)


func _track_object() -> void:
	visited_chunk_latest.clear()
	if not tracked_object: return
	if tracked_object.size() < 1: return 
	
	for obj: Node3D in tracked_object:
		if obj.has_method("is_stationary"):
			if obj.is_stationary(): continue

		var cell: Vector3i # centre_pos
		if obj.has_method("get_centre_pos"):
			cell = Vector3i(obj.get_centre_pos().floor())
		else:
			cell = Vector3i(obj.global_position.floor())
		
		
		#for chunk in chunk_manager.get_intersecting_chunks(cell, ceil(visible_range+0.01)):
		var chunk := chunk_manager.get_chunk_position(Vector3(cell))
		if not visited_chunk_latest.has(chunk):
			visited_chunk_latest.append(chunk)
		#if not voxel_grids.has(chunk):
			#voxel_grids[chunk] = MarchingTable.VoxelGrid.new(chunk_size_v3)
		#
		#var v_g: MarchingTable.VoxelGrid = voxel_grids[chunk]
		#var last_v = v_g.read(cell.x, cell.y, cell.z)
		#v_g.write(cell.x, cell.y, cell.z, last_v+0.01)
		
		
		if not visited_cells.has(cell):# 哈希搜索？
			visited_cells[cell] = true
			visited_cells_latest.append(cell)
			if visited_cells_latest.size() > 4:
				visited_cells_latest.pop_front()


#voxel_grid = MarchingTable.VoxelGrid.new(RESOLUTION, 0.0)
func build_density_field(points: Array):
	visible_range = max(visible_range, 0.0)
	
	
	
	
	
	# 并行计算密度场
	var temp_density_field = {}
	for p in points:
		var _r: int = floori(visible_range)
		var range = Vector3i(_r, _r, _r) + Vector3i.ONE
		var min_corner = Vector3i(floor(p / resolution)) - range
		var max_corner = Vector3i(floor(p / resolution)) + range
		
		for x in range(min_corner.x-1, max_corner.x+1):
			for y in range(min_corner.y-1, max_corner.y+1):
				for z in range(min_corner.z-1, max_corner.z+1):
					var key = Vector3i(x, y, z)
					var pos = key * resolution
					var dist = pos.distance_squared_to(p)
					var contribution: float = visible_range / (1.0 + dist)
					#contribution = float("%0.2f" % contribution)
					# * pos.normalized().dot(Vector3.ONE)
					
					#if key.clamp(min_corner, max_corner) == key:
						#temp_density_field[key] = "go"
					if temp_density_field.has(key):
						temp_density_field[key] += contribution
					else:
						temp_density_field[key] = contribution

	# 空间哈希优化
	var filtered_density_field = {}
	for key in temp_density_field.keys():
		if temp_density_field[key] >= threshold:
			filtered_density_field[key] = temp_density_field[key]
		#elif temp_density_field[key] == "go":
			#filtered_density_field[key] = 1.0
	density_field = density_field.merged(filtered_density_field, true)
	#density_field = density_field.merged(temp_density_field, true)
	#density_field = filtered_density_field

	#var data_image:= []
	#
	#var t3d:= ImageTexture3D.new()
	#t3d.create(Image.FORMAT_L8, 32, 32, 32, false, data_image)
