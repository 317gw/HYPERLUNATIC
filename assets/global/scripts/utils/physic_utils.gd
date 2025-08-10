class_name PhysicsUtils
extends NAMESPACE


static func drag_force(Cd: float, density: float, velocity: Vector3, area: float) -> Vector3:
	return 0.5 * Cd * density * area * velocity.normalized() * velocity.length()**2


static func reynold(density: float, velocity: float, length: float, viscosity: float) -> float:
	return density * velocity * length / viscosity


# https://pages.mtu.edu/~fmorriso/DataCorrelationForSphereDrag2016.pdf
# Use beyond Re=106 is not recommended; for Re<2 equation 1 follows the creeping-flow result (CD=24/Re).
static func sphere_Cd_by_reynold(reynold: float) -> float:  # Sphere_oooo
	reynold = clampf(reynold, 0.01, 1e7)
	if reynold < 2:
		return 24/reynold
	var Re5: float = reynold/5.0
	var Re_105: float = reynold/2.63/1e5
	var Re_106: float = reynold/1e6
	var _a: float = 24 / reynold
	var _b: float = 2.6*Re5 / (1 + Re5**1.52)
	var _c: float = 0.411*Re_105**-7.94 / (1 + Re_105**-8)
	var _d: float = 0.25*Re_106 / (1 + Re_106)
	return _a+_b+_c+_d


## 算液体阻力   空阻   0 -> 1
static func get_water_friction(_density: float, _viscosity: float) -> float:
		var _d: float = clampf(remap(_density, 1000, 10000, 0.1, 0.5) , 0.0, 0.5)
		var _v: float = clampf(remap(_viscosity, 0, 20000, 0.0, 0.5) , 0.0, 0.5)
		return snappedf(_d + _v, 0.001)


## 弹性碰撞
static func impact_velocity(m1:float, m2:float, v1:float, v2:float) -> float:
	return (m1-m2)/(m1+m2)*v1 + 2*m2/(m1+m2)*v2
