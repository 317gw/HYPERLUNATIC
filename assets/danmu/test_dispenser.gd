@tool
class_name TestDispenser
extends Dispenser

var rotation_y_speed: float = 0
var 屎

func ready() -> void:
	#time_since_last_fire = fire_period / 60.0
	bullet_scale = Vector3.ONE * 1


func bullet_event(_delta: float) -> void:
	#rotation_y_speed += _delta * 0.01
	stripe_angle += _delta * 20
	disk_angle += _delta * 20
	#spherical_count += _delta * 20
	#ratio += _delta * 0.01
	pass
