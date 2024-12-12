@tool
extends Node3D
class_name CloudRotatingBase

@export var init_clouds: bool = true ## 重新加载
@export var reload: bool = false ## 重新加载
@export_range(0, 200, 1) var cloud_count: int = 10 ## 云的数量
@export var cloud_speed = 1.0 ## 云的速度

# @export var r_h_scale: float = 1.0 ## 半径高度乘数
@export var cloud_radius: float = 100.0 ## 位置的半径
@export var cloud_height: float = 10.0 ## 位置的高度
@export var cloud_scale = 1.0 ## 云的缩放

@export var to_player: bool = false
@export_range(0, 1) var rotation_x_mix = 0.5
@export_range(0, 1) var polar_spherical_mix = 0.5

@export_category("offset")
@export var speed_offset: float = 0.0 ## 速度偏移
@export var r_offset: float = 0.0 ## 半径偏移
@export var h_offset: float = 0.0 ## 高度偏移
@export var scale_offset: float = 0.0 ## 缩放偏移
@export var r_offset_x_scale = 0.0 ## 半径偏移致缩放系数
#@export var cloud_color = Color(1, 1, 1, 1) ## 云的颜色

var center: Vector3 = Vector3.ZERO ## 中心

var clouds = []

#@export var CLOUD_SPRITES: AnimatedSprite3D
const CLOUD_SPRITES = preload("res://assets/special_effects/shader_cloud.tscn")

@onready var player: HL.Controller.Player = $"../Player"

func _ready() -> void:
	randomize()

func _physics_process(_delta: float) -> void:
	# 如果cloud_count大于0并且子节点的数量不等于cloud_count
	if (cloud_count > 0 and get_child_count()!= cloud_count) or reload:
		clouds.clear()
		delete_all_clouds()
		if init_clouds:
			init_cloud()
		reload = false

	for i in range(clouds.size()):
		var cloud = clouds[i]
		center = self.global_position
		var speed = (cloud_speed + cloud.rand_speed_offset) * _delta
		var direction = self.global_position.direction_to(cloud.self.global_position)

		var distance = self.global_position.distance_to(cloud.self.global_position)
		var polar_angle_xz = -Vector2(direction.x, direction.z).angle_to(Vector2.RIGHT)

		var polar = polar_vector(
			polar_angle_xz + speed,
			abs(cloud_radius + cloud.rand_r_offset),
			cloud.height
		)

		var spherical = spherical_vector(
			abs(cloud_radius + cloud.rand_r_offset),
			polar_angle_xz + speed + PI,
			cloud.height / (cloud_height + h_offset) - PI/2
		)

		cloud.self.global_position = lerp(polar, spherical, polar_spherical_mix)


		# 让z轴方向的云面向父节点的中心
		# and center.angle_to(Vector3(0, 1, 0)) > 0
		if player and cloud.self.global_position != center:
			cloud.self.look_at(player.global_position)
		var rotation_to_player: Vector3 = cloud.self.rotation
		if cloud.self.global_position != center:
			cloud.self.look_at(center)
		var rotX = cloud.self.rotation.x
		if to_player:
			rotX = rotation_to_player.x
		cloud.self.rotation.x = lerpf(0, rotX, rotation_x_mix)

		var cloud_scale_temp = cloud_scale
		if r_offset != 0:
			cloud_scale_temp += r_offset_x_scale *((distance - cloud_radius + r_offset)/(2 * r_offset))
		cloud.self.set_scale(cloud_scale_temp * Vector3.ONE)

		# child.position += direction * speed

		# child.position = Vector3( # 绕父节点中心Y轴水平旋转
		# 	child.position.x * cos(speed) - child.position.z * sin(speed),
		# 	child.position.y,
		# 	child.position.x * sin(speed) + child.position.z * cos(speed)
		# )


func polar_vector(angle: float = 0.0, length: float = 0.0, height: float = 0.0) -> Vector3:
	var v2 = Vector2.RIGHT.rotated(angle) * length
	return Vector3(v2.x, height, v2.y)

# 球坐标
func spherical_vector(radius: float, theta: float, phi: float) -> Vector3:
	var x = radius * sin(phi) * cos(theta)
	var z = radius * sin(phi) * sin(theta)
	var y = radius * cos(phi)
	return Vector3(x, y, z)


func rand(ranges: float) -> float:
	if ranges == 0:
		return 0
	return randf_range(-ranges, ranges)

# 初始化云
func init_cloud() -> void:
	clouds.clear()
	for i in range(cloud_count):
		var cloud: MeshInstance3D = CLOUD_SPRITES.instantiate()

		var rand_speed_offset = rand(speed_offset)
		var rand_r_offset = rand(r_offset)
		var rand_h_offset = rand(h_offset)
		var rand_scale_offset = rand(scale_offset)
		var rand_angle = randf_range(0, TAU) # 随机水平角度
		var height = cloud_height + rand_h_offset

		var radius_temp = cloud_radius + rand_r_offset
		var rand_pos: Vector3 = Vector3.ZERO
		rand_pos.y = height
		rand_pos.x = radius_temp * sin(rand_angle)
		rand_pos.z = radius_temp * cos(rand_angle)

		cloud.set_position(rand_pos)
		var material: ShaderMaterial = cloud.mesh.surface_get_material(0)
		material.set_shader_parameter("frame", randi_range(0, 10))
		#.set_shader_param("INSTANCE_CUSTOM.z", randi_range(0, 10))
		# cloud.frame = randi_range(0, 10)
		cloud.rotation.y += randi_range(0, 1) * PI
		#cloud.set_speed(cloud_speed)
		#cloud.set_color(cloud_color)

		clouds.append({
			"self": cloud,
			"rand_speed_offset": rand_speed_offset,
			"rand_r_offset": rand_r_offset,
			"rand_h_offset": rand_h_offset,
			"rand_scale_offset": rand_scale_offset,
			"rand_angle": rand_angle,
			"height": height
			})

		add_child(cloud)

# 删除所有子节点
func delete_all_clouds() -> void:
	for child in get_children():
		if child.is_in_group("cloud"):
			child.queue_free()
