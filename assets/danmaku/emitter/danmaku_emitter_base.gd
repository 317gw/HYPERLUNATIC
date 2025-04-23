#class_name DanmakuEmitterBase
extends Node3D
#danmaku_emitter_base

"""
Classic 使用最普通的方法实现，性能差，灵活性高
MultiMeshInstance3D 这个复用模型，性能好，重复度高
2DLayerSimulate 用2D节点模拟玩家碰撞，
"""

const FRAME_RATE: float = 60.0 # 每秒发射周期数

enum ResetMode {
	TIME,
	COUNT,
	}

enum ResetDelayMode {
	AFTER, ## 后
	BEFORE, ## 前
	RESET_COUNT, ## 重置次数 之后
	}

enum CapMode {
	STOP_LAUNCHING,
	DELETE_OLDEST,
	}

enum BulletUpMode {
	UP,
	RANDOM,
	EMITTER,
	}

# 发射器
var Here_is_the_last_start = null
@export_group("Emitter")
@export var bullet_ware: Node3D
@export var emitter_mesh_display: Node3D
@export var emitter_velocity: Vector3 = Vector3.ZERO ## 速度
@export var emitter_acceleration: Vector3 = Vector3.ZERO ## 加速度
@export var emitter_center: Vector3 = Vector3.ZERO ## 发射中心坐标
# 射
@export_subgroup("Fire")
@export var firing: bool = true ## 是否开火,射弹幕
@export var fire_rate: int = 6 ## 发射周期 帧 1秒60帧
@export_range(0, 10, 1) var fire_count: int = 1 ## 发射次数 按照发射周期，同一发射帧的发射次数
@export var interpolate_position: bool = false ## 同一帧发射，发射位置是否插值
@export var start_fire_once: bool = true ## 是否开始时发射一次
# 重置
@export_subgroup("Reset")
@export var only_reset_emitter_class: bool = false ## 只重置本类属性，不重置派生
@export var reset_mode: ResetMode = ResetMode.TIME ## 重置模式
@export var time_for_reset: float = 0 ## 按照时间重置，为则0不启用
@export var count_for_reset: int = 0 ## 按照发射次数重置，为0不启用
@export var reset_delay_mode: ResetDelayMode = ResetDelayMode.AFTER ## 重置延迟模式
@export var reset_delay_time: float = 0 ## 重置延迟时间
# 发射盘
@export_subgroup("Disk", "disk_")
@export_range(0, 100, 1) var disk_count: int = 1 ## 发射盘数量
@export var disk_angle: float = 0.0 ## 发射盘环角度
@export var disk_range: float = 360.0 ## 发射盘范围 角度单位
@export var disk_radius: float = 0.0 ## 发射盘半径
# 发射条
@export_subgroup("Stripe", "stripe_")
@export_range(0, 100, 1) var stripe_count: int = 1 ## 发射条数量
@export var stripe_angle: float = 0.0 ## 发射条角度
@export var stripe_range: float = 360.0 ## 发射条范围 角度单位
@export var stripe_radius: float = 0.0 ## 发射条半径
# 球面均匀分布 Spherical uniform distribution
@export_subgroup("Spherical")
@export var ues_spherical: bool = false ## 使用球面均匀分布
@export_range(1, 1000, 1) var spherical_count: float = 100 ## 球面发射数量
@export var ratio: float = 1.0 ## 公比 黄金分割

# 弹幕
@export_group("Bullet")
# 弹幕样式
@export var bullet_scene: PackedScene = preload("res://assets/danmaku/bullet/bullet_test.tscn") ## 类型 发射的弹幕预制体
@export var ues_multi_mesh_instance_3d: bool = false ## 使用MultiMeshInstance3D
@export var bullet_scene_multi_node: PackedScene = null
@export var bullet_scene_multi_mesh: PackedScene = null
@export var bullet_up_mode: BulletUpMode = BulletUpMode.UP ## 弹幕向上的模式
# 消除处理
@export_subgroup("Life&Delete")
@export var exceeding_the_cap_mode: CapMode = CapMode.STOP_LAUNCHING ## 超出容量处理模式
@export var bullet_collision_enabled: bool = true ## 碰撞消除
@export_range(0, 20000) var bullet_max_node: int = 2000 ## 下属的最大弹幕数量
@export var bullet_lifetime: float = 10.0 ## 生存时间 秒
# 属性
@export_subgroup("Property")
@export var bullet_mass: float = 1.0 ## 质量
@export var bullet_speed: float = 1.0 ## 弹幕速度
@export var bullet_acceleration: Vector3 = Vector3.ZERO ## 弹幕加速度
#@export var bullet_rotation: Vector3 = Vector3.ZERO ## 弹幕旋转
@export var bullet_scale_multi: float = 1.0 ## 缩放倍率
@export var bullet_scale: Vector3 = Vector3.ONE ## 缩放
# 特效
@export_subgroup("Effect")
@export_color_no_alpha var bullet_color1: Color = Color.WHITE ## 颜色
@export_color_no_alpha var bullet_color2: Color = Color(Color.WHITE, 0.5) ## 颜色
@export var bullet_blend_mode: int = 0 ## 混合模式
@export var spawn_effect: PackedScene = null ## 生成特效
@export var destroy_effect: PackedScene = null ## 消除特效
@export var trail_effect: PackedScene = null ## 拖影特效

# @export var  ## 忽略……
@export_group("DebugDisplay")
@export var disk_debug_display: bool = true ## 显示发射盘
@export var stripe_debug_display: bool = true ## 显示发射条
@export var display_radius: float = 2.0 ## Debug显示半径
@export var delete_on_game_start: bool = false ## 游戏开始时删除DebugDisplay


# 其他全局变量或属性...
var is_first_fire: bool = true ## 是否是第一帧
var direction_vector: Vector3 ## 发射器朝向 方向向量
var bullets: Array = [] ## 存储发射的弹幕
var number_of_launches_in_this_frame: int = 0 ## 这一帧内的发射次数
# 计时，计数
var time_since_last_fire: float = 0.0 ## 自上次发射以来的时间
var time_since_last_reset: float = 0.0 ## 自上次重置以来的时间
var count_since_last_reset: int = 0 ## 自上次重置以来的次数
# 发射位置数组
var disk_positions: Array[Vector3] = []
var rotation_matrixs: Array[Transform3D] = []
var curve_points: Array = []
var stripe_fire_positions: Array = []
var stripe_targets: Array = []
# 球形均匀分布数组
var spherical_targets: Array = []
# DebugDisplay
#var debug_display: DebugDisplay
#var use_debug_draw: bool = true

var reset_data: Dictionary
"""
danmaku_break
DANMAKU_BREAK
"""
const DANMAKU_BREAK = preload("res://assets/special_effects/danmaku_break.tscn")
const BULLET_BASE_AREA_3D = preload("res://assets/danmaku/bullet_base_area_3d.tscn")



func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		if ues_spherical:
			_calculate_spherical_uniform_distribution()
		else:
			_calculate_stripe_rotation()
		if emitter_mesh_display:
			emitter_mesh_display.debug_display()

	if not Engine.is_editor_hint():
		_process_in_geme(delta)


# 要覆盖用的
func _emitter_ready() -> void:
	pass
func _bullet_event(_delta: float) -> void:
	pass


func _process_in_geme(delta: float) -> void:
	pass


func _handle_reset(delta: float) -> void:
	# 处理重置
	if reset_mode == ResetMode.TIME and time_for_reset > 0 and time_since_last_reset >= time_for_reset:
		time_since_last_reset = 0.0
		_reset(delta)
	if reset_mode == ResetMode.COUNT and count_for_reset > 0 and count_since_last_reset >= count_for_reset:
		count_since_last_reset = 0
		_reset(delta)


func _reset(delta: float) -> void:
	_load_properties()
	if reset_delay_mode == ResetDelayMode.AFTER and reset_delay_time > 0:
		var t = floor(reset_delay_time / delta) * delta
		time_since_last_fire -= t
		time_since_last_reset -= t


func _in_firing(delta: float) -> void:
	# 处理初次发射
	if is_first_fire:
		is_first_fire = false
		if start_fire_once:
			time_since_last_fire += fire_rate / FRAME_RATE
		if reset_delay_mode == ResetDelayMode.BEFORE and reset_delay_time > 0:
			var t = floor(reset_delay_time / delta) * delta # 没用
			time_since_last_fire -= t
			time_since_last_reset -= t

	if time_since_last_reset > 0:
		_bullet_event(delta)
		spherical_count = clamp(spherical_count, 1, 1000)

	# 计数
	time_since_last_fire += delta
	time_since_last_reset += delta
	# 检查是否可以发射弹幕
	if time_since_last_fire >= fire_rate / FRAME_RATE:
		time_since_last_fire = 0.0
		if ues_spherical:
			_calculate_spherical_uniform_distribution()
		else:
			_calculate_stripe_rotation()
		if emitter_mesh_display:
			emitter_mesh_display.debug_display() # debug显示
		match exceeding_the_cap_mode: # 发射弹幕
			CapMode.STOP_LAUNCHING:
				if bullet_ware.get_child_count() < bullet_max_node: # bullets.size()
					_fire_bullet()
			CapMode.DELETE_OLDEST:
				_fire_bullet()
		count_since_last_reset += 1


# 移动弹幕
# 100
# 1~70+  2~60+?  4~80
func _move_bullet(delta: float) -> void:
	pass

# 发射弹幕的函数
func _fire_bullet() -> void:
	number_of_launches_in_this_frame = 0
	if ues_spherical:
		for i in range(1, int(spherical_count) + 1):
			var target: Vector3 = spherical_targets[i-1]
			_set_bullet(emitter_center, target)
	else:
		for i in stripe_targets.size():
			var fire_pos: Vector3 = stripe_fire_positions[i] + self.global_position
			var target: Vector3 = stripe_targets[i]
			_set_bullet(fire_pos, target)


func _set_bullet(fire_pos: Vector3, target: Vector3) -> void: # 定义_set_bullet函数，用于设置弹幕的属性和发射
	pass


func _delete_out_cap_bullets() -> void: # 删除超出上限的弹幕
	pass


func _delete_expired_bullets(delta: float) -> void: # 删除过期的弹幕
	pass


func _delete_bullet(bullet) -> void: # 删除指定的弹幕
	pass


func _calculate_stripe_rotation() -> void:
	disk_positions.clear()
	rotation_matrixs.clear()
	curve_points.clear()
	stripe_fire_positions.clear()
	stripe_targets.clear()

	var range_angle = abs(stripe_range)
	var a = 270 - range_angle / 2.0  + stripe_angle
	var disk_offset = disk_range / 2.0

	for i: float in disk_count:
		var rota = Vector3.ZERO
		rota.z = (disk_range / disk_count) * (i+0.5)
		rota.z += disk_angle - disk_offset
		rota.z = deg_to_rad(rota.z)
		var rotation_matrix = Transform3D(Basis.from_euler(rota), Vector3.ZERO)
		var rotated_normal = Vector3.UP.rotated(Vector3.UP, a) * disk_radius
		var disk_pos = emitter_center + rotated_normal
		disk_positions.append(disk_pos)
		rotation_matrixs.append(rotation_matrix)

	for j: float in stripe_count:
		var angle = a + (range_angle / stripe_count) * (j+0.5) # 计算当前角度
		angle = deg_to_rad(angle)
		var curve_point = emitter_center + Vector3(cos(angle), 0, sin(angle) ) # 计算每个点
		curve_points.append(curve_point)

	for i in disk_count:
		for j in stripe_count:
			var fire_pos = disk_positions[i] + stripe_radius * (curve_points[j] - emitter_center)
			stripe_fire_positions.append(fire_pos * rotation_matrixs[i] )
			stripe_targets.append(curve_points[j] * rotation_matrixs[i] )


func _calculate_spherical_uniform_distribution() -> void:
	if not ues_spherical:
		return
	spherical_targets.clear()

	for i in range(1, int(spherical_count) + 1):
		var high: float = (2*i -1) / floor(spherical_count) - 1
		var radius = sqrt(1-pow(high, 2))
		var theta = TAU * i * pow(HL.GOLDEN_RATIO, ratio)

		var point: Vector3 = Vector3(
			radius * cos(theta),
			high,
			radius * sin(theta)
			) * display_radius

		spherical_targets.append(point)

	#方型造型术？
	#radius * cos(theta)**2 * sign(cos(theta)),
	#0, #sqrt(abs(1 - pow(radius, 2) ) ) * pow(-1, i),
	#radius * sin(theta)**2 * sign(sin(theta))


func calculate_bullet_up(bullet_direction: Vector3, _bullet_up_mode: BulletUpMode = BulletUpMode.UP, up: Vector3 = Vector3.UP, forward: Vector3 = Vector3.FORWARD) -> Vector3:
	var rezult: Vector3 = Vector3.ZERO

	match _bullet_up_mode:
		BulletUpMode.UP:
			rezult = up
		BulletUpMode.RANDOM:
			rezult = Vector3(
				randf_range(-1, 1),
				randf_range(-1, 1),
				randf_range(-1, 1)
			)
		BulletUpMode.EMITTER:
			rezult = -self.global_transform.basis.z

	if rezult.cross(bullet_direction).is_zero_approx():
		rezult = forward

	return rezult.normalized()




# 系列化保存
var dddddddd = {"jj": 1,  "ppw": "ddaaaaaa"}
var aad = [[235, [668, 9]]]
var Here_is_the_last_end = null
func _save_properties() -> void:
	reset_data.clear()
	#reset_data = get_property_list()
	var property_list:= self.get_property_list()
	#print(" ")
	#print(HL.format_array_recursive(property_list))
	#print(" ")

	#.duplicate()
	#inst_to_dict(self).duplicate()

	#reset_data.erase("reset_data")
	#for key in reset_data.keys():
		#if key is String:
			#if "@" in key or key.begins_with("_") or "count_since_last_reset" in key:
				#reset_data.erase(key)

	var start: bool = false
	#var end: bool = false
	for i in property_list.size():
		var propertie_name: String = property_list[i].name
		if propertie_name == "Here_is_the_last_start":
			start = true

		if start:
			var blacklist: bool = (
				propertie_name.begins_with("_")
				or "@" in propertie_name
				or "count_since_last_reset" in propertie_name
				or "reset_data" in propertie_name
				or ".gd" in propertie_name
				)
			if not blacklist:
				reset_data[propertie_name] = self.get(propertie_name)
			if only_reset_emitter_class and propertie_name == "Here_is_the_last_end":
				break


	print(" ")
	#print(reset_data)
	print(HL.format_dict_recursive(reset_data))
	print(" ")

	## 可选杀了继承的
	#if only_reset_emitter_class:.
		#var keys_to_remove: Array = []
		#var found = false
		#for key in reset_data.keys():
			#if found:
				#keys_to_remove.append(key)
			#if key == "Here_is_the_last_one":
				#found = true
		#for key in keys_to_remove:
			#reset_data.erase(key)


func _load_properties() -> void:
	for key in reset_data:
		self.set(key, reset_data[key])
