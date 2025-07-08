class_name AlphabetDivision
extends NAMESPACE


# 常见后缀列表（按长度分组）
const TwoLetterSuffixes = ["ed", "es", "er", "or", "al", "ic", "ty", "fy", "en", "le", "ne", "st", "ly"]
const ThreeLetterSuffixes = ["ing", "ful", "est", "ish", "ive", "ous", "ism", "ate"]
const FourLetterSuffixes = ["tion", "ness", "ment", "ship", "hood", "ward", "able", "ible"]

# 常见辅音组合
const CommonConsonantTrigraphs = ["sch", "scr", "shr", "sph", "spl", "spr", "squ", "str", "thr"]
const CommonConsonantDigraphs = ["bl", "br", "ch", "ck", "cl", "cr", "dr", "fl", "fr", "gh", "gl", "gr", "ng", "ph", "pl", "pr", "qu", "sc", "sh", "sk", "sl", "sm", "sn", "sp", "st", "sw", "th", "tr", "tw", "wh", "wr"]

# 常见元音组合
const CommonVowelDigraphs = ["ai", "au", "aw", "ay", "ea", "ee", "ei", "eu", "ew", "ey", "ie", "oa", "oe", "oi", "oo", "ou", "ow", "oy", "ue", "ui"]

# 短单词词库 One Two Letter Words
const OneLetterWords: Array = ["a", "i"]
const TwoLetterWordsHighFrequency: Array = ["am", "an", "as", "at", "be", "by", "do", "go", "ha", "he", "hi", "if", "in", "is", "it", "me", "my", "no", "of", "ok", "on", "or", "so", "to", "up", "us", "we"]
const TwoLetterWordsLessCommon: Array = ["aa", "ab", "ad", "ae", "ag", "ai", "al", "ar", "ba", "bi", "da", "de", "ef", "el", "em", "en", "er", "es", "et", "ex", "fa", "fe", "gi", "id", "jo", "ka", "ki", "lo", "ma", "mi", "mu", "na", "ne", "od", "oe", "om", "op", "os", "ou", "ow", "ox", "pe", "pi", "qi", "re", "sh", "si", "ta", "ti", "uh", "um", "ut", "xi", "xu", "ye", "yo", "za"]


# 主分割函数
"""
按照看起来像是英文单词的样式分割小写随机英文字母字符串，不改变顺序，可以设置单词长度范围
涉及短单词的时候，参考脚本内的单词字符串数组，降低TwoLetterWordsHighFrequency对应的概率
其他更长的单词无需参考词典
"""
static func split_like_english_words(string: String, min_length: int = 2, max_length: int = 8) -> Array:
	if string.is_empty():
		return []

	string = HL.filtrate_string(string.to_lower())
	var vowels = "aeiou"
	var segments = []
	var start = 0
	var n = string.length()

	# 第一遍：基于规则分割
	while start < n:
		var end = start
		var consec_cons = 0
		var consec_vow = 0
		var found = false

		while end < n and not found:
			var c = string[end]
			var current_length = end - start + 1
			var current_segment = string.substr(start, current_length)
			var next_char = string[end + 1] if end + 1 < n else ""

			# 规则1：后缀匹配（优先检查）
			if not found:
				# 检查4字母后缀
				if current_length >= 4:
					var last_four = current_segment.substr(current_length - 4, 4)
					if last_four in FourLetterSuffixes:
						segments.append(current_segment)
						start = end + 1
						found = true

				# 检查3字母后缀
				if not found and current_length >= 3:
					var last_three = current_segment.substr(current_length - 3, 3)
					if last_three in ThreeLetterSuffixes:
						segments.append(current_segment)
						start = end + 1
						found = true

				# 检查2字母后缀
				if not found and current_length >= 2:
					var last_two = current_segment.substr(current_length - 2, 2)
					if last_two in TwoLetterSuffixes:
						segments.append(current_segment)
						start = end + 1
						found = true

			# 规则2：长度超过max_length
			if not found and current_length >= max_length:
				segments.append(current_segment)
				start = end + 1
				found = true

			# 更新连续辅音/元音计数
			if not found:
				if vowels.find(c) >= 0:
					consec_vow += 1
					consec_cons = 0
				else:
					consec_cons += 1
					consec_vow = 0

				# 规则3：连续辅音处理
				if consec_cons >= 3:
					# 检查辅音组合
					var three_cons = ""
					if end >= 2:
						three_cons = string.substr(end - 2, 3)

					# 连续3辅音且下个字符是辅音，且不是常见组合
					if consec_cons == 3 and next_char != "" and vowels.find(next_char) < 0:
						if three_cons in CommonConsonantTrigraphs:
							# 常见辅音组合不分割
							pass
						else:
							segments.append(current_segment)
							start = end + 1
							found = true
					# 连续4+辅音强制分割
					elif consec_cons >= 4:
						segments.append(current_segment)
						start = end + 1
						found = true

				# 规则4：连续元音处理
				elif consec_vow >= 2 and next_char != "" and vowels.find(next_char) >= 0:
					# 检查元音组合
					var two_vow = ""
					if end >= 1:
						two_vow = string.substr(end - 1, 2)

					if two_vow in CommonVowelDigraphs:
						# 常见元音组合不分割
						pass
					else:
						segments.append(current_segment)
						start = end + 1
						found = true
				# 连续3+元音强制分割
				elif consec_vow >= 3:
					segments.append(current_segment)
					start = end + 1
					found = true

			if not found:
				end += 1

		# 处理未分割的剩余部分
		if not found:
			segments.append(string.substr(start, n - start))
			break

	# 第二遍：合并短片段
	segments = _merge_short_segments(segments, min_length, max_length)
	return segments

# 合并短片段（保持不变）
static func _merge_short_segments(segments: Array, min_length: int, max_length: int) -> Array:
	if segments.is_empty():
		return []

	var result = []
	var i = 0

	while i < segments.size():
		var current = segments[i]

		if current.length() < min_length and i < segments.size() - 1:
			var next_seg = segments[i + 1]
			var merged = current + next_seg
			if merged.length() <= max_length:
				result.append(merged)
				i += 2
				continue
			else:
				result.append(current)
		elif current.length() == 2 and current in TwoLetterWordsHighFrequency and i < segments.size() - 1:
			var next_seg = segments[i + 1]
			var merged = current + next_seg
			if merged.length() <= max_length:
				result.append(merged)
				i += 2
				continue
			else:
				result.append(current)
		else:
			result.append(current)

		i += 1

	# 递归处理直到没有变化
	if result.size() != segments.size():
		return _merge_short_segments(result, min_length, max_length)

	return result
