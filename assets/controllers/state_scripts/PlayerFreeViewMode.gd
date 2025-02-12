class_name FreeViewMode
extends State

# 飞
@export var free_view_speed_sensitivity: float = 0.5
var free_view_speed_scale: float = 2

@onready var PLAYER: HL.Player = $"../.."
@onready var camera: HL.Camera = $"../../Head/Camera3D"
#@onready var player_rigid_body: PlayerRigidBody3D = $"../../PlayerRigidBody"


func Enter():
	#player_rigid_body.process_mode = Node.PROCESS_MODE_DISABLED
	free_view_speed_scale = 2


#func Exit():
	#player_rigid_body.global_position = PLAYER.global_position
	#player_rigid_body.process_mode = Node.PROCESS_MODE_PAUSABLE


func Physics_Update(_delta: float) -> void:
	free_view_move(_delta)


func Handle_Input(_event: InputEvent) -> void:
	if _event.is_action_pressed("free_view_mode"):
		Transitioned.emit(self, "Fall")
		return
	
	if _event.is_action_pressed("mouse_wheel_up"):
		free_view_speed_scale += free_view_speed_sensitivity
	if _event.is_action_pressed("mouse_wheel_down"):
		free_view_speed_scale -= free_view_speed_sensitivity
	free_view_speed_scale = clampf(free_view_speed_scale, 0.5, 10)



func free_view_move(delta: float) -> void:
	if not is_instance_valid(camera):
		print("Camera is not valid.")
		return
	var face_dir = camera._face_dir * -PLAYER.input_dir.y + camera._face_dir.cross(Vector3.UP) * PLAYER.input_dir.x
	var up_down: Vector3 = Vector3(0, PLAYER.input_up_down, 0)
	var speed: float = PLAYER.speed_max if Input.is_action_pressed("shift") else PLAYER.speed_normal
	PLAYER.velocity = (face_dir + up_down).normalized() * speed * free_view_speed_scale
	PLAYER.global_position += PLAYER.velocity * delta
