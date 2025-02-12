class_name StandOnHead
extends Node3D

var stand_body_now: Node3D = null
var stand_body_now_last: Node3D = null
var stand_body_now_switch: bool = false
var standed_bodys: Array = []

var player_platform_on_leave_original: CharacterBody3D.PlatformOnLeave

@onready var player: HL.Player = $".."
@onready var stand_body: AnimatableBody3D = $StandBody
@onready var stand_collision: CollisionShape3D = $StandBody/StandCollision
@onready var stand_area: Area3D = $StandArea
@onready var ray_cast_3d: RayCast3D = $RayCast3D


func _ready() -> void:
	player_platform_on_leave_original = player.platform_on_leave


func _physics_process(_delta: float) -> void:
	if standed_bodys.size() == 0:
		no_stand_body()
		return
	stand_body.process_mode = Node.PROCESS_MODE_PAUSABLE
	ray_cast_3d.process_mode = Node.PROCESS_MODE_PAUSABLE

	# 筛选距离player最近的body
	var state = player.movement_state_machine.current_state.name
	if not (state == "Idle" or state == "Run") and player.velocity.normalized().dot(Vector3.DOWN) > 0.1:
		find_nearest_stand_body()
	if stand_body_now == null:
		no_stand_body()
		return

	# 判断stand_body_now_switch
	if not stand_body_now_last == stand_body_now:
		stand_body_now_switch = true
	stand_body_now_last = stand_body_now

	# 设置CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	if stand_body_now_switch:
		player.platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
		stand_body_now_switch = false
	else:
		player.platform_on_leave = player_platform_on_leave_original

	# 通过射线检测设置碰撞位置
	ray_cast_3d.global_position = stand_body_now.global_position
	ray_cast_3d.global_position.y = player.global_position.y
	ray_cast_3d.global_position.y = max(ray_cast_3d.global_position.y, stand_body_now.global_position.y + 0.4)
	ray_cast_3d.force_update_transform()
	ray_cast_3d.force_raycast_update()
	if not ray_cast_3d.is_colliding():
		print("not ray_cast_3d.is_colliding")
	var trgt_pos: Vector3 = ray_cast_3d.get_collision_point() - Vector3(0, stand_collision.shape.height, 0) * 0.3
	stand_body.global_position = trgt_pos


func no_stand_body() -> void:
	stand_body.process_mode = Node.PROCESS_MODE_DISABLED
	ray_cast_3d.process_mode = Node.PROCESS_MODE_DISABLED


func find_nearest_stand_body() -> void:
	stand_body_now = standed_bodys[0]
	for body in standed_bodys:
		if body.global_position.distance_to(player.global_position) < stand_body_now.global_position.distance_to(player.global_position):
			stand_body_now = body


func _on_stand_area_body_entered(body: Node3D) -> void:
	if not body in standed_bodys:
		standed_bodys.append(body)


func _on_stand_area_body_exited(body: Node3D) -> void:
	if body in standed_bodys:
		standed_bodys.erase(body)
		if stand_body_now == body:
			stand_body_now = null


func _on_stand_area_area_entered(area: Area3D) -> void:
	if not area in standed_bodys:
		standed_bodys.append(area)


func _on_stand_area_area_exited(area: Area3D) -> void:
	if area in standed_bodys:
		standed_bodys.erase(area)
		if stand_body_now == area:
			stand_body_now = null
