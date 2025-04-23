class_name Bullet
extends Node3D

#@export var collision: CollisionShape3D

var lifetime: float ##
var bullet_mass: float ## 质量
var velocity: Vector3 ##速度
var acceleration: Vector3 ##加速度


var color1: Color = Color.WHITE :
	set(value):
		color1 = value
		set_color(value, color2)

var color2: Color = Color(Color.WHITE, 0.5) :
	set(value):
		color2 = value
		set_color(color1, value)

var bullet_radius: float = 0.25 : # m CollisionShape3D
	set(value):
		bullet_radius = value
		set_radius(value)

#var first_frame_fired: bool = true
#var need_to_change_colour: bool = true

func set_color(_color1: Color, _color2: Color) -> void:
	pass



func set_radius(_radius: float) -> void:
	pass

func set_bullet_scale(_scale: Vector3) -> void:
	pass
