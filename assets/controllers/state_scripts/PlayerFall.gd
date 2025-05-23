class_name PlayerFall
extends State

@onready var PLAYER: HL.Player = $"../.."
@onready var camera: HL.Camera = $"../../Head/Camera3D"
@onready var snap_stairs: SnapStairs = $"../../SnapStairs"
@onready var climb: Climb = $"../../Climb"
@onready var dash: PlayerDash = $"../Dash"


func Enter():
	pass
	#player.Calculate_Jump_Distance()
	#player.Calculate_Jump_Parameters()


func Exit():
	pass


func Physics_Update(_delta: float) -> void:
	PLAYER.stop_movement(_delta)
	PLAYER.movement_air(_delta)
	PLAYER.apply_gravity(-PLAYER.gravity_fall, _delta)
	PLAYER.swimming(_delta)
	PLAYER.air_speed_clamp(_delta)

	#PLAYER.apply_velocity(PLAYER.ApplyVelocityMode.MOVE_AND_COLLIDE)
	PLAYER.apply_velocity()
	snap_stairs.snap_down_to_stairs_check(true)
	camera.slide_camera_smooth_back_to_origin(_delta)

	if PLAYER.is_on_floor(): # 地面
		PLAYER.landing_sound_player()
		if PLAYER.dir_hor:
			Transitioned.emit(self, "Run")
			return
		else:
			Transitioned.emit(self, "Idle")
			return
	if PLAYER.can_jump():
		Transitioned.emit(self, "Jump")
		return
	if PLAYER.can_dash():
		Transitioned.emit(self, "Dash")
		return
	if climb.can_climb():
		Transitioned.emit(self, "Climb")
		return
	#if PLAYER.is_swimming() and not PLAYER.is_on_floor():
		#Transitioned.emit(self, "Swim")
		#return

func Handle_Input(_event: InputEvent) -> void:
	if _event.is_action_pressed("free_view_mode"):
		Transitioned.emit(self, "FreeViewMode")
		return
