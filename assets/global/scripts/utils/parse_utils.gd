class_name ParseUtils
extends NAMESPACE


## 解析 度分秒 格式角度
## 不限制范围
static func parse_degrees_minutes_seconds(angle_str: String) -> float:
	# 处理符号并移除前缀符号
	var sign = 1.0
	var clean_str = angle_str.strip_edges()
	if clean_str.begins_with("-"):
		sign = -1.0
		clean_str = clean_str.substr(1)
	elif clean_str.begins_with("+"):
		clean_str = clean_str.substr(1)

	# 替换所有分隔符
	for sep in clean_str:
		if not sep in HL.Digits:
			clean_str = clean_str.replace(sep, ".")

	# 提取数字部分
	var parts = clean_str.split(".", false)

	var degrees: float = 0.0
	var minutes: float = 0.0
	var seconds: float = 0.0

	if parts.size() > 0: degrees = float(parts[0])
	if parts.size() > 1: minutes = float(parts[1])
	if parts.size() > 2: seconds = float(parts[2])

	# 计算最终角度（度）
	return sign * (degrees + minutes/60.0 + seconds/3600.0)


## 解析 年月日时分秒 格式时间到 {"year": int, "month": int, "day": int, "hour": int, "minute": int, "second": float}
## 不限制范围
static func parse_date(time_str: String) -> Dictionary:
	# 替换所有分隔符
	var clean_str = time_str.strip_edges()
	for sep in clean_str:
		if not sep in HL.Digits:
			clean_str = clean_str.replace(sep, ".")

	# 分割成数字部分
	var parts = clean_str.split(".", false)

	var year: int = 0
	var month: int = 0
	var day: int = 0
	var hour: int = 0
	var minute: int = 0
	var second: float = 0.0

	if parts.size() > 0: year = int(parts[0])
	if parts.size() > 1: month = int(parts[1])
	if parts.size() > 2: day = int(parts[2])
	if parts.size() > 3: hour = int(parts[3])
	if parts.size() > 4: minute = int(parts[4])
	if parts.size() > 5: second = float(parts[5])

	# 解析为数值
	return {
		"year": year,
		"month": month,
		"day": day,
		"hour": hour,
		"minute": minute,
		"second": second
	}
