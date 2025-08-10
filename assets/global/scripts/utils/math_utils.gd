class_name MathUtils
extends NAMESPACE


## 指数衰减函数
## 用于代替 lerp 在 _process 等中每帧迭代产生平滑数据效果，帧率无关
## 4.60517秒到达99%，x乘delta缩短x倍时间，如delta * 4.60517将在1秒到99%
static func exponential_decay(from: float, to: float, delta: float) -> float:
	return from * exp(-delta) + to * (1 - exp(-delta))

	# 老实现 __By 317GW 2024 8 31 半夜
	#var x0 = log(abs(to - from) )
	#return to - exp(x0 - delta) * sign(to - from)

	# lerp变形
	#return lerp(from, to, 1 - exp(-delta))

# ↓decay_rate多余，使用时直接在delta上乘比例不就行了
#static func exponential_decay(from: float, to: float, delta: float, decay_rate: float = 1.0) -> float:
	#return from * exp(-delta * decay_rate) + to * (1 - exp(-delta * decay_rate))

"""
测得进度
%			s
1			0.01005
5			0.05129
10			0.10536
20			0.22314
25			0.28768
50			0.69315
75			1.38629

90			2.30259
99			4.60517
99.9		6.90776
99.99		9.21034

99.999		11.51293
99.9999		13.81551
99.99999	16.1181
"""


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
	return 1 / (1 + pow(HL.E, -value))


## 高斯函数
static func gaussian(x: float, center: float, width: float) -> float:
	return exp(-0.5 * ((x - center) / width) ** 2)


static func power(base: float, exponent: float) -> float:
	return pow(abs(base), exponent) * sign(base)


## 最接近给定整数的2的次方数，大的那个
static func next_power_of_two(n: int) -> int:
	if n <= 0:
		return 1
	var power := 1
	while power < n:
		power <<= 1
	return power


## 最接近给定整数的2的次方数
static func nearest_power_of_two(n: int) -> int:
	var power := next_power_of_two(n)
	# 检查哪个更接近
	var lower := power >> 1
	if (n - lower) < (power - n):
		return lower
	return power


## 将两个向量的点积转换为它们的夹角（弧度）
static func dot_product_to_angle(dot_product: float, magnitude_a: float = 1.0, magnitude_b: float = 1.0) -> float:
	if magnitude_a == 0.0 or magnitude_b == 0.0:
		return 0.0
	var cosine = dot_product / (magnitude_a * magnitude_b)
	cosine = clamp(cosine, -1.0, 1.0)  # 避免数值误差导致反余弦错误
	return acos(cosine)


## 将夹角（弧度）转换为两个向量的点积
static func angle_to_dot_product(angle_rad: float, magnitude_a: float = 1.0, magnitude_b: float = 1.0) -> float:
	return magnitude_a * magnitude_b * cos(angle_rad)


## 计算两个数的最大公因数
static func gcd(a: int, b: int) -> int:
	while b != 0:
		var temp = b
		b = a % b
		a = temp
	return abs(a)


## 计算两个数的最小公倍数
static func lcm(a: int, b: int) -> int:
	return abs(a) / gcd(a, b) * abs(b)


## 计算数组的最大公因数
static func array_gcd(arr: Array[int]) -> int:
	if arr.size() == 0:
		return 0
	var result = arr[0]
	for i in range(1, arr.size()):
		result = gcd(result, arr[i])
		if result == 1:
			break
	return result


## 计算数组的最小公倍数
static func array_lcm(arr: Array[int]) -> int:
	if arr.size() == 0:
		return 0

	var result = arr[0]
	for i in range(1, arr.size()):
		result = lcm(result, arr[i])
	return result


## 返回数组的GCD和LCM
static func get_gcd_and_lcm(arr: Array[int]) -> Dictionary:
	return {
		"gcd": array_gcd(arr),
		"lcm": array_lcm(arr)
	}


## 计算两个整数的最简比（如4:3, 16:9）
static func simplify_ratio(a: int, b: int, flag: String = ":", min_digits_a: int = 0, min_digits_b: int = 0) -> String:
	if a == 0 or b == 0:
		#push_error("参数不要为0")
		return str(a) + flag + str(b)
	# 取绝对值处理负数情况
	var abs_a: int = abs(a)
	var abs_b: int = abs(b)
	var common_divisor: int = gcd(abs_a, abs_b);

	var simplified_a: String = str(abs_a / common_divisor).pad_zeros(max(min_digits_a, len(str(abs_a / common_divisor))))
	var simplified_b: String = str(abs_b / common_divisor).pad_zeros(max(min_digits_b, len(str(abs_b / common_divisor))))
	return simplified_a + flag + simplified_b





## 缩放精度
## 废弃
static func clamping_accuracy(n: float, precision: int = 6) -> float:
	if precision < 1:
		return n
	return int(n * precision) / float(precision)


## 缩放精度
## 废弃
static func clamping_accuracy_vector3(vector3: Vector3, precision: int = 6) -> Vector3:
	if precision < 1:
		return vector3
	vector3.x = clamping_accuracy(vector3.x, precision)
	vector3.y = clamping_accuracy(vector3.y, precision)
	vector3.z = clamping_accuracy(vector3.z, precision)
	return vector3


## 查找比例
## 废弃
static func get_closest_aspect_ratio(size: Vector2) -> String:
	var aspect_ratio: float = size.x / size.y

	# 标准比例及其对应的宽高比值
	var standard_ratios: Dictionary = {
		"4:3": 4.0/3.0,
		"5:4": 5.0/4.0,
		"16:9": 16.0/9.0,
		"16:10": 16.0/10.0,
		"21:9": 21.0/9.0,
		"32:9": 32.0/9.0
	}

	var closest_ratio := "16:9"  # 默认值
	var min_diff := INF

	# 找出最接近的标准比例
	for ratio: String in standard_ratios:
		var diff: float = abs(aspect_ratio - standard_ratios[ratio])
		if diff < min_diff:
			min_diff = diff
			closest_ratio = ratio

	return closest_ratio


# 最近步长函数   没大用  用 snapped() 即可
#static func round_to_step(value: float, step: float) -> float:
	#if step <= 0:
		#push_error("步长必须大于0")
		#return value
#
	#var rounded = round(value / step) * step
	## 处理浮点数精度问题，保留小数点后足够位数
	#return snapped(rounded, step)
