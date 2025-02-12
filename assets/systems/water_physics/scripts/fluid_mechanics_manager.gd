extends Node3D


const FLUID_MECHANICS = preload("res://assets/systems/water_physics/fluid_mechanics.tscn")
const PROBE = preload("res://assets/systems/water_physics/probe.tres")

#@export var voxel_point_distance: float = 1 # m

var space_state: PhysicsDirectSpaceState3D
var water_mesh_3d_s: Dictionary = {} # {"id": 0, "body": dddddd}
var rigid_bodys_fluid_mechanics: Array = []
var probe_finish: bool = false
var probe_buoy_count: int = 0
var probe_slice_count: int = 0
var probe_buoy: Mesh
var probe_slice: Mesh

var _probe_count: int = 0

var _average_physics_process_m: float = 0
var _history: Array[float] = []
const _history_size: int = 120

#var _multi_probe_thread = Thread.new()
#var _force_thread = Thread.new()
#var _thread_queue = ThreadQueue.new(1024)  # 创建一个线程队列
#var _octree = Octree.new(Vector3.ZERO, 100.0, 1000)


@onready var area_3d: Area3D = $Area3D
@onready var timer: Timer = $Timer
@onready var multi_probe_buoy: MultiMeshInstance3D = $MultiProbeBuoy
@onready var multi_probe_slice: MultiMeshInstance3D = $MultiProbeSlice


func _ready() -> void:
	probe_buoy = PROBE.duplicate()
	probe_slice = PROBE.duplicate()
	_history.resize(_history_size)

func _physics_process(_delta: float) -> void:
	space_state = get_world_3d().direct_space_state
	if not probe_finish:
		return
	
	
	#_apply_force(_delta)
	
	#_multi_probe_thread.wait_to_finish()
	#_multi_probe_thread.start(_update_multi_probe_pos)
	#
	#_force_thread.wait_to_finish()
	#_force_thread.start(_apply_force.bind(_delta))
	
	#_probe_count = 0
	#if _thread_queue._working:
		#await _thread_queue._thread_finished
	
	
	
	#var time_start = Time.get_ticks_usec()
	#for rbfm: HL.FluidMechanics in rigid_bodys_fluid_mechanics:
		#rbfm.space_state = space_state
		#rbfm.apply_force(_delta)
		##_update_multi_probe_pos(rbfm)
	#var time_end = Time.get_ticks_usec()
	#
	## 平均计时
	#_history.push_back(time_end - time_start)
	#if _history.size() > _history_size:
		#_history.pop_front()
	#_average_physics_process_m = 0
	#for i in _history:
		#_average_physics_process_m += i
	#_average_physics_process_m /= _history_size
	#prints("took %d microseconds" % (time_end - time_start), int(_average_physics_process_m))
	
	
	
		#var force_p: Vector3 = -Global.gravity * rbfm.volume / rbfm.probe_buoy_pos.size()
		#_thread_queue.add_job(_apply_force, ThreadQueue._nop, [rbfm, force_p])
		#_thread_queue.add_job(_update_multi_probe_pos, ThreadQueue._nop, [rbfm])
	#_thread_queue.start()


#func _apply_force(_rbfm: HL.FluidMechanics, _force_p: Vector3) -> void:
	#for i in _rbfm.probe_buoy_pos.size():
		#var density: float = float(_rbfm.is_point_in_water(_rbfm.probe_buoy_pos[i])[0])
		#if density == 0:
			#continue
		#
		#_rbfm._parent_rigid_body.apply_force(
			#_force_p * density,
			#_rbfm.probe_buoy_pos[i]
			#)

# 
func _update_multi_probe_pos(_rbfm: HL.FluidMechanics) -> void:
	for i in _rbfm.probe_buoy_pos.size():
		multi_probe_buoy.multimesh.set_instance_transform(
			_probe_count,
			Transform3D(
				Basis.IDENTITY,
				_rbfm.global_basis * _rbfm.probe_buoy_pos[i] + _rbfm.global_position)
			)
		_probe_count += 1

# ).call_deferred()


# 读取场景中的所有RigidBody3D，添加FluidMechanics
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		if body.has_meta("fluid_mechanics"):
			return
		var fluid_mechanics: HL.FluidMechanics = FLUID_MECHANICS.instantiate()
		body.add_child(fluid_mechanics, true)
		#fluid_mechanics.name = "FluidMechanics"
		#fluid_mechanics.voxel_point_distance = voxel_point_distance
		rigid_bodys_fluid_mechanics.append(fluid_mechanics)


# 生成完毕
func _on_timer_timeout() -> void:
	area_3d.monitoring = false
	area_3d.monitorable = false
	area_3d.process_mode = Node.PROCESS_MODE_DISABLED

	for rbfm in rigid_bodys_fluid_mechanics:
		rbfm.space_state = space_state
		rbfm.generate_voxel_points()
		rbfm.voxel_points_ready = true
		probe_buoy_count += rbfm.probe_buoy_pos.size()
		#probe_slice_count += rbfm.probe_slice_pos.size()

	multi_probe_buoy.multimesh = _set_multi_mesh(probe_buoy_count, probe_buoy)
	multi_probe_slice.multimesh = _set_multi_mesh(probe_slice_count, probe_slice)

	probe_finish = true


func _set_multi_mesh(instance_count: int, mesh: Mesh) -> MultiMesh:
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = instance_count
	multimesh.mesh = mesh
	return multimesh





#
#func _enter_tree() -> void:
	#_multi_probe_thread.wait_to_finish()
	#_force_thread.wait_to_finish()
