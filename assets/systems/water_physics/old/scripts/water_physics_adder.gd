#class_name WaterPhysicsAdder
extends Area3D

#const WATER_PHYSICS = preload("res://assets/systems/water_physics/water_physics.tscn")
const WATER_PHYSICS = preload("res://assets/systems/water_physics/old/water_physics.tscn")

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		for child in body.get_children():
			if child.name == "water_physics":
				return
		var water_physics = WATER_PHYSICS.instantiate()
		body.add_child(water_physics)
		water_physics.name = "water_physics"


func _on_timer_timeout() -> void:
	self.queue_free()
