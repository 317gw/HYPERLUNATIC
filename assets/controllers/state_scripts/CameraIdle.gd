extends State
class_name CameraIdle

@onready var PLAYER: HL.Controller.Player = $"../.."
@onready var Head: Node3D = $"../../Head"
@onready var Camera: HL.Controller.Camera = $"../../Head/Camera3D"


func Enter():
	pass


func Exit():
	pass


func Physics_Update(_delta: float) -> void:
	Camera.look_back_rotation = lerp(Camera.look_back_rotation, 0.0, PI * _delta / 0.18)


func Handle_Input(_event: InputEvent) -> void:
	if _event.is_action_pressed("look_back"):
		Transitioned.emit(self, "LookBack")
	if _event.is_action_pressed("turn_round") and can_turn_round():
		Transitioned.emit(self, "TurnRound")


func can_turn_round() -> bool:
	return (PLAYER.turn_round_timer.time_left == 0 and
			not PLAYER.movement_state_machine.current_state is PlayerDash and
			not PLAYER.movement_state_machine.current_state is PlayerDashJump)
