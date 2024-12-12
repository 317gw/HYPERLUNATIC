class_name PlayerDashJump
extends State

@onready var PLAYER: HL.Controller.Player = $"../.."
@onready var climb: Climb = $"../../Climb"


func Enter():
	# player.Calculate_Jump_Distance()
	# player.Calculate_Air_Speed(player.DashJump_Distance, player.DashJump_Time)
	PLAYER.calculate_dashjump_parameters()
	PLAYER.jump_ready(PLAYER.dashjump_vel)
	PLAYER.vel2d = Vector2(PLAYER.dash_dir3d.x, PLAYER.dash_dir3d.z) * PLAYER.dashjump_speed
	PLAYER.air_speed = PLAYER.dashjump_speed
	PLAYER.apply_velocity()


func Exit():
	PLAYER.air_acc_target = 0


func Physics_Update(_delta: float) -> void:
	PLAYER.stop_movement(_delta)
	PLAYER.movement_air(_delta, true)
	PLAYER.apply_gravity(PLAYER.dashjump_gravity, _delta)
	if PLAYER.not_air_speed_clamp_timer.time_left == 0:
		PLAYER.air_speed_clamp(_delta)
	PLAYER.jumping_up()

	PLAYER.jump_debug()
	PLAYER.apply_velocity()

	if PLAYER.velocity.y < -PLAYER.dashjump_vel: # 如果玩家正在正在下落
		Transitioned.emit(self, "Fall")

	if PLAYER.is_on_floor(): # 地面
		PLAYER.landing_sound_player()
		if PLAYER.dir2d:
			Transitioned.emit(self, "Run")
		else:
			Transitioned.emit(self, "Idle")
	if climb.can_climb() and climb.climb_on_dash_jump:
		Transitioned.emit(self, "Climb")


func Handle_Input(_event: InputEvent) -> void:
	if _event.is_action_pressed("free_view_mode"):
		Transitioned.emit(self, "FreeViewMode")
