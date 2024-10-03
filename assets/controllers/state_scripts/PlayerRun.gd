class_name PlayerRun
extends State

@onready var PLAYER: Player = $"../.."
@onready var camera: PlayerCamera = $"../../Head/Camera3D"
@onready var snap_stairs: SnapStairs = $"../../SnapStairs"


func Enter():
	PLAYER.reset_dash_number()


func Exit():
	pass


func Physics_Update(_delta: float) -> void:
	#print("   ")
	if snap_stairs.snap_up_stairs_check(_delta):
		#print("snap_up")
		if PLAYER.vel2d_speed > PLAYER.speed_normal:
			PLAYER.vel2d_speed = move_toward(PLAYER.vel2d_speed, PLAYER.speed_normal, PLAYER.acc_normal * 0.2 * _delta)
		move(_delta, false)
	else:
		#print("snap_down")
		move(_delta)
		snap_stairs.snap_down_to_stairs_check()
	camera.slide_camera_smooth_back_to_origin(_delta)

	#PLAYER.movement_floor(_delta)
	#PLAYER.air_speed_clamp(_delta)
	#PLAYER.apply_velocity()


	if not PLAYER.dir2d: # 无方向输入
		Transitioned.emit(self, "Idle")
	if not PLAYER.is_on_floor():
		Transitioned.emit(self, "Fall")
		PLAYER.coyote_timer.start()
	if PLAYER.can_dash_jump():
		Transitioned.emit(self, "DashJump")
	if PLAYER.can_jump():
		Transitioned.emit(self, "Jump")
	if PLAYER.can_dash():
		Transitioned.emit(self, "Dash")


func Handle_Input(_event: InputEvent) -> void:
	if _event.is_action_pressed("free_view_mode"):
		Transitioned.emit(self, "FreeViewMode")


func move(_delta: float, do_move_and_slide: bool = true) -> void:
		PLAYER.movement_floor(_delta)
		PLAYER.air_speed_clamp(_delta)
		PLAYER.apply_velocity(do_move_and_slide)
