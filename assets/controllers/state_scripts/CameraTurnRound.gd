extends State
class_name CameraTurnRound

var camera_rot: float
var rot_tgt: float # rotate_target
var rotate_type = null
var Limit_Angle: float = 67
enum Rotate_Type {BACK, UP, DOWN,}

@onready var PLAYER: HL.Player = $"../.."
@onready var Head: Node3D = $"../../Head"
@onready var Camera: HL.Camera = $"../../Head/Camera3D"


func Enter():
	PLAYER.turn_round_timer.start()
	camera_rot = Camera._mouse_rotation.x
	if camera_rot < deg_to_rad(91) and camera_rot > deg_to_rad(Limit_Angle):
		rotate_type = Rotate_Type.UP
	elif camera_rot < deg_to_rad( - Limit_Angle) and camera_rot > deg_to_rad( - 91):
		rotate_type = Rotate_Type.DOWN
	else:
		rotate_type = Rotate_Type.BACK
	rot_tgt = PI / 2 + abs(camera_rot)


func Exit():
	match rotate_type:
		Rotate_Type.UP:
			up_down_exit()
		Rotate_Type.DOWN:
			up_down_exit()
		Rotate_Type.BACK:
			PLAYER.turn_round_rotation = 0.0
			Camera._mouse_rotation.y += PI


func Physics_Update(_delta: float) -> void:
	match rotate_type:
		Rotate_Type.UP:
			up_down( - 1, _delta)
		Rotate_Type.DOWN:
			up_down(1, _delta)
		Rotate_Type.BACK:
			PLAYER.turn_round_rotation = lerp(PLAYER.turn_round_rotation, PI, PI * _delta / 0.18)
			if is_equal_approx(PLAYER.turn_round_rotation, PI):
				Transitioned.emit(self, "CameraIdle")


func up_down(signs: int, _delta: float) -> void:
	Camera.up_down_rotation = lerp(Camera.up_down_rotation, signs * rot_tgt, PI * _delta / 0.18)
	if is_equal_approx(Camera.up_down_rotation, signs * rot_tgt):
		Transitioned.emit(self, "CameraIdle")
	if abs(Camera.up_down_rotation / rot_tgt) > 0.95 and Camera._mouse_input:
		Transitioned.emit(self, "CameraIdle")


func up_down_exit() -> void:
	Camera._mouse_rotation.x += Camera.up_down_rotation
	Camera.up_down_rotation = 0.0
