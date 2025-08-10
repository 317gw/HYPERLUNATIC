class_name EarthAstronomyBasic
extends Node

"""
根据经纬度和时间算出这天的参考性质的紫外线、温度、湿度、气压、日出日落时间
时间以一年为周期，每年没有数据差异
地理无关，不使用真实采集的数据

维度 latitude +-90度
经度 longitude +-180度
海拔 elevation 米
时间 {"year": int, "month": int, "day": int, "hour": int, "minute": int, "second": float}
"""

# 太阳计算相关常数
const SUN_DECLINATION_CONST: float = 23.45
const SOLAR_NOON_CONST: float = 12.0
const DAYS_IN_YEAR: float = 365.0

# 环境基础值
const BASE_SEA_LEVEL_PRESSURE: float = 1013.25  # hPa (标准大气压)
const BASE_TEMP: float = 25.0         # 赤道年平均温度 (摄氏度)
const BASE_HUMIDITY: float = 60.0     # 平均湿度 (%)
const BASE_UV: float = 5.0            # 平均紫外线指数

# 限制
const HUMIDITY_MIN: float = 10
const HUMIDITY_MAX: float = 100
const PRESSURE_MIN: float = 300.0     # 最低气压 (高海拔)
const PRESSURE_MAX: float = 1080.0    # 最高气压 (低海拔)

#godot4.4
#制作时间和角度解析函数
#角度输入"+40.33.30"、"40.33.30"、"-111.49.1"解析成float
#角度解析函数只解析 度分秒 格式的角度，前缀+或没有是为整数，-为正数，不用管定义域
#时间输入"2024/6/2/21:01:35"解析成字典{"year": int, "month": int, "day": int, "hour": int, "minute": int, "second": float} 只为正数
#这两个解析函数输入的非数字分隔符的作用都一样",.:;/，。；："等都是分隔符，输入都是String

func _ready():

#region 示例使用
	test(parse_latitude("40 33 31"), parse_longitude("111 49 1"), 1036, ParseUtils.parse_date("2025 6 2 22 15 35"))#和林格尔
	"""
	和林格尔这天这时天气预报
	日出 05:04
	日落 19:57
	紫外线 4级
	温度 14° 最低5° 最高16°
	湿度 29%
	气压 875百帕
	云量 6%
	"""
	#var date1 = {"year": 2023, "month": 6, "day": 21, "hour": 12, "minute": 0, "second": float}
	#test(40, -74, 10, date1)# 纽约
#endregion


## 获取一年中的第几天 (1-365)
func day_of_year(month: int, day: int) -> int:
	var days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var doy = 0
	for i in range(month - 1):
		doy += days_in_month[i]
	doy += day
	return doy


## 计算太阳赤纬 (季节变化)
func solar_declination(doy: int) -> float:
	return deg_to_rad(SUN_DECLINATION_CONST * sin(deg_to_rad(360.0 * float(doy - 81) / DAYS_IN_YEAR)))


## 计算日出日落时间
func calculate_sun_times(latitude: float, longitude: float, doy: int) -> Dictionary:
	assert(abs(latitude) <= 90.0, "纬度超出有效范围（-90 ≤ latitude ≤ 90）")
	assert(abs(longitude) <= 180.0, "经度超出有效范围（-180 ≤ longitude ≤ 180）")
	assert(1 <= doy and doy <= 365, "年积日应在1-365之间")

	var lat_rad = deg_to_rad(latitude)
	var dec = solar_declination(doy)

	# 计算时角
	var hour_angle = acos(-tan(lat_rad) * tan(dec))

	# 转换为小时
	var sunrise = SOLAR_NOON_CONST - rad_to_deg(hour_angle) / 15.0
	var sunset = SOLAR_NOON_CONST + rad_to_deg(hour_angle) / 15.0

	# 经度修正 (每15度经度对应1小时时差)
	#var longitude_offset = longitude / 15.0
	#sunrise += longitude_offset
	#sunset += longitude_offset

	# 规范化时间 (0-24)
	sunrise = wrapf(sunrise, 0.0, 24.0)
	sunset = wrapf(sunset, 0.0, 24.0)

	return {
		"sunrise": sunrise,
		"sunset": sunset
	}


## 计算云层覆盖率 (基于纬度和季节)
func calculate_cloud_cover(latitude: float, doy: int) -> float:
	#var lat_factor = 1.0 - abs(sin(2.0 * deg_to_rad(latitude))) # 纬度影响：赤道和高纬度云多，副热带云少
	#var season_factor = 0.7 + 0.3 * cos(2.0 * PI * (doy - 172) / DAYS_IN_YEAR) # 季节影响：夏季云多，冬季云少
	#var cloud_cover = 40.0 + 40.0 * lat_factor * season_factor # 基础云量 (40%-80%)
	#return clamp(cloud_cover, 0, 100)
	var base_cloud = 15.0  # 基础云量
	var season = cos(2 * PI * (doy - 172) / DAYS_IN_YEAR)
	return clamp(base_cloud + 5.0 * season, 5.0, 30.0)


func calculate_earth_temperature_basic(latitude: float, doy: int) -> float:
	return (BASE_TEMP - 0.6 * abs(latitude)) + 0.4 * latitude * cos(2 * PI * (doy - day_of_year(7, 23)) / DAYS_IN_YEAR)



## 获取每日数据
func get_daily_data(latitude: float, longitude: float, elevation: float, date: Dictionary) -> Dictionary:
	assert(abs(latitude) <= 90.0, "纬度超出有效范围")
	assert(abs(longitude) <= 180.0, "经度超出有效范围")
	assert(1 <= date["month"] and date["month"] <= 12, "月份应在1-12之间")
	assert(1 <= date["day"] and date["day"] <= 31, "日期应在1-31之间")

	var doy = day_of_year(date["month"], date["day"])
	var sun_times = calculate_sun_times(latitude, longitude, doy)

	# 计算云层覆盖率
	var cloud_cover = calculate_cloud_cover(latitude, doy)

	# 季节因子 (基于一年中的日期)
	#var season = sin(2 * PI * (doy - 80) / DAYS_IN_YEAR)
	#var season = sin(2 * PI * (doy - 172) / DAYS_IN_YEAR)  # 夏季峰值
	var season = cos(2 * PI * (doy - day_of_year(7, 23)) / DAYS_IN_YEAR) * sign(latitude)


	# 纬度因子
	var lat_factor = cos(deg_to_rad(latitude))

	# 计算温度 (基于季节和纬度)
	#var temperature = BASE_TEMP - 0.5 * abs(latitude) + 15.0 * season

	var temperature = 25.0
	temperature -= 0.4 * (1.0 - lat_factor) # 维度
	temperature += 12.0 * season # 季节
	temperature -= elevation * 0.006 # 海拔对温度的影响


	# 计算湿度 (与温度负相关)
	#var humidity = BASE_HUMIDITY - 0.5 * (temperature - BASE_TEMP) - 0.1 * abs(latitude)
	#var humidity = BASE_HUMIDITY - 0.7 * (temperature - BASE_TEMP)
	#humidity += 20.0 * season * lat_factor
	#humidity -= elevation * 0.001 # 海拔对湿度的影响 (高海拔更干燥)
	#humidity += cloud_cover * 0.2 # 云层对湿度的影响 (云多湿度高)

	#var humidity = 75.0 - 0.8 * (temperature - 20.0)
	#humidity -= 15.0 * season
	#humidity -= elevation * 0.0008
	#humidity += cloud_cover * 0.15

	var humidity = 60.0 - 0.8 * (temperature - 15.0)
	humidity -= 15.0 * season
	humidity -= elevation * 0.001     # 海拔干燥效应
	humidity += cloud_cover * 0.2     # 云量影响

	# 增加凝结效应（当温度<5度时湿度自动升高）
	if temperature < 5.0:
		humidity += (5.0 - temperature) * 3.0  # 每低于5度1度，湿度+3%
	humidity = clamp(humidity, HUMIDITY_MIN, HUMIDITY_MAX)

	# 计算气压 (与海拔相关 - 国际标准大气压公式)
	var pressure = BASE_SEA_LEVEL_PRESSURE * pow(1.0 - elevation / 44330.0, 5.255)
	pressure -= (1.0 - lat_factor) * 35.0
	pressure = clamp(pressure, PRESSURE_MIN, PRESSURE_MAX)

	# 计算紫外线指数 (基于太阳高度)
	var solar_noon = (sun_times["sunrise"] + sun_times["sunset"]) / 2.0
	var max_sun_angle = max_solar_angle(latitude, doy)
	var uv_index = BASE_UV + 4.0 * (max_sun_angle / 90.0) * (1.0 + 0.5 * season) # 基础紫外线
	uv_index *= 1.0 + 0.12 * (elevation / 1000.0) # 海拔影响 (每1000米增加12%)
	uv_index *= 1.0 - (cloud_cover / 100.0) * 0.7 # 云层影响 (减少紫外线)
	uv_index = clamp(uv_index, 0.0, 12.0)

	return {
		"sunrise": sun_times["sunrise"],
		"sunset": sun_times["sunset"],
		"uv_index": uv_index,
		"temperature": temperature,
		"humidity": humidity,
		"pressure": pressure,
		"cloud_cover": cloud_cover
	}


## 获取当前天气
func get_current_weather(latitude: float, longitude: float, elevation: float, date: Dictionary) -> Dictionary:
	assert(abs(latitude) <= 90.0, "纬度超出有效范围")
	assert(abs(longitude) <= 180.0, "经度超出有效范围")
	assert(0 <= date["hour"] and date["hour"] < 24, "小时应在0-23之间")
	assert(0 <= date["minute"] and date["minute"] < 60, "分钟应在0-59之间")

	var daily_data = get_daily_data(latitude, longitude, elevation, date)
	var time_of_day: float = date["hour"] + date["minute"] / 60.0 + date["second"] / 3600.0
	var doy = day_of_year(date["month"], date["day"])

	# 计算当前太阳高度角
	var sun_angle = current_solar_angle(latitude, longitude, doy, time_of_day)

	# 调整紫外线指数 (基于当前太阳高度和云层)
	var uv_index = daily_data["uv_index"] * clamp(sun_angle / 90.0, 0.0, 1.0)

	# 调整温度 (日变化)
	#var solar_noon = (daily_data["sunrise"] + daily_data["sunset"]) / 2.0
	# 转换为太阳时（用于温度变化计算）
	var solar_noon = (daily_data["sunrise"] + daily_data["sunset"]) / 2.0
	var time_solar = wrapf(time_of_day + longitude/15.0, 0.0, 24.0)

	#var temp_variation = 10.0 * cos(PI * (time_of_day - solar_noon - 2.0) / 12.0) # 2点最低 14点最高
	#var temperature = daily_data["temperature"] + temp_variation
	var temp_variation = 8.0 * sin(2 * PI * (time_solar - 6.0) / 24.0)
	var temperature = daily_data["temperature"] + temp_variation

	# 调整湿度
	# var humidity = daily_data["humidity"] - 0.5 * (temperature - daily_data["temperature"])
	var now_diurnal_coeff: float = diurnal_coeff(time_of_day, daily_data["sunrise"], daily_data["sunset"])
	var night_factor = 1.2 * (1.0 - now_diurnal_coeff) # 夜间湿度提高20%
	var humidity = daily_data["humidity"] * night_factor - 0.5 * (temperature - daily_data["temperature"])
	var dew_point = daily_data["temperature"] - (100 - daily_data["humidity"])/5.0 + 2.0 # 露点效应（当温度接近露点时饱和）
	var dew_effect = clampf((dew_point - temperature) * 20.0, 0.0, 100.0 - humidity) # 当温度低于露点时强制饱和
	humidity = min(humidity + dew_effect, 100.0)
	humidity = clamp(humidity, HUMIDITY_MIN, HUMIDITY_MAX) # 限制

	# 气压日变化较小，保持基本不变
	var pressure = daily_data["pressure"] + 3.0 * sin(2 * PI * (time_of_day - 3.0) / 24.0)

	return {
		"uv_index": uv_index,
		"temperature": temperature,
		"humidity": humidity,
		"pressure": pressure,
		"sunrise": daily_data["sunrise"],
		"sunset": daily_data["sunset"],
		"cloud_cover": daily_data["cloud_cover"]
	}


## 计算最大太阳高度角
func max_solar_angle(latitude: float, doy: int) -> float:
	assert(abs(latitude) <= 90.0, "纬度超出有效范围")
	assert(1 <= doy and doy <= 365, "年积日应在1-365之间")

	var lat_rad = deg_to_rad(latitude)
	var dec = solar_declination(doy)
	return 90 - rad_to_deg(abs(lat_rad - dec))


## 计算当前太阳高度角
func current_solar_angle(latitude: float, longitude: float, doy: int, time: float) -> float:
	var lat_rad = deg_to_rad(latitude)
	var dec = solar_declination(doy)

	# 计算太阳时角
	var solar_noon = SOLAR_NOON_CONST + longitude / 15.0
	var hour_angle = deg_to_rad(15.0 * (time - solar_noon))
	#var hour_angle = deg_to_rad(15.0 * (time_solar - 12.0))

	# 计算太阳高度角
	var sin_alt = sin(lat_rad) * sin(dec) + cos(lat_rad) * cos(dec) * cos(hour_angle)
	var altitude = rad_to_deg(asin(sin_alt))

	return max(altitude, 0)  # 确保非负


## 格式化时间 (小时.小数 -> 小时:分钟)
func format_time(time: float) -> String:
	var hour = int(time)
	var minute = int((time - hour) * 60)
	return "%02d:%02d" % [hour, minute]


## 维度湿度分布 0~1
#func latitude_humidity(latitude: float) -> float:
	## 核心函数（双峰叠加）
	#var humidity: float = (
		#0.7 * MathUtils.gaussian(abs(latitude), 0, 25) + # 赤道峰 (σ=25°)
		#0.3 * MathUtils.gaussian(abs(latitude), 60, 15) - # 中纬峰 (σ=15°)
		#0.15 * MathUtils.gaussian(abs(latitude), 30, 10) # 副热带干谷 (σ=10°)
	#)
#
	#humidity *= (1 - abs(latitude)/200)
#
	#return clampf(humidity, 0.0, 1.0)


## 白天黑夜系数，白天为1
func diurnal_coeff(hour: float, sunrise: float, sunset: float, smooth_half_range: float = 1.0) -> float:
	return smoothstep(sunrise - smooth_half_range, sunrise + smooth_half_range, hour) * smoothstep(sunset + smooth_half_range, sunset - smooth_half_range, hour)


func test(latitude: float, longitude: float, elevation: float, date: Dictionary) -> void:
	print("")
	print("输入:")
	print("维度：", latitude)
	print("经度：", longitude)
	print("海拔：", elevation)
	print("日期：", date)

	var daily_data = get_daily_data(latitude, longitude, elevation, date)
	print("")
	print("当天平均天气:")
	print("日出: ", format_time(daily_data["sunrise"]))
	print("日落: ", format_time(daily_data["sunset"]))
	print("紫外线指数: ", daily_data["uv_index"])
	print("温度: ", daily_data["temperature"], "°C")
	print("湿度: ", daily_data["humidity"], "%")
	print("气压: ", daily_data["pressure"], "hPa")
	print("云层覆盖率: ", daily_data["cloud_cover"], "%")

	var current_weather = get_current_weather(latitude, longitude, elevation, date)
	print("")
	print("现在天气:")
	print("紫外线: ", current_weather["uv_index"])
	print("温度: ", current_weather["temperature"], "°C")
	print("湿度: ", current_weather["humidity"], "%")
	print("气压: ", current_weather["pressure"], "hPa")
	print("云层覆盖率: ", current_weather["cloud_cover"], "%")


## 解析 度分秒 格式角度
func parse_latitude(latitude_str: String) -> float:
	var _latitude: float = ParseUtils.parse_degrees_minutes_seconds(latitude_str)
	return clampf(_latitude, -90.0, 90.0)


func parse_longitude(longitude_str: String) -> float:
	var _longitude: float = ParseUtils.parse_degrees_minutes_seconds(longitude_str)
	return clampf(_longitude, -180.0, 180.0)

# ParseUtils.parse_date()

"""
和林格尔这天这时天气预报
日出 05:04
日落 19:57
紫外线 4级
温度 14° 最低5° 最高16°
湿度 29%
气压 875百帕
云量 6%

脚本算法或者参数有问题
这是测试结果：
输入:
维度：40.5586111111111
经度：111.816944444444
海拔：1036.0
日期：{ "year": 2025, "month": 6, "day": 2, "hour": 22, "minute": 15, "second": 35.0 }

当天平均天气:
日出: 04:38
日落: 19:21
紫外线指数: 6.18175845727532
温度: -1.81268038475282°C
湿度: 100.0%
气压: 886.435632183965hPa
云层覆盖率: 40.4721172727294%

现在天气:
紫外线: 3.44386406358446
温度: -2.41073109215898°C
湿度: 100.0%
气压: 883.597305447169hPa
云层覆盖率: 40.4721172727294%

"""
