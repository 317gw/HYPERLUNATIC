extends RigidBody3D



func _integrate_forces(_state):
	apply_central_impulse(Vector3.FORWARD)
