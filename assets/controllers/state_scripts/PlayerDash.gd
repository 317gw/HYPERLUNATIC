class_name PlayerDash
extends State

signal dash_started

var is_vertical_dash: bool = false # 没用
var dash_type = null
enum Dash_Type {DASH2D, DASH3D}

@onready var PLAYER: HL.Controller.Player = $"../.."


func Enter():
	dash_started.emit()

	if Input.is_action_pressed("jump"):
		dash_type = Dash_Type.DASH3D
		#PLAYER.dash_on_air()
		PLAYER.dash_dir3d = Vector3(0, 1, 0)
		PLAYER.dash_ready()
		is_vertical_dash = false # 没用
		return

	if PLAYER.dir2d and not Input.is_action_pressed("move_forward"):
		dash_type = Dash_Type.DASH2D
		PLAYER.dash_on_floor()
		# print("Dash2D")
	else:
		dash_type = Dash_Type.DASH3D
		PLAYER.dash_on_air()
		# print("Dash3D")
	PLAYER.dash_ready()


func Exit():
	pass


func Physics_Update(_delta: float) -> void:
	match dash_type:
		Dash_Type.DASH2D:
			PLAYER.dashing_on_floor()
		Dash_Type.DASH3D:
			PLAYER.dashing_on_air()
	
	PLAYER.dash_on_wall(_delta)
	PLAYER.dash_velocity_clamp()
	#PLAYER.reset_dash_number()

	PLAYER.apply_velocity()

	if PLAYER.dash_timer.time_left == 0:
		if PLAYER.is_on_floor(): # 地面
			if PLAYER.dir2d:
				Transitioned.emit(self, "Run")
			else:
				Transitioned.emit(self, "Idle")
		else:
			Transitioned.emit(self, "Fall")
		PLAYER.dash_out()

	if PLAYER.can_dash_jump():
		Transitioned.emit(self, "DashJump")


func Handle_Input(_event: InputEvent) -> void:
	if _event.is_action_pressed("free_view_mode"):
		Transitioned.emit(self, "FreeViewMode")


func vertical_dash() -> void: # 没用
	is_vertical_dash = true
