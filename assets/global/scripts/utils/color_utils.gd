class_name ColorUtils
extends NAMESPACE




static func rainbow_color_custom(time: float, speed: float = HL.GOLDEN_RATIO, saturation: float = 1.0, value: float = 1.0) -> Color:
	var hue: float = fmod(time, 1.0) # 计算色相 (0-1范围)，基于帧数和速度
	var rainbow_color := Color.from_hsv(hue, saturation, value) # 使用HSV颜色模型创建颜色
	return rainbow_color


static func rainbow_color_real_time(speed: float = HL.GOLDEN_RATIO, saturation: float = 1.0, value: float = 1.0) -> Color:
	var time = Time.get_ticks_msec() / 10000.0  # 获取秒数
	var hue = fmod(time * speed, 1.0)
	return Color.from_hsv(hue, saturation, value)
