extends Node3D

@onready var PLAYER: Player = $".."
@onready var player_transform_marker: Node3D = $"../PlayerTransformMarker"

func _ready():
	await owner.ready

func _physics_process(_delta: float) -> void:
	debug_draw_line()

func debug_draw_line():
	var velocity_xz: Vector3 = Vector3(PLAYER.velocity.x, 0, PLAYER.velocity.z)
	# var velocity_normalized = PLAYER.velocity.normalized()
	# var velocity_x: Vector3 = Vector3(velocity_normalized.x, 0, 0)
	# var velocity_z: Vector3 = Vector3(0, 0, velocity_normalized.z)
	DebugDraw.draw_line_relative(global_position, velocity_xz.normalized()) # 速度方向平面
	DebugDraw.draw_mesh_line_relative(global_position, PLAYER.velocity.normalized(), 3, Color.RED, 0.3) # 速度方向
	# DebugDraw.draw_mesh_line_relative(global_position, velocity_x, 1, Color.AQUA)
	# DebugDraw.draw_mesh_line_relative(global_position, velocity_z, 1, Color.AQUA)
	DebugDraw.draw_mesh_line_relative(global_position, Vector3(0, 0, 0.3), 0.5, Color.GREEN) # 指向z
	# 按键方向
	DebugDraw.draw_mesh_line_relative(global_position + Vector3(0, 0.1, 0), PLAYER.input_direction, 2, Color.TURQUOISE, 0.3)
	DebugDraw.draw_mesh_line_relative(global_position + Vector3(0, 0.2, 0), -PLAYER.transform.basis.z * 0.3, 1, Color.BLACK, 0.3)
	DebugDraw.draw_mesh_line_relative(global_position + Vector3(0, 0.25, 0), -player_transform_marker.transform.basis.z * 0.3, 1, Color.WHITE, 0.3)
