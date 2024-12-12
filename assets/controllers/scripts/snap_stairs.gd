class_name SnapStairs
extends Node3D
## ↓ https://github.com/majikayogames/SimpleFPSController
# 坡面太陡&楼梯检测
# 丝滑楼梯
# 楼梯检测

@export var max_step_height: float = 0.6
@export var step_length: float = 0.5

var snapped_to_stairs_last_several_frame:Array = []
var snapped_to_stairs_last_several_frame_max: int = 20
var translate_y: float
var snapped_to_stairs_last_frame := false
var last_frame_was_on_floor = -INF

@onready var player: HL.Controller.Player = $".."
@onready var camera: HL.Controller.Camera = $"../Head/Camera3D"
@onready var stairs_ahead_ray: RayCast3D = $StairsAheadRay
@onready var stairs_below_ray: RayCast3D = $StairsBelowRay
@onready var stairs_below_edge_ray: RayCast3D = $StairsBelowEdgeRay
@onready var stair_ray_2: RayCast3D = $StairRay2
@onready var stair_ray_3: RayCast3D = $StairRay3


func _ready() -> void:
	stairs_ahead_ray.target_position.y = -(max_step_height+0.05)
	stairs_below_ray.target_position.y = -(max_step_height-0.05)


func _physics_process(_delta: float) -> void:
	if snapped_to_stairs_last_several_frame.size() > snapped_to_stairs_last_several_frame_max:
		snapped_to_stairs_last_several_frame.remove_at(0)
		#print(snapped_to_stairs_last_several_frame)


func is_surface_too_steep(surface_normal: Vector3, angle: float) -> bool:
	return surface_normal.angle_to(Vector3.UP) > angle


func snapped_to_stairs_last_several_frame_count() -> float:
	var count: int = 0
	for i in snapped_to_stairs_last_several_frame:
		if i:
			count += 1
	return count


func snap_down_to_stairs_check(check_stairs_second_ray: bool = false) -> void:
	var did_snap := false
	var was_on_floor_last_frame = Engine.get_physics_frames() == last_frame_was_on_floor
	stairs_below_ray.force_raycast_update()
	var floor_below: bool = stairs_below_ray.is_colliding() and not is_surface_too_steep(stairs_below_ray.get_collision_normal(), player.floor_max_angle/3)
	# ↓ if Fall
	if not player.is_on_floor() and player.velocity.y <= 0 and (was_on_floor_last_frame or snapped_to_stairs_last_frame) and floor_below:
		var body_test_result = KinematicCollision3D.new()
		#print("snap_down +1+")
		if player.test_move(player.global_transform, Vector3(0,-max_step_height,0), body_test_result):
			translate_y = lerp(translate_y, body_test_result.get_travel().y, 0.5)

			# 是否启用射线检测，过去是否在台阶上
			if check_stairs_second_ray and not (snapped_to_stairs_last_several_frame_count() > 3):
				#print(not snapped_to_stairs_last_several_frame.all(func(i): return i))
				var vel2d_v3 = player.velocity*Vector3(1,0,1) + player.input_direction
				stair_ray_2.global_position = body_test_result.get_position() + vel2d_v3.normalized() * step_length
				stair_ray_3.global_position = body_test_result.get_position() + vel2d_v3.normalized() * step_length * 2
				stair_ray_2.force_raycast_update()
				stair_ray_3.force_raycast_update()

				if stair_ray_2.is_colliding() and stair_ray_3.is_colliding():
					var y_result_to_stair2 = abs(stair_ray_2.get_collision_point().y - body_test_result.get_position().y)
					var y_stair2_to_3 = abs(stair_ray_2.get_collision_point().y - stair_ray_3.get_collision_point().y)
					var is_continuous_stair = y_stair2_to_3 > 0.1

					#  = abs(stair_ray_2.get_collision_point().y - body_test_result.get_position().y)
					#prints(y_result_to_stair2, y_stair2_to_3, is_continuous_stair)

					#translate_y = lerp(translate_y, translate_y * (1 - y_result_to_stair2/max_step_height), 0.5)
					# lerp(translate_y, translate_y * (1 - dd/max_step_height), 0.5)
					# 如果台阶不连续，则不进行snap
					if not is_continuous_stair:
						return

			camera.slide_camera_smooth_back_to_origin_y_only = true
			camera.save_camera_pos_for_smoothing()
			player.global_position.y += translate_y
			# + input_direction*air_speed*get_physics_process_delta_time()
			player.apply_floor_snap()
			did_snap = true
			#print("did_snap = true")
	snapped_to_stairs_last_frame = did_snap
	snapped_to_stairs_last_several_frame.append(snapped_to_stairs_last_frame)




func snap_up_stairs_check(delta: float) -> bool:
	if not player.is_on_floor() and not snapped_to_stairs_last_frame:
		return false

	var vel2d_v3 = player.velocity*Vector3(1,0,1) + player.input_direction
	if vel2d_v3.length() == 0:
		return false

	var expected_move_motion = vel2d_v3 * delta
	var step_pos_with_clearance = player.global_transform.translated(expected_move_motion + Vector3(0, max_step_height*2, 0))
	var down_check_result = KinematicCollision3D.new()
	var self_test_move = player.test_move(step_pos_with_clearance, Vector3(0, -max_step_height*2.1, 0), down_check_result)
	if down_check_result.get_collision_count() == 0:
		return false

	var collider = down_check_result.get_collider()
	if not (self_test_move and (collider is StaticBody3D or collider is CSGShape3D) ):
		return false

	var step_height = (step_pos_with_clearance.origin - player.global_position + down_check_result.get_travel()).y
	if step_height > max_step_height or step_height <= 0.01 or (down_check_result.get_position() - player.global_position).y > max_step_height:
		return false

	stairs_ahead_ray.global_position = down_check_result.get_position() + Vector3(0,max_step_height,0) + expected_move_motion.normalized() * 0.1
	stairs_ahead_ray.force_raycast_update()
	if stairs_ahead_ray.is_colliding() and not is_surface_too_steep(stairs_ahead_ray.get_collision_normal(), player.floor_max_angle/3):
		camera.slide_camera_smooth_back_to_origin_y_only = false
		camera.save_camera_pos_for_smoothing()
		player.global_position = step_pos_with_clearance.origin + down_check_result.get_travel() # ***
		player.apply_floor_snap()
		snapped_to_stairs_last_frame = true
		return true

	return false
