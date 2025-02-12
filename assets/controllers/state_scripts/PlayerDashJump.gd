class_name PlayerDashJump
extends State


@onready var PLAYER: HL.Player = $"../.."
@onready var dash: PlayerDash = $"../Dash"
@onready var climb: Climb = $"../../Climb"


func Enter():
	dash.dash_number += 1
	dash.calculate_dashjump_parameters()
	PLAYER.jump_ready(dash.dashjump_vel)
	#PLAYER.vel_hor = dash.dash_dir3d * dash.dashjump_speed
	PLAYER.air_speed = dash.dashjump_speed
	#PLAYER.vel_hor = PLAYER.vel_hor.normalized() * dash.dashjump_speed
	PLAYER.apply_velocity()


func Exit():
	PLAYER.air_acc_target = 0


func Physics_Update(_delta: float) -> void:
	PLAYER.stop_movement(_delta)
	PLAYER.movement_air(_delta, true)
	PLAYER.swimming(_delta)
	PLAYER.apply_gravity(-dash.dashjump_gravity, _delta)
	if PLAYER.not_air_speed_clamp_timer.time_left == 0:
		PLAYER.air_speed_clamp(_delta)
	PLAYER.jumping_up()

	PLAYER.jump_debug()
	PLAYER.apply_velocity()

	if PLAYER.vel_up < -dash.dashjump_vel: # 如果玩家正在正在下落
		Transitioned.emit(self, "Fall")
		return

	if PLAYER.is_on_floor(): # 地面
		PLAYER.landing_sound_player()
		if PLAYER.dir_hor:
			Transitioned.emit(self, "Run")
			return
		else:
			Transitioned.emit(self, "Idle")
			return
	if climb.can_climb() and climb.climb_on_dash_jump:
		Transitioned.emit(self, "Climb")
		return
	#if PLAYER.is_swimming() and not PLAYER.is_on_floor():
		#Transitioned.emit(self, "Swim")
		#return


func Handle_Input(_event: InputEvent) -> void:
	if _event.is_action_pressed("free_view_mode"):
		Transitioned.emit(self, "FreeViewMode")
		return
