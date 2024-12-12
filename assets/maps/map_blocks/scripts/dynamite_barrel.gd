extends RigidBody3D

@export var health: float = 5
@export var explode_damage: float = 4
@export var explode_radius: float = 6
@export var explode_force: float = 4000
@export var explode_time: float = 1 # bugggggggg
@export var rand_rotation_y: bool = true

const EXPLODE = preload ("res://assets/weapons/explode.tscn")
@onready var zzzz: MeshInstance3D = $"柱体"
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

var taking_damge: bool = false


func _ready() -> void:
	randomize()

	if rand_rotation_y:
		zzzz.rotation.y = randf_range(0, TAU)
		collision_shape_3d.rotation.y = zzzz.rotation.y


func _physics_process(_delta: float) -> void:
	if health <= 0:
		await get_tree().create_timer(randf_range(0.0, 1), false, true).timeout
		dead()


func be_hit(attack: HL.Attack) -> void:
	damaged(attack.damage)
	#var dir = attack.position.direction_to(global_position)
	#var force = dir * attack.knockback_force * attack.position.distance_to(global_position) / attack.radius
	#apply_impulse(force)
	prints("hit by", attack.source)


func damaged(damage: float) -> void:
	taking_damge = true
	health -= damage
	 # 没用？


func dead() -> void:
	var expl = EXPLODE.instantiate()
	Global.effects.add_child(expl)
	expl.global_position = global_position
	expl.explode(explode_damage, explode_radius, explode_force)
	expl.died_time = explode_time
	queue_free()
