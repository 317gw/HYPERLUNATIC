class_name AtSurface
extends State


@onready var water_physics: Node3D = $"../.."
@onready var mesh_instance_3d: MeshInstance3D = $"../../MeshInstance3D"
@onready var buoyancy_probe: Node3D = $"../../BuoyancyProbe"
@onready var resistance_probe: Node3D = $"../../ResistanceProbe"


func Physics_Update(_delta: float) -> void:
	if water_physics.frame_skiper.skip_frame():
		return
	_delta = water_physics.frame_skiper.skiped_delta

	#water_physics.calculate_velocity(_delta)
	water_physics.raycast_surface_pos()
	water_physics.simple_simulations(_delta)
	water_physics.probe_simulations(_delta, 40, 0.2, false)
	#water_physics.at_surface_pid(_delta)
	water_physics.damp_at_surface()
	water_physics.buoyancy_centre_clamp()

	mesh_instance_3d.global_position = water_physics.buoyancy_centre + water_physics.global_position

	if not water_physics.is_in_water:
		Transitioned.emit(self, "OutWater")
	if not water_physics.is_at_surface():
		if water_physics.using_simple_simulations:
			Transitioned.emit(self, "SimpleSimulations")
		else:
			Transitioned.emit(self, "ProbeSimulations")
	if water_physics.can_in_water_sleeping():
		Transitioned.emit(self, "InWaterSleeping")
