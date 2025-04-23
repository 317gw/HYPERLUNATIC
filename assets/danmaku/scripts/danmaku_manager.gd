extends Node3D

@onready var particles: HL.DmParticles = $Particles
@onready var bullet_and_collision: Node3D = $"Bullet&Collision"
@onready var multi_mesh_instances: Node3D = $MultiMeshInstances


func _ready() -> void:
	Global.danmaku_manager_ready.emit()
