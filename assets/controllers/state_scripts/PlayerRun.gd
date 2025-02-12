class_name PlayerRun
extends State

@onready var PLAYER: HL.Player = $"../.."
@onready var camera: HL.Camera = $"../../Head/Camera3D"
@onready var snap_stairs: SnapStairs = $"../../SnapStairs"
@onready var dash: PlayerDash = $"../Dash"


func Enter():
	dash.reset_dash_number()


func Exit():
	pass


func Physics_Update(_delta: float) -> void:
	#print("   ")
	if snap_stairs.snap_up_stairs_check(_delta):
		#print("snap_up")
		if PLAYER.vel_hor.length() > PLAYER.speed_normal:
			PLAYER.vel_hor = move_toward(PLAYER.vel_hor.length(), PLAYER.speed_normal, PLAYER.acc_normal * 0.2 * _delta) * PLAYER.vel_hor.normalized()
		move(_delta, false)
	else:
		#print("snap_down")
		move(_delta)
		snap_stairs.snap_down_to_stairs_check()
	camera.slide_camera_smooth_back_to_origin(_delta)

	#PLAYER.movement_floor(_delta)
	#PLAYER.air_speed_clamp(_delta)
	#PLAYER.apply_velocity()


	if not PLAYER.dir_hor: # 无方向输入
		Transitioned.emit(self, "Idle")
		return
	if not PLAYER.is_on_floor():
		#if PLAYER.is_swimming():
			#Transitioned.emit(self, "Swim")
			#return
		Transitioned.emit(self, "Fall")
		return
		PLAYER.coyote_timer.start()
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


func move(_delta: float, do_move_and_slide: bool = true) -> void:
		PLAYER.movement_floor(_delta)
		#PLAYER.swimming(_delta)
		PLAYER.apply_gravity(-PLAYER.gravity_fall, _delta)
		PLAYER.air_speed_clamp(_delta)
		PLAYER.apply_velocity(do_move_and_slide)
