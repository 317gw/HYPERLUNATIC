class_name SnapStairs
extends Node3D
## Stair and steep surface detection/snapping for FPS character controller
## 坡面太陡&楼梯检测, 丝滑楼梯, 楼梯检测
## ↓ https://github.com/majikayogames/SimpleFPSController

@export var max_step_height: float = 0.6
@export var step_search_distance: float = 0.5
@export var max_step_angle: float = 15 #degrees

var was_snapped_last_frame : bool = false
var last_on_floor_frame : float = -INF
var _stair_snap_history: Array = []
var _max_snap_history_frames: int = 20
var _current_snap_offset: float # translate_y

@onready var _player: HL.Player = $".."
@onready var _camera: HL.Camera = $"../Head/Camera3D"
@onready var stairs_ahead_ray: RayCast3D = $StairsAheadRay
@onready var stairs_below_ray: RayCast3D = $StairsBelowRay
@onready var stairs_below_edge_ray: RayCast3D = $StairsBelowEdgeRay
@onready var stair_ray_2: RayCast3D = $StairRay2
@onready var stair_ray_3: RayCast3D = $StairRay3


func _ready() -> void:
	stairs_ahead_ray.target_position.y = -(max_step_height+0.05)
	stairs_below_ray.target_position.y = -(max_step_height-0.05)


func _physics_process(_delta: float) -> void:
	if _stair_snap_history.size() > _max_snap_history_frames:
		_stair_snap_history.remove_at(0)
		#print(_stair_snap_history)


func is_surface_too_steep(surface_normal: Vector3, max_allowed_angle: float) -> bool:
	return surface_normal.angle_to(_player.up_direction) > deg_to_rad(max_allowed_angle)


func _get_snap_history_count() -> float:
	var count: int = 0
	for i in _stair_snap_history:
		if i:
			count += 1
	return count


func snap_down_to_stairs_check(check_stairs_second_ray: bool = false) -> void:
	var did_snap := false
	var was_on_floor_last_frame = Engine.get_physics_frames() == last_on_floor_frame

	stairs_below_ray.force_raycast_update()
	var floor_below: bool = stairs_below_ray.is_colliding() and not is_surface_too_steep(stairs_below_ray.get_collision_normal(), max_step_angle)

	# ↓ if Fall , should snap downward
	if not _player.is_on_floor() and _player.velocity.y <= 0 and (was_on_floor_last_frame or was_snapped_last_frame ) and floor_below:
		var body_test_result = KinematicCollision3D.new()
		#print("snap_down +1+")
		if _player.test_move(_player.global_transform, Vector3(0,-max_step_height,0), body_test_result):
			_current_snap_offset = lerp(_current_snap_offset, body_test_result.get_travel().y, 0.5)

			# 是否启用射线检测，过去是否在台阶上
			if check_stairs_second_ray and not (_get_snap_history_count() > 3):
				#print(not _stair_snap_history.all(func(i): return i))
				var vel2d_v3 = _player.velocity*Vector3(1,0,1) + _player.input_direction
				stair_ray_2.global_position = body_test_result.get_position() + vel2d_v3.normalized() * step_search_distance
				stair_ray_3.global_position = body_test_result.get_position() + vel2d_v3.normalized() * step_search_distance * 2
				stair_ray_2.force_raycast_update()
				stair_ray_3.force_raycast_update()

				if stair_ray_2.is_colliding() and stair_ray_3.is_colliding():
					var y_result_to_stair2 = abs(stair_ray_2.get_collision_point().y - body_test_result.get_position().y)
					var y_stair2_to_3 = abs(stair_ray_2.get_collision_point().y - stair_ray_3.get_collision_point().y)
					var is_continuous_stair = y_stair2_to_3 > 0.1

					#  = abs(stair_ray_2.get_collision_point().y - body_test_result.get_position().y)
					#prints(y_result_to_stair2, y_stair2_to_3, is_continuous_stair)

					#_current_snap_offset = lerp(_current_snap_offset, _current_snap_offset * (1 - y_result_to_stair2/max_step_height), 0.5)
					# lerp(_current_snap_offset, _current_snap_offset * (1 - dd/max_step_height), 0.5)
					# 如果台阶不连续，则不进行snap
					if not is_continuous_stair:
						return

			_camera.slide_camera_smooth_back_to_origin_y_only = true
			_camera.save_camera_position()
			_player.global_position.y += _current_snap_offset
			# + input_direction*air_speed*get_physics_process_delta_time()
			_player.apply_floor_snap()
			did_snap = true
			#print("did_snap = true")
	was_snapped_last_frame  = did_snap
	_stair_snap_history.append(was_snapped_last_frame )




func snap_up_stairs_check(delta: float) -> bool:
	if not _player.is_on_floor() and not was_snapped_last_frame :
		return false

	var vel2d_v3 = _player.velocity*Vector3(1,0,1) + _player.input_direction
	if vel2d_v3.length() == 0:
		return false

	var expected_move_motion = vel2d_v3 * delta
	var step_pos_with_clearance = _player.global_transform.translated(expected_move_motion + Vector3(0, max_step_height*2, 0))
	var down_check_result = KinematicCollision3D.new()
	var self_test_move = _player.test_move(step_pos_with_clearance, Vector3(0, -max_step_height*2.1, 0), down_check_result)
	if down_check_result.get_collision_count() == 0:
		return false

	var collider = down_check_result.get_collider()
	if not (self_test_move and (collider is StaticBody3D or collider is CSGShape3D) ):
		return false

	var step_height = (step_pos_with_clearance.origin - _player.global_position + down_check_result.get_travel()).y
	if step_height > max_step_height or step_height <= 0.01 or (down_check_result.get_position() - _player.global_position).y > max_step_height:
		return false

	stairs_ahead_ray.global_position = down_check_result.get_position() + Vector3(0,max_step_height,0) + expected_move_motion.normalized() * 0.1
	stairs_ahead_ray.force_raycast_update()
	if stairs_ahead_ray.is_colliding() and not is_surface_too_steep(stairs_ahead_ray.get_collision_normal(), max_step_angle):
		_camera.slide_camera_smooth_back_to_origin_y_only = false
		_camera.save_camera_position()
		_player.global_position = step_pos_with_clearance.origin + down_check_result.get_travel() # ***
		_player.apply_floor_snap()
		was_snapped_last_frame  = true
		return true

	return false
