extends RigidBody3D

#@export var point_count: int = 10
#@export var is_spawn: bool = false
@export_range(0, 1, 0.01) var disappear_time: float = 0.1
#
#var points: Array = []
#var trail_mesh: ImmediateMesh

#@onready var trail: MeshInstance3D = $Trail
@onready var timer: Timer = $Timer

#func _ready() -> void:
	#trail_mesh = trail.mesh

	#trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	#trail_mesh.surface_set_color(Color(1, 1, 1, 1))
	#trail_mesh.surface_add_vertex(Vector3.LEFT)
	#trail_mesh.surface_add_vertex(Vector3.FORWARD)
	#trail_mesh.surface_add_vertex(Vector3.ZERO)
	#trail_mesh.surface_end()

func _physics_process(_delta: float) -> void:
	if timer.time_left / timer.wait_time <= disappear_time:
		scale = Vector3.ONE * timer.time_left / timer.wait_time / disappear_time

	#通过添加点来模拟轨迹
	#if is_spawn:
		#if points.size() > point_count:
			#points.remove_at(0)
		#points.append(global_position)
	#else:
		#if points.size() > 0:
			#points.remove_at(0)

func _on_timer_timeout() -> void:
	queue_free()
