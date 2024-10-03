class_name Probe
extends Area3D

var velocity: Vector3 = Vector3.ZERO
var global_position_lest_frame: Vector3 = Vector3.ZERO

func _ready() -> void:
	global_position_lest_frame = global_position

func _physics_process(delta: float) -> void:
	velocity = (global_position - global_position_lest_frame) / delta
	global_position_lest_frame = global_position
