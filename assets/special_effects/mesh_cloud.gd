@tool
extends MultiMeshInstance3D

@export var init_cloud: bool = false
@export var minimum_distance: float = 5 # m
@export_range(0, 100) var density_check_times: int = 5

#@export var cloud_width: float = 10 # m
#@export var cloud_radius: float = 100 # m

@export var size: Vector3 = Vector3.ONE
@export var cloud_move: Vector3 = Vector3.ZERO
@export var cloud_move_scale: float = 1.0

@export var near_edge_power: Vector3 = Vector3(0.2, 0.3, 0.2)

@export_range(0, 1) var noise_mask: float = 0.75 # m
@export var noise3D: NoiseTexture3D

var texture_noise3D_data: Array[Image]
var current_instance_count: int = 0
var cloud_basis: Array[Basis]
var cloud_pos: Array[Vector3]
var cloud_pos_offset: Vector3 = Vector3.ZERO

var check_distance_squared: float

#var pixel: Color

#var semaphore: Semaphore

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D



func _ready() -> void:
	if not Engine.is_editor_hint():
		mesh_instance_3d.queue_free()
	
	#await 
	_init_cloud_pos()
	apple_pos()


func _physics_process(delta: float) -> void:
	if init_cloud:
		init_cloud = false
		_init_cloud_pos()
	
	if Engine.is_editor_hint() and mesh_instance_3d:
		mesh_instance_3d.mesh.size = size
		return
	
	
	cloud_pos_offset += cloud_move * cloud_move_scale * delta

	# var time_start = Time.get_ticks_usec()
	apple_pos()
	# var time_end = Time.get_ticks_usec()
	# print("update_enemies() took %d microseconds" % (time_end - time_start))


func apple_pos() -> void:
	if cloud_pos.is_empty() or cloud_basis.is_empty():
		#print("cloud_ is_empty!!!!!")
		return
	for i in cloud_pos.size():
		var pos: Vector3 = cloud_pos[i] + cloud_pos_offset
		pos = Vector3(
			wrap(pos.x, -size.x/2, size.x/2), 
			wrap(pos.y, -size.y/2, size.y/2), 
			wrap(pos.z, -size.z/2, size.z/2)
		)
		
		var _size: float = clamp(
			mmm(pos.x/size.x, near_edge_power.x)*
			mmm(pos.y/size.y, near_edge_power.y)*
			mmm(pos.z/size.z, near_edge_power.z),
			0, 1)
		
		var T: Transform3D = Transform3D(cloud_basis[i] * _size, pos)
		multimesh.set_instance_transform(i, T)


func _init_cloud_pos() -> void:
	texture_noise3D_data.clear()
	current_instance_count = 0
	cloud_basis.clear()
	cloud_pos.clear()
	
	texture_noise3D_data = noise3D.get_data()
	if not texture_noise3D_data:
		await noise3D.changed
		texture_noise3D_data = noise3D.get_data()
	
	#print(texture_noise3D_data)
	if texture_noise3D_data.is_empty():
		print("texture_noise3D_data.is_empty")
		return
	
	check_distance_squared = min((size.x+size.y+size.z)/3, minimum_distance) ** 2
	
	for i in multimesh.instance_count:
		var result = _rand_pos(noise3D.depth, noise3D.width, noise3D.height)
		
		#var blocker:= AwaitBloker.new()
		#WorkerThreadPool.add_task(func():
			#blocker.set_meta("result", _rand_pos(noise3D.depth, noise3D.width, noise3D.height))
			#blocker.go_on_deferred()
		#)
		#await blocker.continued
		#var result = blocker.get_meta("result")
		
		#if not result[2]:
			#continue
		#current_instance_count += 1
		cloud_pos.append(result[0])
		cloud_basis.append(Basis.IDENTITY * result[1])

	
	#multimesh.visible_instance_count = current_instance_count
	


func _rand_pos(noise3D_depth: int, noise3D_width: int, noise3D_height: int) -> Array:
	var _density_check: int = 0
	while true:
		var pos: Vector3 = Vector3(
			randf_range(-size.x, size.x), 
			randf_range(-size.y, size.y), 
			randf_range(-size.z, size.z)
			)/2

		if density_check_times > 0 and _density_check < density_check_times:
			for i in range(density_check_times):
				_density_check += 1
				
				#var theta = randf_range(0, TAU)
				#var radiu = randf_range(0, cloud_radius)
				#
				#pos = Vector3(
					#radiu * cos(theta), 
					#randf_range(-cloud_width/2, cloud_width/2), 
					#radiu * sin(theta)
					#)

				var _pos: Vector3 = Vector3(
					randf_range(-size.x, size.x), 
					randf_range(-size.y, size.y), 
					randf_range(-size.z, size.z)
					)/2


				if check_density(_pos):
					pos = _pos
					break
				#if i == density_check_times-1:
					#return [Vector3.ZERO, 0, false]


		var h: int = int(remap(pos.y, -size.y/2, size.y/2, 0, noise3D_depth-1))
		var x: int = int(remap(pos.x, -size.x/2, size.x/2, 0, noise3D_width-1))
		var y: int = int(remap(pos.z, -size.z/2, size.z/2, 0, noise3D_height-1))
		#prints(h, x, y)
		
		var pixel: Color = texture_noise3D_data[h].get_pixel(x, y)
		#var get_pixel = func(): pixel = texture_noise3D_data[h].get_pixel(x, y)
		#get_pixel.call_deferred()
		
		#print(pixel)
		if pixel.r > noise_mask:
			return [pos, pixel.r]
	return [Vector3.ZERO, 0]


func check_density(pos: Vector3) -> bool:
	if cloud_pos.is_empty():
		return true

	#for i in range(cloud_pos.size()):
		#var dist = pos.distance_to(cloud_pos[i])
		#if dist < minimum_distance:
			#return false
	
	if cloud_pos.all(func(p): pos.distance_squared_to(p) < check_distance_squared):
		return false
	
	return true


func mmm(x: float, power: float = 1) -> float:
	return abs(cos(x*PI)) ** power
