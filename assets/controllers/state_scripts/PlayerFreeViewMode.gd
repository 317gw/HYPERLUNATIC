class_name FreeViewMode
extends State

@onready var PLAYER: HL.Controller.Player = $"../.."
@onready var player_rigid_body: PlayerRigidBody3D = $"../../PlayerRigidBody"
#@onready var camera: HL.Controller.Camera = $"../../Head/Camera3D"
#@onready var snap_stairs: SnapStairs = $"../../SnapStairs"


func Enter():
	player_rigid_body.process_mode = Node.PROCESS_MODE_DISABLED


func Exit():
	player_rigid_body.global_position = PLAYER.global_position
	player_rigid_body.process_mode = Node.PROCESS_MODE_PAUSABLE


func Physics_Update(_delta: float) -> void:
	PLAYER.free_view_move(_delta)


func Handle_Input(_event: InputEvent) -> void:
	if _event.is_action_pressed("free_view_mode"):
		Transitioned.emit(self, "Fall")
