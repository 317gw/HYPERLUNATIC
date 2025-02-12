class_name Climb
extends Node3D
# By 317GW 2024 8 23?

@export var auto_climb:bool = true
@export var climb_on_dash_jump:bool = false
@export var climb_on_rigidbody3d:bool = false
@export var down_to_floor_ray_edge_size:float = 0.05
@export var player_to_wall:float = 0.4
@export var ray_target_position: Vector3 = Vector3(0, 0, -1)
@export var gap_check_high:float = 0.05
@export var gap_limit:float = 0.07
@export_range(0.0, 180.0, 0.1) var gap_max_angle:float = 30.0


var hit_wall: bool = false
var hit_air: bool = false
var hit_down_to_floor: bool = false
#var can_climb_edge: bool = false
var edge_pos_lerp: Vector3 = Vector3(0,0,0)
var edge_global_position: Vector3 = Vector3(0,0,0)
var target_player_global_position: Vector3 = Vector3(0,0,0)
var target_pos_last_frame: Vector3 = Vector3(0,0,0)
var wall_ray_pos_original: Vector3 = Vector3(0,0,0)
var air_ray_pos_original: Vector3 = Vector3(0,0,0)
var gap_width: float = -1

var climb_object: Object = null
var climb_object_last: Object = null
var climb_object_to_rays: Vector3 = Vector3(0,0,0)
var climb_object_to_player: Vector3 = Vector3(0,0,0)
var climb_object_pos_last: Vector3 = Vector3(0,0,0)
var climb_object_velocity: Vector3 = Vector3(0,0,0)

@onready var player: HL.Player = $".."
@onready var head: Node3D = $"../Head"
@onready var hand: GrabFuction = $"../Head/Hand"
@onready var camera_3d: HL.Camera = $"../Head/Camera3D"

# 判定
@onready var strike_head_area: Area3D = $StrikeHeadArea
@onready var clip_cast: ShapeCast3D = $ClipCast
@onready var edge_cast: ShapeCast3D = $EdgeCast
@onready var wall_ray: RayCast3D = $WallRay
@onready var air_ray: RayCast3D = $AirRay
@onready var down_to_floor_ray: RayCast3D = $AirRay/DownToFloorRay
@onready var chest_ray: RayCast3D = $"ChestRay"
# 计时
@onready var climb_timer: Timer = $"../Timers/ClimbTimer"


func _ready() -> void:
	init_position()
	wall_ray_pos_original = wall_ray.position
	air_ray_pos_original = air_ray.position
	#entered_body.clear()


func _physics_process(_delta: float) -> void:
	if clip_cast.position != Vector3(0, 0.85, 0):
		clip_cast.position = Vector3(0, 0.85, 0)  # Vector3(0, 0.85, 0) 是玩家碰撞几何中心
	if player.movement_state_machine.current_state.name == "Climb":
		mesh_3.visible = true
	elif mesh_1.visible == true or mesh_2.visible == true or mesh_3.visible == true:
		mesh_1.visible = false
		mesh_2.visible = false
		mesh_3.visible = false


# 初始化位置
func init_position() -> void:
	wall_ray.target_position = ray_target_position
	air_ray.target_position = ray_target_position
	down_to_floor_ray.position = ray_target_position


@onready var mesh_1: MeshInstance3D = $Mesh1
@onready var mesh_2: MeshInstance3D = $Mesh2
@onready var mesh_3: MeshInstance3D = $Mesh3
func have_gap() -> bool:
	if not hit_down_to_floor:
		gap_width = -1
		return false
	if hit_air:
		gap_width = (air_ray.get_collision_point() - down_to_floor_ray.get_collision_normal() * gap_check_high).distance_to(edge_global_position)
		#prints(gap_width)
		#if gap_width > gap_limit:
			#print("???")
		return gap_width > gap_limit

	#prints("hit_air hit_down_to_floor", hit_down_to_floor)
	gap_width = -1
	return true


func can_climb_edge() -> bool:
	return hit_wall and hit_down_to_floor and climb_timer.is_stopped() and down_to_floor_ray.get_collision_normal().angle_to(Vector3.UP) < deg_to_rad(gap_max_angle)


func can_climb() -> bool:
	#if player.velocity.length() < player.speed_max:
	#print("   ")
	if Input.is_action_pressed("slow"):
		return false
	
	if climb_timer.is_stopped() and can_climb_input() and not hand.picked_up:
		#print("1")
		update_raycasts() # false

		if climb_object is RigidBody3D and not climb_on_rigidbody3d:
			return false

		#update_edge_global_position()
		if can_climb_edge() and have_gap():
			#print("2")
			update_position()
			update_climb_object()
			return not is_clipping()
	#print("3")
	return false


func can_climb_input() -> bool:
	if auto_climb:
		return true
	return Input.is_action_pressed("climb")


func update_raycasts() -> void: # is_edge_pos_lerp:bool = true
	# 一次墙检测
	wall_ray.force_raycast_update()
	hit_wall = wall_ray.is_colliding()
	# 镂空杆子检测？
	if not hit_wall and edge_global_position:
		wall_ray.global_position.y = edge_global_position.y - gap_check_high

	# 向下边沿检测
	if hit_wall:
		down_to_floor_ray.global_position.x = wall_ray.get_collision_point().x
		down_to_floor_ray.global_position.z = wall_ray.get_collision_point().z
		down_to_floor_ray.position.z -= down_to_floor_ray_edge_size
		down_to_floor_ray.force_update_transform()
	down_to_floor_ray.force_raycast_update()
	hit_down_to_floor = down_to_floor_ray.is_colliding()
	climb_object = down_to_floor_ray.get_collider()

	if climb_object and climb_object != climb_object_last:
		climb_object_pos_last = climb_object.global_position

	# var climb_object_collision_point = Vector3.ZERO
	# if climb_object:
		# climb_object_collision_point = climb_object.get_collision_point()

	# 二次墙检测
	if hit_down_to_floor:
		wall_ray.global_position.y = down_to_floor_ray.get_collision_point().y - gap_check_high
		wall_ray.force_update_transform()
		wall_ray.force_raycast_update()
		hit_wall = wall_ray.is_colliding()
	#else:
		#wall_ray.position = wall_ray_pos_original

	# 边沿上检测 用于测算边沿宽度
	if hit_down_to_floor:
		air_ray.global_position.y = down_to_floor_ray.get_collision_point().y + gap_check_high
		air_ray.force_update_transform()
	air_ray.force_raycast_update()
	hit_air = air_ray.is_colliding()
	if hit_down_to_floor:
		air_ray.position = air_ray_pos_original


	# 显示参考球
	if hit_air:
		mesh_1.global_position = air_ray.get_collision_point()
		mesh_2.global_position = (air_ray.get_collision_point() - down_to_floor_ray.get_collision_normal() * gap_check_high)
		if player.movement_state_machine.current_state.name == "Climb":
			mesh_1.visible = true
			mesh_2.visible = true
	mesh_3.global_position = edge_global_position

	edge_global_position.x = wall_ray.get_collision_point().x
	edge_global_position.z = wall_ray.get_collision_point().z
	edge_global_position.y = down_to_floor_ray.get_collision_point().y

	edge_cast.global_position = edge_global_position
	edge_cast.force_update_transform()
	edge_cast.force_shapecast_update()

	wall_ray.position = wall_ray_pos_original



func update_position(check_distance: bool = false) -> void:
	target_pos_last_frame = target_player_global_position
	chest_ray.force_raycast_update()

	if chest_ray.is_colliding():
		if (player.global_position*Vector3(1, 0, 1)).distance_to(chest_ray.get_collision_point()*Vector3(1, 0, 1)) < (player.global_position*Vector3(1, 0, 1)).distance_to(wall_ray.get_collision_point()*Vector3(1, 0, 1)):
			target_player_global_position = chest_ray.get_collision_point()
		else:
			target_player_global_position = wall_ray.get_collision_point()
	else:
		target_player_global_position = wall_ray.get_collision_point()

	target_player_global_position += wall_ray.get_collision_normal() * player_to_wall
	target_player_global_position.y = edge_global_position.y - head.position.y
	if target_player_global_position.distance_to(target_pos_last_frame) > -ray_target_position.z*0.5 and check_distance:
		target_player_global_position = target_pos_last_frame


func is_hit_from_inside(ray: RayCast3D) -> bool: # 没用
	var bf = ray.hit_from_inside
	ray.hit_from_inside = true
	ray.force_update_transform()
	ray.force_raycast_update()
	ray.hit_from_inside = bf
	return ray.get_collision_normal() == Vector3.ZERO


func is_clipping() -> bool:
	for i in range(3):
		#prints("is_clipping", i)
		clip_cast.global_position = target_player_global_position + Vector3(0, 0.85, 0)
		clip_cast.force_update_transform()
		clip_cast.force_shapecast_update()
		if clip_cast.is_colliding():
			target_player_global_position += wall_ray.get_collision_normal() * i * 0.1
		else:
			#prints("is_clipping false", i)
			return false
	target_player_global_position = target_pos_last_frame
	#prints("is_clipping true")
	return true


func align_z_with_normal(normal: Vector3, check_angle: bool = false) -> void:
	var z_axis = self.global_transform.basis.z
	var angle = z_axis.angle_to(normal)
	var axis = z_axis.cross(normal).normalized()

	# 如果z_axis和normal已经平行或反平行，不需要旋转
	if axis.length_squared() == 0 or (check_angle and abs(angle) > deg_to_rad(50)):
		return


	var rotation_matrix = Basis(axis, angle)
	self.global_transform.basis *= rotation_matrix
	self.rotation.x = 0
	self.rotation.z = 0


func update_climb_object() -> void:
	if climb_object and climb_object != climb_object_last:
		climb_object_to_rays = target_player_global_position - climb_object.global_position
	if climb_object:
		climb_object_pos_last = climb_object.global_position
		#climb_object_to_player =
	climb_object_last = climb_object
