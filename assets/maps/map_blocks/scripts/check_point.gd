extends Area3D

@export var rotation_speed: float = 10
@export var noise_range_ori: float = 0.3
@export var uv_offset_ori: Vector2 = Vector2(0, 0.025)

var player_in_centre: bool = false
var current_rotation_speed: float
var material: ShaderMaterial
var noise_range_trg: float
var uv_offset_trg: Vector2

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	material = mesh_instance_3d.material_override


func _physics_process(delta: float) -> void:
	if player_in_centre:
		current_rotation_speed = HL.exponential_decay(current_rotation_speed, rotation_speed*3, delta*5)
		noise_range_trg = HL.exponential_decay(noise_range_trg, 0.6, delta*5)
		uv_offset_trg = HL.exponential_decay_vec2(uv_offset_trg, Vector2(0.0, -0.4), delta*5)
	else:
		current_rotation_speed = HL.exponential_decay(current_rotation_speed, rotation_speed, delta*5)
		noise_range_trg = HL.exponential_decay(noise_range_trg, noise_range_ori, delta*5)
		uv_offset_trg = HL.exponential_decay_vec2(uv_offset_trg, uv_offset_ori, delta*5)
	material.set_shader_parameter("noise_range", noise_range_trg)
	material.set_shader_parameter("uv_offset", uv_offset_trg)


	var rotation_amount = current_rotation_speed * delta
	mesh_instance_3d.rotate_y(deg_to_rad(rotation_amount)) # 转


func _on_body_entered(body: Node3D) -> void:
	if body is HL.Player:
		player_in_centre = true


func _on_body_exited(body: Node3D) -> void:
	if body is HL.Player:
		player_in_centre = false
