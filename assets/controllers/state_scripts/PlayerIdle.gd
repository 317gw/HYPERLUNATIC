class_name PlayerIdle
extends State

@onready var PLAYER: HL.Player = $"../.."
@onready var camera: HL.Camera = $"../../Head/Camera3D"
@onready var dash: PlayerDash = $"../Dash"


func Enter():
	dash.dash_dir3d = Vector3.ZERO
	dash.reset_dash_number()


func Exit():
	pass


func Physics_Update(_delta: float) -> void:
	PLAYER.stop_movement(_delta)
	PLAYER.apply_gravity(-PLAYER.gravity_fall, _delta) # 关闭为特性，无操控滑出地面，可悬浮
	PLAYER.swimming(_delta)
	PLAYER.air_speed_clamp(_delta)

	PLAYER.apply_velocity()
	camera.slide_camera_smooth_back_to_origin(_delta)

	#var direction :=
	if PLAYER.is_swimming() and not PLAYER.is_on_floor():
		Transitioned.emit(self, "Fall")
		return
	if Input.get_vector("move_left", "move_right", "move_forward", "move_backward"):
		Transitioned.emit(self, "Run")
		return
	if PLAYER.can_dash_jump():
		Transitioned.emit(self, "DashJump")
		return
	if PLAYER.can_jump():
		Transitioned.emit(self, "Jump")
		return
	if PLAYER.can_dash():
		Transitioned.emit(self, "Dash")
		return


func Handle_Input(_event: InputEvent) -> void:
	if _event.is_action_pressed("free_view_mode"):
		Transitioned.emit(self, "FreeViewMode")
		return
