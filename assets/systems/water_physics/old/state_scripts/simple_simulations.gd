class_name SimpleSimulations
extends State

var no_surface: bool = false

@onready var water_physics: Node3D = $"../.."
@onready var mesh_instance_3d: MeshInstance3D = $"../../MeshInstance3D"
@onready var buoyancy_probe: Node3D = $"../../BuoyancyProbe"
@onready var resistance_probe: Node3D = $"../../ResistanceProbe"


func Physics_Update(_delta: float) -> void:
	#water_physics.calculate_velocity(_delta)

	if water_physics.raycast_surface_pos():
		if no_surface:
			water_physics.simple_simulations(_delta, true)
			if water_physics.ss_smooth_out():
				no_surface = false
		else:
			water_physics.simple_simulations(_delta)
		water_physics.damp_at_surface()
		water_physics.buoyancy_centre_clamp()
	else:
		no_surface = true
		water_physics.liquid_discharged_volume = MathUtils.exponential_decay(water_physics.liquid_discharged_volume, water_physics.volume * 0.5, _delta*20)
		water_physics.buoyancy_centre = Vector3.ZERO

	#water_physics.simple_simulations(_delta)
	#water_physics.damp_at_surface()
	#water_physics.buoyancy_centre_clamp()

	mesh_instance_3d.global_position = water_physics.buoyancy_centre + water_physics.global_position

	if not water_physics.is_in_water:
		Transitioned.emit(self, "OutWater")
	if not water_physics.is_using_simple_simulations():
		Transitioned.emit(self, "ProbeSimulations")
	if water_physics.is_at_surface():
		Transitioned.emit(self, "AtSurface")
	if water_physics.can_in_water_sleeping():
		Transitioned.emit(self, "InWaterSleeping")
