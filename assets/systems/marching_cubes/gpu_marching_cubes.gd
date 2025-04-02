@tool
extends MeshInstance3D

const uniform_set_index: int = 0

@export var ISO: float = 0.1
#@export var TextureDATA: Texture3D
@export var FLAT_SHADED: bool = false

var rd = RenderingServer.create_local_rendering_device()
var pipeline: RID
var shader: RID
var buffers: Array
var uniform_set: RID

var output
var _needs_buffer_rebuild := true
#var DATA  #: MarchingTable.VoxelGrid
var voxel_grid: MarchingTable.VoxelGrid
var data_size: Vector3
#var current_data_size: Vector3

#@export var GENERATE: bool:
	#set(value):
		#var time = Time.get_ticks_msec()
		#DATA = TextureDATA
		#compute()
		#var elapsed = (Time.get_ticks_msec()-time)/1000.0
		#print("Terrain generated in: " + str(elapsed) + "s")


func _ready():
	init_compute()
	#voxel_grid = MarchingTable.VoxelGrid.new(Vector3(16, 16 ,16))
	setup_bindings(true)


func _notification(type):
	if type == NOTIFICATION_PREDELETE:
		release()


func release():
	for b in buffers:
		rd.free_rid(b)
	buffers.clear()
	rd.free_rid(pipeline)
	rd.free_rid(shader)
	rd.free()


func set_voxel_grid(new_grid: MarchingTable.VoxelGrid):
	if voxel_grid and (voxel_grid.resolution != new_grid.resolution):
		_needs_buffer_rebuild = true

	voxel_grid = new_grid
	if is_inside_tree() and rd:
		compute()


func get_params():
	#data_size = Vector3(TextureDATA.get_width(), TextureDATA.get_height(), TextureDATA.get_depth())
	#var voxel_grid:= MarchingTable.VoxelGrid.new(data_size)
	#voxel_grid.set_data(TextureDATA)

	data_size = voxel_grid.resolution
	var params = PackedFloat32Array()
	params.append(data_size.x)
	params.append(data_size.y)
	params.append(data_size.z)
	params.append(ISO)
	params.append(int(FLAT_SHADED))
	params.append_array(voxel_grid.data)
	return params


func init_compute():
	# Create shader and pipeline
	var shader_file = load("res://assets/systems/marching_cubes/marching_cubes.glsl")
	var shader_spirv = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)


func setup_bindings(force_rebuild := false):
	if not (force_rebuild or _needs_buffer_rebuild or buffers.is_empty()) or not voxel_grid:
		return
	for b in buffers:
		rd.free_rid(b)
	buffers.clear()

	# Create the input params buffer
	var input = get_params()
	var input_bytes = input.to_byte_array()
	buffers.push_back(rd.storage_buffer_create(input_bytes.size(), input_bytes))

	# Create counter buffer
	var counter_bytes = PackedFloat32Array([0]).to_byte_array()
	buffers.push_back(rd.storage_buffer_create(counter_bytes.size(), counter_bytes))

	# Create the triangles buffer
	var total_cells = data_size.x * data_size.y * data_size.z
	var vertices = PackedColorArray()
	vertices.resize(total_cells * 5 * (3 + 1)) # 5 triangles max per cell, 3 vertices and 1 normal per triangle
	var vertices_bytes = vertices.to_byte_array()
	buffers.push_back(rd.storage_buffer_create(vertices_bytes.size(), vertices_bytes))

	# Create the LUT buffer
	var lut_array = PackedInt32Array()
	for i in range(MarchingTable.TRIANGULATIONS.size()):
		lut_array.append_array(MarchingTable.TRIANGULATIONS[i])
	var lut_array_bytes = lut_array.to_byte_array()
	buffers.push_back(rd.storage_buffer_create(lut_array_bytes.size(), lut_array_bytes))

	_create_uniform_set()
	#current_data_size = voxel_grid.resolution
	_needs_buffer_rebuild = false


func _create_uniform_set():
	var input_params_uniform := RDUniform.new()
	input_params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	input_params_uniform.binding = 0
	input_params_uniform.add_id(buffers[0])

	var counter_uniform = RDUniform.new()
	counter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	counter_uniform.binding = 1
	counter_uniform.add_id(buffers[1])

	var vertices_uniform := RDUniform.new()
	vertices_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	vertices_uniform.binding = 2
	vertices_uniform.add_id(buffers[2])

	var lut_uniform := RDUniform.new()
	lut_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	lut_uniform.binding = 3
	lut_uniform.add_id(buffers[3])

	uniform_set = rd.uniform_set_create([
		input_params_uniform,
		counter_uniform,
		vertices_uniform,
		lut_uniform,
	], shader, uniform_set_index)


func compute():
	if voxel_grid == null:
		return
	setup_bindings()

	# Update input buffers and clear output ones
	# This one is actually not always needed. Comment to see major speed optimization
	var input = get_params()
	var input_bytes = input.to_byte_array()
	rd.buffer_update(buffers[0], 0, input_bytes.size(), input_bytes)

	var total_cells = data_size.x * data_size.y * data_size.z
	var vertices = PackedColorArray()
	vertices.resize(total_cells * 5 * (3 + 1)) # 5 triangles max per cell, 3 vertices and 1 normal per triangle
	var vertices_bytes = vertices.to_byte_array()

	var counter_bytes = PackedFloat32Array([0]).to_byte_array()
	rd.buffer_update(buffers[1], 0, counter_bytes.size(), counter_bytes)

	# Dispatch compute and uniforms
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, uniform_set_index)
	rd.compute_list_dispatch(compute_list, data_size.x / 8, data_size.y / 8, data_size.z / 8)
	rd.compute_list_end()

	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()

	# Read back the data from the buffer
	var total_triangles = rd.buffer_get_data(buffers[1]).to_int32_array()[0]
	var output_array := rd.buffer_get_data(buffers[2]).to_float32_array()

	output = {
		"vertices": PackedVector3Array(),
		"normals": PackedVector3Array(),
	}

	for i in range(0, total_triangles * 16, 16): # Each triangle spans for 16 floats
		output["vertices"].push_back(Vector3(output_array[i+0], output_array[i+1], output_array[i+2]))
		output["vertices"].push_back(Vector3(output_array[i+4], output_array[i+5], output_array[i+6]))
		output["vertices"].push_back(Vector3(output_array[i+8], output_array[i+9], output_array[i+10]))

		var normal = Vector3(output_array[i+12], output_array[i+13], output_array[i+14])
		# Each vector will point to the same normal
		for j in range(3):
			output["normals"].push_back(normal)

	create_mesh_with_array()


func create_mesh_with_array():
	var mesh_data = []
	mesh_data.resize(Mesh.ARRAY_MAX)
	mesh_data[Mesh.ARRAY_VERTEX] = output["vertices"]
	mesh_data[Mesh.ARRAY_NORMAL] = output["normals"]

	var array_mesh = ArrayMesh.new()
	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
	call_deferred("set_mesh", array_mesh)


func create_mesh_with_surface():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	if FLAT_SHADED:
		surface_tool.set_smooth_group(-1)

	for vert in output["vertices"]:
		surface_tool.add_vertex(vert)

	surface_tool.generate_normals()
	surface_tool.index()
	call_deferred("set_mesh", surface_tool.commit())
