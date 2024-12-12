#class_name Rifle
extends HL.Weapon

const BULLET_DECAL = preload ("res://assets/weapons/bullet_decal.tscn")
const FIRE_LINE = preload ("res://assets/weapons/fire_line.tscn")

@export var fire_line_color: Color
@export var firing_range: float = 1000
@export var damage: float = 1.5
@export var knockback_force: float = 0.5


var animation_state_machine: AnimationNodeStateMachinePlayback
var target_rotation: Vector3 = Vector3.ZERO
var wall_limit: float = 0.0


@onready var gun_ray_cast: RayCast3D = $MuzzleMarker/GunRayCast
@onready var wall_limit_marker: Marker3D = $WallLimitMarker
@onready var normal_target_marker: Marker3D = $"MuzzleMarker/NormalTargetMarker"
@onready var muzzle_marker: Marker3D = $"MuzzleMarker"
@onready var animation_tree: AnimationTree = $AnimationTree # 获取AnimationTree
@onready var fire_mark: Node3D = $"MuzzleMarker/开火标记"
@onready var target_ball: MeshInstance3D = $TargetBall


func Ready() -> void: # 节点准备好时执行
	animation_state_machine = animation_tree["parameters/playback"]
	gun_ray_cast.target_position.z = -firing_range
	normal_target_marker.position.z = -firing_range
	target_rotation = self.rotation
	wall_limit = -wall_limit_marker.position.z
	self_position_origin = self.position


func Physics_Update(_delta: float) -> void:
	if fire_mark.visible == true:
		await get_tree().create_timer(_delta).timeout
		fire_mark.visible = false

	var look_at_target: Vector3 = PLAYER.eye_ray_cast.get_collision_point() if PLAYER.eye_ray_cast.is_colliding() else PLAYER.normal_target_marker.global_position
	var speed = 20 * _delta
	var self_rotation_before = self.rotation
	self.look_at(look_at_target)
	target_rotation.x = Global.exponential_decay(self_rotation_before.x, self.rotation.x, speed)
	target_rotation.y = Global.exponential_decay(self_rotation_before.y, self.rotation.y, speed)
	target_rotation.z = Global.exponential_decay(self_rotation_before.z, self.rotation.z, speed)
	self.rotation = target_rotation

	self.position = self_position_origin
	var distance_to_wall = wall_limit - self.global_position.distance_to(look_at_target)
	distance_to_wall = clamp(distance_to_wall, 0.0, wall_limit)
	self.position = self_position_origin + self.transform.basis.z * distance_to_wall
	# else:
	# 	self.position = self_position_origin

	target_ball.global_position = look_at_target
	# print("look_at_target:", look_at_target)


func Main_Action() -> void:
	if animation_state_machine.get_current_node() != "大开火加退弹":
		animation_state_machine.start("大开火加退弹", true)

		fire_mark.visible = true
		fire_mark.rotation.z = (randf() - 0.5)*PI*0.3

		var shoot_pos: Vector3 = muzzle_marker.global_position
		var target_pos: Vector3 = gun_ray_cast.get_collision_point() if gun_ray_cast.is_colliding() else normal_target_marker.global_position
		var line = FIRE_LINE.instantiate()
		line.set_line(shoot_pos, target_pos - global_position, 4, fire_line_color)
		add_child(line)

		if gun_ray_cast.is_colliding():
			var body = gun_ray_cast.get_collider()
			print(body)
			add_bullet_decal(target_pos, body)
			if body.is_in_group("BodyBoneParts"):
				body = get_BodyBoneRoot(body.get_parent()) # 递归寻找身体根节点
			if body.has_method("be_hit"): # 击中敌人
				var attack = HL.Attack.new()
				attack.damage = damage
				attack.knockback_force = knockback_force
				attack.position = global_position
				body.be_hit(attack)


func add_bullet_decal(target_pos: Vector3, body):
	if gun_ray_cast.is_colliding():
		var decal = BULLET_DECAL.instantiate()
		body.add_child(decal)
		decal.global_position = target_pos
		if gun_ray_cast.get_collision_normal() == Vector3.UP:
			decal.rotation = Vector3(PI / 2, 0, 0)
		elif gun_ray_cast.get_collision_normal() == Vector3.DOWN:
			decal.rotation = -Vector3(PI / 2, 0, 0)
		else:
			decal.look_at(target_pos + gun_ray_cast.get_collision_normal(), Vector3.UP)


func get_BodyBoneRoot(body) -> Node:
	if body.is_in_group("BodyBoneRoot"):
		return body
	return get_BodyBoneRoot(body.get_parent())
