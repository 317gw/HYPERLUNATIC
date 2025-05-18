class_name HL
extends NAMESPACE
# NameSpace daze⭐

# OMG! is .gd !!!!!!!!!
const DoubleClick = preload("res://assets/global/scripts/double_click.gd")
#const FrameSkiper = preload("res://assets/global/scripts/frame_skiper.gd")

const Attack = preload("res://assets/global/scripts/attack.gd")
const Weapon = preload("res://assets/weapons/scripts/weapon.gd")

const ForceControlCharacterBody3D = preload("res://assets/global/scripts/force_control_character_body3d.gd")

# Controller
const Player = preload("res://assets/controllers/scripts/PlayerController.gd")
const Camera = preload("res://assets/controllers/scripts/Camera3D.gd")
const WeaponManager = preload("res://assets/weapons/scripts/weapon_manager.gd")

# Weapons
const Rifle = preload("res://assets/weapons/rifle/rifle.gd")
const HolyFisher = preload("res://assets/weapons/holy_fisher/holy_fisher.gd")

# Physics
const FluidMechanics = preload("res://assets/systems/water_physics/scripts/fluid_mechanics.gd")
const FluidMechanicsManager = preload("res://assets/systems/water_physics/scripts/fluid_mechanics_manager.gd")
const WaterMesh = preload("res://assets/systems/water_physics/scripts/water_mesh.gd")

# Route
const Route = preload("res://assets/maps/map_blocks/scripts/route.gd")
const RouteTerminal = preload("res://assets/maps/map_blocks/terminal/route_terminal.gd")

const MarchingCubes = preload("res://assets/systems/marching_cubes/marching_cubes.gd")
const ChunkManager = preload("res://assets/systems/chunk/chunk_manager.gd")

# ui
const MainMenus = preload("res://assets/arts_graphic/ui/menu/main_menus.gd")
const OptionWindow = preload("res://assets/arts_graphic/ui/menu/option_window.gd")
const Propertie = preload("res://assets/arts_graphic/ui/menu/propertie.gd")
const PlayerFP_UI = preload("res://assets/arts_graphic/ui/player_ui/player_fp_ui.gd")
const FrontSight = preload("res://assets/arts_graphic/ui/player_ui/front_sight.gd")
const ToolUi = preload("res://assets/arts_graphic/ui/player_ui/tool_ui.gd")
const DebugMenu = preload("res://assets/arts_graphic/ui/debug_menu/debug_menu.gd")

# 弹幕
const DanmakuManager = preload("res://assets/danmaku/scripts/danmaku_manager.gd")
const DmParticles = preload("res://assets/danmaku/scripts/dm_particles.gd")

# map?
const SkyLimit = preload("res://assets/maps/map_blocks/scripts/sky_limit.gd")

# 常数
class Viscositys:
	const AIR: float = 0.0000178
	const WATER: float = 0.001
	const QUICKSILVER: float = 0.00155

const E: float = 2.718281828459045
const GOLDEN_RATIO: float = 0.618033988749895 ## 黄金分割率

# 小写英文字母
const LowercaseAlphabet: String = "abcdefghijklmnopqrstuvwxyz"
const LowercaseAlphabetArray: Array = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
# 大写英文字母
const UppercaseAlphabet: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const UppercaseAlphabetArray: Array = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
# 小写大写英文字母
const Alphabet: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
const AlphabetArray: Array = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
# 数字
const Digits: String = "0123456789"
const DigitsArray: Array = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
# 英文字母和数字
const Alphanumeric: String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
const AlphanumericArray: Array = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]


const NEW_BOX_SHAPE_3D = preload("res://assets/models/low_prefabricate/new_box_shape_3d.tres")
const NEW_CAPSULE_SHAPE_3D = preload("res://assets/models/low_prefabricate/new_capsule_shape_3d.tres")
const NEW_CYLINDER_SHAPE_3D = preload("res://assets/models/low_prefabricate/new_cylinder_shape_3d.tres")
const NEW_SEPARATION_RAY_SHAPE_3D = preload("res://assets/models/low_prefabricate/new_separation_ray_shape_3d.tres")
const NEW_SPHERE_SHAPE_3D = preload("res://assets/models/low_prefabricate/new_sphere_shape_3d.tres")
const shape_3d_array: Array = [NEW_BOX_SHAPE_3D, NEW_CAPSULE_SHAPE_3D, NEW_CYLINDER_SHAPE_3D, NEW_SEPARATION_RAY_SHAPE_3D, NEW_SPHERE_SHAPE_3D]


const NEW_BOX_MESH = preload("res://assets/models/low_prefabricate/new_box_mesh.tres")
const NEW_CAPSULE_MESH = preload("res://assets/models/low_prefabricate/new_capsule_mesh.tres")
const NEW_CYLINDER_MESH = preload("res://assets/models/low_prefabricate/new_cylinder_mesh.tres")
const NEW_PLANE_MESH = preload("res://assets/models/low_prefabricate/new_plane_mesh.tres")
const NEW_PRISM_MESH = preload("res://assets/models/low_prefabricate/new_prism_mesh.tres")
const NEW_QUAD_MESH = preload("res://assets/models/low_prefabricate/new_quad_mesh.tres")
const NEW_SPHERE_MESH = preload("res://assets/models/low_prefabricate/new_sphere_mesh.tres")
const NEW_TORUS_MESH = preload("res://assets/models/low_prefabricate/new_torus_mesh.tres")
const mesh_array: Array = [NEW_BOX_MESH, NEW_CAPSULE_MESH, NEW_CYLINDER_MESH, NEW_PLANE_MESH, NEW_PRISM_MESH, NEW_QUAD_MESH, NEW_SPHERE_MESH, NEW_TORUS_MESH]


# ↓常用复用静态函数
static func _pass(value): return value
static func _true(value) -> bool: return true
static func _nop(_arg = null): pass


## 用于代替lerp在 _process 等中每帧调用平滑数据  4.6秒到达99%  x乘delta缩短x倍时间 __By 317GW 2024 8 31 半夜
static func exponential_decay(from: float, to: float, delta: float) -> float:
	var x0 = log(abs(to - from) )
	return to - exp(x0 - delta) * sign(to - from)


static func exponential_decay_vec2(from: Vector2, to: Vector2, delta: float) -> Vector2:
	return Vector2(
		exponential_decay(from.x, to.x, delta),
		exponential_decay(from.y, to.y, delta)
		)

static func exponential_decay_vec3(from: Vector3, to: Vector3, delta: float) -> Vector3:
	return Vector3(
		exponential_decay(from.x, to.x, delta),
		exponential_decay(from.y, to.y, delta),
		exponential_decay(from.z, to.z, delta)
		)


static func sigmoid(value: float) -> float:
	return 1 / (1 + pow(E, -value))


#class GenerateLattice
const LATTICE_VECTORS = [
	Vector3(0, 0, 0),
	Vector3(0.5, 0.5, 0),
	Vector3(0.5, 0, 0.5),
	Vector3(0, 0.5, 0.5)
]
# FCC晶格的四个基础向量  FCC lattice
static func generate_FCC_lattice(_range: int = 2, process: Callable = _pass, condition: Callable = _true) -> PackedVector3Array:
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


static func generate_cubic_lattice(_range: int = 2, process: Callable = _pass, condition: Callable = _true) -> PackedVector3Array:
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
# 自适应立方晶格
static func generate_adaption_cubic_lattice(_distance: float = 1.0, _aabb: AABB = AABB(), process: Callable = _pass, condition: Callable = _true) -> PackedVector3Array:
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


# 输入字符串输出颜色。输入几个相似的字符串，输出的颜色也应该是相似的。相同的输入会有相同的结果。允许不同字符串对应同样的结果。
# 0.1882 ~ 0.4784
static func get_color_from_string(input: String, ues_alpha: bool = false) -> Color:
	var sum: Vector4 = Vector4.ZERO
	var decay: Vector4 = Vector4(0.8, 0.7, 0.6, 1.0)
	var weight: Vector4 = Vector4.ONE

	for i in range(input.length()):
		var char_code: int = input.unicode_at(i)
		char_code = remap(float(char_code), "0".unicode_at(0), "z".unicode_at(0), 0, 255)
		sum += char_code * weight# * difference
		weight *= decay

	var r = cos(sum.x/255*PI) * 0.5 + 0.5
	var g = cos(sum.y/255*PI) * 0.5 + 0.5
	var b = cos(sum.z/255*PI) * 0.5 + 0.5
	var a = cos(sum.w/255*PI) * 0.5 + 0.5 if ues_alpha else 1.0
	return Color(r, g, b, a)

"""测试
	var strs: Array = HL.AlphanumericArray + ["hello", "hellp", "hallo", "nello", "fu*@ck"]
	for i in strs.size():
		var color:= HL.get_color_from_string(strs[i])
		print_rich("[color=#%s][b]%s[/b][/color]" % [color.to_html(), strs[i]])
		print(color)

	for i in 50:
		var str = HL.random_string(randi_range(1, 10))
		var color:= HL.get_color_from_string(str)
		print_rich("[color=#%s][b]%s[/b][/color]" % [color.to_html(), str])
		print(color)
"""


# 输出限定字表限定长度的随机字符串
static func random_string(length: int = 7, character_set: String = Alphanumeric) -> String:
	var result: String = ""
	for _i in range(length):
		result += character_set[randi() % character_set.length()]
	return result


static func rainbow_color_custom(time: float, speed: float = GOLDEN_RATIO, saturation: float = 1.0, value: float = 1.0) -> Color:
	var hue: float = fmod(time, 1.0) # 计算色相 (0-1范围)，基于帧数和速度
	var rainbow_color := Color.from_hsv(hue, saturation, value) # 使用HSV颜色模型创建颜色
	return rainbow_color


static func rainbow_color_real_time(speed: float = GOLDEN_RATIO, saturation: float = 1.0, value: float = 1.0) -> Color:
	var time = Time.get_ticks_msec() / 10000.0  # 获取秒数
	var hue = fmod(time * speed, 1.0)
	return Color.from_hsv(hue, saturation, value)


# 字典和数组的文本格式化排版
const FOUR_SPACES: String = "    "
static func format_dict_recursive(dict: Dictionary, indent_level := 0) -> String:
	var indent := FOUR_SPACES.repeat(indent_level)
	var result := "{\n"
	var keys := dict.keys()
	for i in keys.size():
		var key = keys[i]
		var value = dict[key]

		result += indent + FOUR_SPACES + '"%s": ' % str(key)

		if value is Dictionary:
			result += format_dict_recursive(value, indent_level + 1)
		elif value is Array:
			result += format_array_recursive(value, indent_level + 1)
		elif value is String:
			result += '"' + str(value) + '"'
		elif value is StringName:
			result += '&"' + str(value) + '"'
		else:
			result += str(value)

		if i < keys.size() - 1:
			result += ",\n"
		else:
			result += "\n"

	result += indent + "}"
	return result


static func format_array_recursive(array: Array, indent_level := 0) -> String:
	if array.is_empty():
		return "[]"

	# 单元素数组不换行
	if array.size() == 1:
		var element = array[0]
		if element is Dictionary:
			return "[%s]" % format_dict_recursive(element, indent_level + 1)
		elif element is Array:
			return "[%s]" % format_array_recursive(element, indent_level + 1)
		else:
			return "[%s]" % str(element)

	# 多元素数组正常换行格式化
	var indent := FOUR_SPACES.repeat(indent_level)
	var result := "[\n"
	for i in array.size():
		result += indent + FOUR_SPACES

		var element = array[i]
		if element is Dictionary:
			result += format_dict_recursive(element, indent_level + 1)
		elif element is Array:
			result += format_array_recursive(element, indent_level + 1)
		elif element is String:
			result += '"' + str(element) + '"'
		elif element is StringName:
			result += '&"' + str(element) + '"'
		else:
			result += str(element)

		if i < array.size() - 1:
			result += ",\n"
		else:
			result += "\n"

	result += indent + "]"
	return result


static func string_num_pad_decimals(number: float, decimals: int = 1, sign: String = "") -> String:
	var _num: String = String.num(number, decimals).pad_decimals(decimals)
	if sign == "":
		return _num
	else:
		if int(number) >= 0 or is_zero_approx(number):
			return sign + _num.replacen("-", "")
		else:
			return _num

	#return "+" + _num if (sign and (int(number) >= 0 or is_zero_approx(number))) else _num


static func format_vector(vector, decimals: int = 3) -> Dictionary:
	if vector is Vector2:
		var vector2: Vector2 = vector
		return {
			"x": string_num_pad_decimals(vector2.x, decimals),
			"y": string_num_pad_decimals(vector2.y, decimals)
		}
	elif vector is Vector3:
		var vector3: Vector3 = vector
		return {
			"x": string_num_pad_decimals(vector3.x, decimals),
			"y": string_num_pad_decimals(vector3.y, decimals),
			"z": string_num_pad_decimals(vector3.z, decimals)
		}
	elif vector is Vector4:
		var vector4: Vector4 = vector
		return {
			"x": string_num_pad_decimals(vector4.x, decimals),
			"y": string_num_pad_decimals(vector4.y, decimals),
			"z": string_num_pad_decimals(vector4.z, decimals),
			"w": string_num_pad_decimals(vector4.w, decimals)
		}
	else:
		return {}


# return_vector["all"] =  X:1.321 Y:2.312 Z:3.312      (1.321, 2.312, 3.312)
# HL.format_vector_extended().
static func format_vector_extended(vector, decimals: int = 3) -> Dictionary:
	var result := format_vector(vector, decimals)
	if result.is_empty():
		return {}

	if vector is Vector2:
		result["all"] = "X %s  Y %s" % [result["x"], result["y"]]
		result["tuple"] = "(%s, %s)" % [result["x"], result["y"]]
	elif vector is Vector3:
		result["all"] = "X %s  Y %s  Z %s" % [result["x"], result["y"], result["z"]]
		result["tuple"] = "(%s, %s, %s)" % [result["x"], result["y"], result["z"]]
	elif vector is Vector4:
		result["all"] = "X %s  Y %s  Z %s  W %s" % [result["x"], result["y"], result["z"], result["w"]]
		result["tuple"] = "(%s, %s, %s, %s)" % [result["x"], result["y"], result["z"], result["w"]]

	return result


# 最接近给定整数的2的次方数，大的那个
static func next_power_of_two(n: int) -> int:
	if n <= 0:
		return 1
	var power := 1
	while power < n:
		power <<= 1
	return power


# 最接近给定整数的2的次方数
static func nearest_power_of_two(n: int) -> int:
	var power := next_power_of_two(n)
	# 检查哪个更接近
	var lower := power >> 1
	if (n - lower) < (power - n):
		return lower
	return power


# 最近步长函数   没大用  用 snapped() 即可
static func round_to_step(value: float, step: float) -> float:
	if step <= 0:
		push_error("步长必须大于0")
		return value

	var rounded = round(value / step) * step
	# 处理浮点数精度问题，保留小数点后足够位数
	return snapped(rounded, step)


# 将两个向量的点积转换为它们的夹角（弧度）
static func dot_product_to_angle(dot_product: float, magnitude_a: float = 1.0, magnitude_b: float = 1.0) -> float:
	if magnitude_a == 0.0 or magnitude_b == 0.0:
		return 0.0
	var cosine = dot_product / (magnitude_a * magnitude_b)
	cosine = clamp(cosine, -1.0, 1.0)  # 避免数值误差导致反余弦错误
	return acos(cosine)

# 将夹角（弧度）转换为两个向量的点积
static func angle_to_dot_product(angle_rad: float, magnitude_a: float = 1.0, magnitude_b: float = 1.0) -> float:
	return magnitude_a * magnitude_b * cos(angle_rad)


static func power(base: float, exponent: float) -> float:
	return pow(abs(base), exponent) * sign(base)
