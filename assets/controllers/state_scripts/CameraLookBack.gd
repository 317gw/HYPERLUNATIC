extends State
class_name CameraLookBack

@onready var PLAYER: HL.Player = $"../.."
@onready var Head: Node3D = $"../../Head"
@onready var Camera: HL.Camera = $"../../Head/Camera3D"


func Enter():
	pass


func Exit():
	pass


func Physics_Update(_delta: float) -> void:
	Camera.look_back_rotation = lerp(Camera.look_back_rotation, 0.9999 * PI, PI * _delta / 0.18) # 回头


func Handle_Input(_event: InputEvent) -> void:
	if _event.is_action_released("look_back"):
		Transitioned.emit(self, "CameraIdle")
	if _event.is_action_pressed("turn_round") and PLAYER.turn_round_timer.time_left == 0:
		# 回头后转身
		Transitioned.emit(self, "CameraIdle")
		Camera._mouse_rotation.y += Camera.look_back_rotation
		Camera.look_back_rotation = 0.0
		Camera.mouse_tilt_angle = abs(Camera.mouse_tilt_angle)
