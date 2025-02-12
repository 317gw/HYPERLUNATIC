class_name InWaterSleeping
extends State


@onready var water_physics: Node3D = $"../.."
@onready var mesh_instance_3d: MeshInstance3D = $"../../MeshInstance3D"
@onready var buoyancy_probe: Node3D = $"../../BuoyancyProbe"
@onready var resistance_probe: Node3D = $"../../ResistanceProbe"


func Enter():
	water_physics.is_in_water = true
	water_physics.sleeping = true
	buoyancy_probe.process_mode = Node.PROCESS_MODE_DISABLED
	resistance_probe.process_mode = Node.PROCESS_MODE_DISABLED


func Exit():
	water_physics.sleeping = false
	buoyancy_probe.process_mode = Node.PROCESS_MODE_INHERIT
	resistance_probe.process_mode = Node.PROCESS_MODE_INHERIT


func Physics_Update(_delta: float) -> void:
	#water_physics.calculate_velocity(_delta)

	water_physics.in_water_sleeping()

	mesh_instance_3d.global_position = water_physics.buoyancy_centre + water_physics.global_position

	if not water_physics.is_sleeping():
		if water_physics.is_using_simple_simulations():
			Transitioned.emit(self, "SimpleSimulations")
		else:
			Transitioned.emit(self, "ProbeSimulations")
