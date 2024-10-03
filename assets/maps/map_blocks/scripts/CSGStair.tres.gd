# https://github.com/majikayogames/SimpleFPSController
@tool

class_name CSGStair
extends CSGBox3D

@export var num_stairs : int = 10

var _cur_num_stairs = -1
var _cur_size : Vector3


func _process(_delta):
	if _cur_num_stairs != num_stairs or _cur_size != self.size:
		make_stairs()

func make_stairs():
	#if not Engine.is_editor_hint():
		#return

	num_stairs = clampi(num_stairs, 0, 999)

	var stairs_poly = $StairsSubtractCSG # add_fresh_stairs_csg_poly()

	var point_arr : PackedVector2Array = PackedVector2Array()
	var step_height = self.size.y / num_stairs
	var step_width = self.size.x / num_stairs

	if num_stairs == 0:
		# For 0 stairs make a ramp
		# 为 0 个楼梯创建一个斜坡
		point_arr.append(Vector2(self.size.x, self.size.y))
		point_arr.append(Vector2(0, self.size.y))
		point_arr.append(Vector2(0, 0))
	else:
		# Creating the points for the stairs polygon
		# 为楼梯多边形创建点
		for i in range(num_stairs - 1):
			point_arr.append(Vector2(i * step_width, (i + 1) * step_height))
			if i < num_stairs:
				point_arr.append(Vector2((i + 1) * step_width, (i + 1) * step_height))

		# Closing the polygon by adding the last two points
		# 通过添加最后两个点来关闭多边形
		point_arr.append(Vector2(self.size.x - step_width, self.size.y))
		point_arr.append(Vector2(0, self.size.y))

	stairs_poly.polygon = point_arr

	stairs_poly.depth = self.size.z

	stairs_poly.position.z = self.size.z / 2.0
	stairs_poly.position.y = -self.size.y / 2.0
	stairs_poly.position.x = -self.size.x / 2.0

	_cur_num_stairs = num_stairs
	_cur_size = self.size
