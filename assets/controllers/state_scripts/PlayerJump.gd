class_name PlayerJump
extends State

@onready var PLAYER: HL.Controller.Player = $"../.."
@onready var climb: Climb = $"../../Climb"
@onready var dash: PlayerDash = $"../Dash"
@onready var climb_state: PlayerClimb = $"../Climb"


func Enter():
	PLAYER.calculate_jump_distance()
	PLAYER.calculate_air_speed(PLAYER.jump_distance, PLAYER.jump_time, true)
	PLAYER.jump_ready(PLAYER.jump_vel)


func Exit():
	PLAYER.air_acc_target = 0


func Physics_Update(_delta: float) -> void:
	PLAYER.stop_movement(_delta)
	PLAYER.movement_air(_delta)
	PLAYER.apply_gravity(PLAYER.gravity_jump, _delta)
	if PLAYER.not_air_speed_clamp_timer.time_left == 0:
		PLAYER.air_speed_clamp(_delta)
	PLAYER.jumping_up()

	PLAYER.jump_debug()
	PLAYER.apply_velocity()


	if PLAYER.velocity.y <= 0: # 如果玩家正在正在下落
		Transitioned.emit(self, "Fall")
	# 如果玩家松开了跳跃键
	if (not Input.is_action_pressed("jump") or climb_state.is_climb_jump) and PLAYER.velocity.y > PLAYER.jump_vel / 2:
		climb_state.is_climb_jump = false
		PLAYER.velocity.y = PLAYER.jump_vel / 2
		Transitioned.emit(self, "Fall")
	if PLAYER.can_dash():
		Transitioned.emit(self, "Dash")
	if climb.can_climb():
		Transitioned.emit(self, "Climb")


func Handle_Input(_event: InputEvent) -> void:
	if _event.is_action_pressed("free_view_mode"):
		Transitioned.emit(self, "FreeViewMode")
