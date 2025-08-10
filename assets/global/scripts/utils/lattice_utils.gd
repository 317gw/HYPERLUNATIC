class_name LatticeUtils
extends NAMESPACE


#class GenerateLattice
const LATTICE_VECTORS = [
	Vector3(0, 0, 0),
	Vector3(0.5, 0.5, 0),
	Vector3(0.5, 0, 0.5),
	Vector3(0, 0.5, 0.5)
]


## FCC晶格的四个基础向量  FCC lattice
static func generate_FCC_lattice(_range: int = 2, process: Callable = HL._pass, condition: Callable = HL._true) -> PackedVector3Array:
	var arr: PackedVector3Array
	_range = max(_range, 1)
	for x in range(_range):
		for y in range(_range):
			for z in range(_range):
				for offset in LATTICE_VECTORS:
					var point = Vector3(x + offset.x, y + offset.y, z + offset.z) # Vector3(x, y, z)
					point = process.call(point)
					if condition.call(point) and not arr.has(point):
						arr.append(point)
	return arr


static func generate_cubic_lattice(_range: int = 2, process: Callable = HL._pass, condition: Callable = HL._true) -> PackedVector3Array:
	var arr: PackedVector3Array
	_range = max(_range, 1)
	for x in range(_range):
		for y in range(_range):
			for z in range(_range):
				var point = Vector3(x, y, z) # Vector3(x, y, z)
				point = process.call(point)
				if condition.call(point) and not arr.has(point):
					arr.append(point)
	return arr


	#var _min_edge: float = min(_aabb.size.x, _aabb.size.y, _aabb.size.z)
	#var _distance: float = voxel_point_distance * max(_min_edge*0.5, 1)  # 限制比例到0.5
## 自适应立方晶格
static func generate_adaption_cubic_lattice(_distance: float = 1.0, _aabb: AABB = AABB(), process: Callable = HL._pass, condition: Callable = HL._true) -> PackedVector3Array:
	var _range := Vector3i(_aabb.size / _distance/2)
	var rx := range(-_range.x, _range.x +1) if _range.x % 2 == 0 else range(-_range.x-1, _range.x+1)
	var ry := range(-_range.y, _range.y +1) if _range.y % 2 == 0 else range(-_range.y-1, _range.y+1)
	var rz := range(-_range.z, _range.z +1) if _range.z % 2 == 0 else range(-_range.z-1, _range.z+1)

	var offset = Vector3(
		float(_range.x % 2 != 0),
		float(_range.y % 2 != 0),
		float(_range.z % 2 != 0)
	)/2

	var arr: PackedVector3Array
	for x in rx:
		for y in ry:
			for z in rz:
				var point = (Vector3(x, y, z) + offset) * _distance
				point = process.call(point)
				if condition.call(point) and not arr.has(point):
					arr.append(point)
	return arr
