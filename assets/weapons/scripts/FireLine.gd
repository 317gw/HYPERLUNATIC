extends Node3D
class_name FireLine

# const FIRE_LIGHT_CALIBRE:float = 2.0
var start_pos: Vector3 = Vector3(0, 0, 0)
var end_pos: Vector3 = Vector3(0, 0, 0)
var fire_light_calibre: float = 2.0
var fire_line_color: Color = Color(1, 1, 1, 1)
var dead_time: float = 0.5

# var time: float = 0.0
var target_fire_light_calibre: float = 0.0

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.wait_time = dead_time
	global_position = start_pos

func _physics_process(_delta: float) -> void:
	# time -= delta
	target_fire_light_calibre = lerp(target_fire_light_calibre, 0.0, timer.time_left / timer.wait_time)
	# print(target_fire_light_calibre)
	DebugDraw.draw_mesh_line_relative(start_pos, end_pos, target_fire_light_calibre, fire_line_color)

func set_line(shoot_pos: Vector3, target_pos: Vector3, calibre: float=4, color: Color=Color(1, 1, 1, 1), time: float=1):
	start_pos = shoot_pos
	end_pos = target_pos
	fire_line_color = color
	dead_time = time
	target_fire_light_calibre = calibre # 得一次
	#print("start_pos:", start_pos)
	#print("line_pos:", global_position)
	#print("end_pos:", end_pos)

func _on_timer_timeout() -> void:
	self.queue_free()
