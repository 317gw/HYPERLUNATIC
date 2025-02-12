# https://github.com/jbernardic/Godot-Smooth-Voxels/blob/main/Scripts/Terrain.gd
# MIT License
@tool
#class_name MarchingCubes
extends MeshInstance3D

@export	var MATERIAL: Material
@export var RESOLUTION: int = 32
#@export var SUBDIVIDE: int = 1  # 新增分块大小参数
@export var ISO_LEVEL: float = 0.0
@export var NOISE: FastNoiseLite
@export var FLAT_SHADED: bool = false
@export var TERRAIN_TERRACE: int = 1
@export_flags("x", "y", "z", "-x", "-y", "-z") var DISABLED_EDGES: int = 0

@export var GENERATE: bool:
	set(value):
		if not self is MeshInstance3D:
			return
		var time = Time.get_ticks_msec()
		voxel_grid = MarchingTable.VoxelGrid.new(size)
		mesh = generate()
		var elapsed = (Time.get_ticks_msec()-time)/1000.0
		print("Terrain generated in: " + str(elapsed) + "s")

var size: Vector3
var voxel_grid: MarchingTable.VoxelGrid
#var voxel_grid_optimized: VoxelGrid
var thread = Thread.new()


func _ready() -> void:
	#print(DISABLED_EDGES)
	size = Vector3(RESOLUTION, RESOLUTION, RESOLUTION)
	voxel_grid = MarchingTable.VoxelGrid.new(size, 0.0)
	#voxel_grid = VoxelGrid.new(size, CHUNK_SIZE)


func _noise(x:int, y:int, z:int):
	return NOISE.get_noise_3d(x, y, z)+(y+y%TERRAIN_TERRACE)/float(RESOLUTION)-0.5

func _scalar_field(x:float, y:float, z:float):
	return (x*x + y*y + z*z) / 60.0


func _calculate_vertices(data) -> PackedVector3Array:
	# 取消边界面
	var DEmax:= Vector3i(
		int(DISABLED_EDGES&1 == 0),
		int(DISABLED_EDGES&2 == 0),
		int(DISABLED_EDGES&4 == 0)
	)
	var DEmin:= Vector3i(
		int(DISABLED_EDGES&8 == 0),
		int(DISABLED_EDGES&16 == 0),
		int(DISABLED_EDGES&32 == 0)
	)
	
	var vertices = PackedVector3Array()
	
	if data is Callable:
		for z in range(DEmin.z, voxel_grid.resolution.z-DEmax.z):
			for y in range(DEmin.y, voxel_grid.resolution.y-DEmax.y):
				for x in range(DEmin.x, voxel_grid.resolution.x-DEmax.x):
					#var value = _noise(x, y, z)
					#var value = _scalar_field(x, y, z)
					#voxel_grid.write(x, y, z, value)
					voxel_grid.write(x, y, z, data.call(x, y, z))
		#march
		for z in voxel_grid.resolution.z-1:
			for y in voxel_grid.resolution.y-1:
				for x in voxel_grid.resolution.x-1:
					_march_cube(x, y, z, voxel_grid, vertices)

	if data is Dictionary:
		var resolution3 = Vector3i(voxel_grid.resolution.x, voxel_grid.resolution.y, voxel_grid.resolution.z)
		#var pos_write = data.keys().filter(func(v: Vector3i): return v.clamp(DEmin, resolution3 - DEmax) == v)
		var pos_write = data.keys().filter(func(v: Vector3i): return v.clamp(Vector3i.ZERO, resolution3 - Vector3i.ONE) == v)
		#var pos_march = data.keys().filter(func(v: Vector3i): return v.clamp(Vector3i.ZERO, resolution3 - Vector3i.ONE) == v)
		#print(pos_march)
		#voxel_grid.data.fill(0.0)
		for pos in pos_write:
			voxel_grid.write(pos.x, pos.y, pos.z, data[pos])
		#for pos in pos_march:
			#print(pos)
			#_march_cube(pos.x, pos.y, pos.z, voxel_grid, vertices)
		for z in voxel_grid.resolution.z-1:
			for y in voxel_grid.resolution.y-1:
				for x in voxel_grid.resolution.x-1:
					_march_cube(x, y, z, voxel_grid, vertices)
	
	if data is MarchingTable.VoxelGrid:
		for z in data.resolution-1:
			for y in data.resolution-1:
				for x in data.resolution-1:
					_march_cube(x, y, z, data, vertices)
	
	return vertices


# callable: Callable = _scalar_field
func generate(data = _scalar_field, generate_pos: Vector3 = Vector3.ZERO) -> ArrayMesh:
	var time = Time.get_ticks_msec()
	
	var vertices: PackedVector3Array
	vertices = _calculate_vertices(data)
	#thread.start(_calculate_vertices.bind(data))
	#vertices = thread.wait_to_finish()
	
	var elapsed = (Time.get_ticks_msec()-time)/1000.0
	print("Terrain generated in: " + str(elapsed) + "s")
	
	#draw
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	if FLAT_SHADED:
		surface_tool.set_smooth_group(-1)
	for vert in vertices:
		surface_tool.add_vertex(vert)
	surface_tool.generate_normals()
	surface_tool.index()
	#surface_tool.set_material(MATERIAL)
	
	return surface_tool.commit()


func _march_cube(x:int, y:int, z:int, voxel_grid:MarchingTable.VoxelGrid, vertices:PackedVector3Array):
	var tri = _get_triangulation(x, y, z, voxel_grid)
	if tri == null:
		return
	for edge_index in tri:
		if edge_index < 0: break
		var point_indices = MarchingTable.EDGES[edge_index]
		var p0 = Vector3(MarchingTable.POINTS[point_indices[0]])
		var p1 = Vector3(MarchingTable.POINTS[point_indices[1]])
		var pos_a = Vector3(x, y, z) + p0
		var pos_b = Vector3(x, y, z) + p1
		
		#var position = (pos_a + pos_b)*0.5
		var pos = _calculate_interpolation(pos_a, pos_b, voxel_grid)
		vertices.append(pos)


func _calculate_interpolation(a:Vector3, b:Vector3, voxel_grid:MarchingTable.VoxelGrid):
	var val_a = voxel_grid.read(a.x, a.y, a.z)
	var val_b = voxel_grid.read(b.x, b.y, b.z)
	return a.lerp(b, inverse_lerp(val_a, val_b, ISO_LEVEL))


func _get_triangulation(x:int, y:int, z:int, voxel_grid:MarchingTable.VoxelGrid):
	var idx = 0b00000000
	for i in 8:
		var offset: Vector3i = MarchingTable.POINTS[i]
		idx |= (int(voxel_grid.read(x+offset.x, y+offset.y, z+offset.z) < ISO_LEVEL) << i)
	if idx == 0 or idx == 0b11111111:
		return null
	else:
		return MarchingTable.TRIANGULATIONS[idx]
