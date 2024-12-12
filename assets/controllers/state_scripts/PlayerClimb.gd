class_name PlayerClimb
extends State

var player_pos_temp: Vector3
var player_target_pos: Vector3
var climb_target_pos: Vector3
var target_normal: Vector3
var is_climb_jump: bool = false

@onready var PLAYER: HL.Controller.Player = $"../.."
@onready var climb: Climb = $"../../Climb"
@onready var climb_timer: Timer = $"../../Timers/ClimbTimer"


func Enter() -> void:
	target_normal = climb.wall_ray.get_collision_normal()
	climb.align_z_with_normal(target_normal)

	# 初始化攀爬位置
	climb_target_pos = climb.target_player_global_position
	climb_target_pos += PLAYER.velocity.normalized() * clamp(PLAYER.velocity.length(), 0.0, PLAYER.speed_max) * get_physics_process_delta_time()
	player_target_pos = PLAYER.global_position

	# 应用一次速度
	PLAYER.velocity = PLAYER.velocity * get_physics_process_delta_time()
	PLAYER.apply_velocity()


func Exit() -> void:
	target_normal = PLAYER.transform.basis.z
	climb.wall_ray.position = climb.wall_ray_pos_original
	#climb.climb_object_velocity = Vector3.ZERO
	#climb.climb_object_last = null
	climb.init_position()
	if climb.rotation != Vector3.ZERO:
		climb.rotation = Vector3.ZERO
	climb_timer.start()


func Physics_Update(_delta: float) -> void:
	# 边缘检测
	climb.update_raycasts()
	if climb.climb_object:
		climb.climb_object_velocity = (climb.climb_object.global_position - climb.climb_object_pos_last)/ _delta
		climb.climb_object_pos_last = climb.climb_object.global_position
	if climb.have_gap() and climb.can_climb_edge:
		climb.update_position(true)
		climb.update_climb_object()
		climb.is_clipping()


	#if not climb.hit_down_to_floor and not climb.hit_wall:
		#climb.global_position = climb.climb_object.global_position + climb.climb_object_to_rays
	if not climb.edge_cast.is_colliding() and not climb.hit_down_to_floor and not climb.hit_wall:
		Transitioned.emit(self, "Fall")

	target_normal = target_normal.lerp(climb.wall_ray.get_collision_normal(), 0.1)
	climb.align_z_with_normal(target_normal, true)

	# 下边是移动
	var lerp_w = player_target_pos.distance_to(climb.target_player_global_position)
	lerp_w = remap(lerp_w, 0.0, abs(climb.ray_target_position.z), 0.3, 0.01)
	climb_target_pos = climb_target_pos.lerp(climb.target_player_global_position, 0.3)
	player_target_pos = player_target_pos.lerp(climb_target_pos, lerp_w)

	PLAYER.movement_air(_delta)

	# 判断方向 不让怼墙里  在改进碰撞不会鬼畜和进入之后就没用了  影响操作
	#var dot: float = 0.0
	#if climb.chest_ray.is_colliding():
		#dot = PLAYER.velocity.normalized().dot(climb.chest_ray.get_collision_normal())
	#else:
		#dot = PLAYER.velocity.normalized().dot(climb.wall_ray.get_collision_normal())
	#dot = dot ** 3
	#dot = smoothstep(0, -1, dot)
	#PLAYER.vel2d *= (1 - abs(dot))

	PLAYER.vel2d = PLAYER.vel2d.normalized() * clamp(PLAYER.vel2d.length(), 0.0, PLAYER.speed_normal)
	PLAYER.apply_velocity(false)



	# 可能很没用的 靠近边缘极限 的速度控制
	# 动那个↓ 0.8 是超出的距离的1-0.8比例
	var y = smoothstep(climb.gap_limit*0.8, climb.gap_limit, climb.gap_width)
	y = remap(y, 0.0, 1.0, 0.1, 1)
	if climb.gap_width < 0:
		y = 1
	var velocity: Vector3 = PLAYER.velocity * _delta * y
	if climb.climb_object and climb.climb_object_velocity.length() < 40.0:
		velocity = (PLAYER.velocity + climb.climb_object_velocity*1.9) * _delta * y

	player_target_pos += velocity
	#print(climb.climb_object_velocity)
	# 动
	if PLAYER.move_and_collide(velocity):
		player_target_pos = lerp(player_target_pos, PLAYER.global_position, 0.6)
	if PLAYER.global_position.distance_to(player_target_pos) < -climb.ray_target_position.z*0.5:
		PLAYER.global_position = player_target_pos

	PLAYER.velocity = PLAYER.velocity.lerp(Vector3.ZERO, 0.07)


func Handle_Input(_event: InputEvent) -> void:
	if _event.is_action_pressed("free_view_mode"):
		Transitioned.emit(self, "FreeViewMode")
	if _event.is_action_pressed("jump") or _event.is_action_pressed("mouse_wheel_jump"):
		is_climb_jump = true
		Transitioned.emit(self, "Jump")
	if _event.is_action_pressed("slow"):
		Transitioned.emit(self, "Fall")
