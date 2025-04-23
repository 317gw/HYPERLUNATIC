@tool
extends DanmakuEmitter

var time: float = 0.0

func ready() -> void:
	#time_since_last_fire = fire_rate / 60.0
	#bullet_scale = Vector3.ONE * 1
	pass

func _bullet_event(_delta: float) -> void:
	time += _delta
	#rotation_y_speed += _delta * 0.01
	stripe_angle += _delta * 59
	#disk_angle += _delta * 20
	#spherical_count += _delta * 20
	#ratio += _delta * 0.01
	bullet_scale_multi = sin(Global.paused_time_physics_process) * 0.5 + 1.0
	var color:=  HL.rainbow_color_custom(Global.paused_time_physics_process)
	bullet_color1 = color
	bullet_color2 = Color(color, 0.5)
