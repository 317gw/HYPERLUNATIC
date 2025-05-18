class_name PlayerJump
extends State

var is_wheel_jump: bool = false

@onready var PLAYER: HL.Player = $"../.."
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
	PLAYER.swimming(_delta)
	PLAYER.apply_gravity(-PLAYER.gravity_jump, _delta)
	if PLAYER.not_air_speed_clamp_timer.time_left == 0:
		PLAYER.air_speed_clamp(_delta)
	PLAYER.jumping_up()

	PLAYER.jump_debug()
	PLAYER.apply_velocity()


	#if PLAYER.is_swimming():
		#Transitioned.emit(self, "Swim")
		#return
	#else:
	if PLAYER.vel_up <= 0: # 如果玩家正在正在下落
		Transitioned.emit(self, "Fall")
		return
	# 如果玩家松开了跳跃键
	if not Input.is_action_pressed("jump") and PLAYER.vel_up > PLAYER.jump_vel / 2 and not is_wheel_jump:
		PLAYER.vel_up = PLAYER.jump_vel / 2
		PLAYER.apply_velocity(PLAYER.ApplyVelocityMode.DO_NOTHING)
		Transitioned.emit(self, "Fall")
		return
	if PLAYER.can_dash():
		Transitioned.emit(self, "Dash")
		return
	if climb.can_climb():
		Transitioned.emit(self, "Climb")
		return


func Handle_Input(_event: InputEvent) -> void:
	if _event.is_action_pressed("free_view_mode"):
		Transitioned.emit(self, "FreeViewMode")
		return
