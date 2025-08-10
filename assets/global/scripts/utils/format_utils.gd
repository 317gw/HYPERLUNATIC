class_name FormatUtils
extends NAMESPACE


## 字典的文本格式化排版
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


## 数组的文本格式化排版
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


## 格式化float到字符，可选正负号
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


## 向量格式化
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
# FormatUtils.format_vector_extended().
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
