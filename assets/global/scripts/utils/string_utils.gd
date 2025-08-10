class_name StringUtils
extends NAMESPACE


## 输入字符串输出颜色。输入几个相似的字符串，输出的颜色也应该是相似的。相同的输入会有相同的结果。允许不同字符串对应同样的结果。
## 0.1882 ~ 0.4784
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

## 输出限定字表限定长度的随机字符串
static func random_string(length: int = 7, character_set: String = HL.Alphanumeric) -> String:
	var result: String = ""
	for _i in range(length):
		result += character_set[randi() % character_set.length()]
	return result


##
static func filtrate_string(string: String, character_set: String = HL.LowercaseAlphabet) -> String:
	var _string: String = ""
	for i in string:
		if i in character_set:
			_string += i
	return _string


## 计算两个字符串的莱文斯坦距离（编辑距离）
static func levenshtein_distance(a: String, b: String) -> int:
	var len_a = a.length()
	var len_b = b.length()

	# 创建二维数组
	var dp:= []
	for i in range(len_a + 1):
		dp.append([])
		for j in range(len_b + 1):
			if i == 0:
				dp[i].append(j)  # 初始化第一行
			elif j == 0:
				dp[i].append(i)  # 初始化第一列
			else:
				dp[i].append(0)

	# 动态规划计算编辑距离
	for i in range(1, len_a + 1):
		for j in range(1, len_b + 1):
			var cost = 0 if a[i - 1] == b[j - 1] else 1
			dp[i][j] = min(
				dp[i-1][j] + 1,      # 删除操作
				dp[i][j-1] + 1,      # 插入操作
				dp[i-1][j-1] + cost   # 替换操作
			)

	return dp[len_a][len_b]


## 查找相似度最高的字符串
static func find_most_similar(target: String, candidates: Array) -> String:
	if candidates.is_empty():
		return ""

	var min_distance = levenshtein_distance(target, candidates[0])
	var best_match = candidates[0]

	for i in range(1, candidates.size()):
		var candidate = candidates[i]
		var distance = levenshtein_distance(target, candidate)

		# 如果找到更小的距离或相同距离但更短的字符串
		if distance < min_distance or (distance == min_distance and candidate.length() < best_match.length()):
			min_distance = distance
			best_match = candidate

	return best_match
