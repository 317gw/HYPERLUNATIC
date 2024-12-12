class_name Bullet
extends Node3D

var speed: float
var lifetime: float
var color: Color

var first_frame_fired: bool = true
var need_to_change_colour: bool = true


var bullet_radius: float = 0.25 : # m
	set(value):
		set_radius(value)

func set_albedo(_albedo: Color) -> void:
	pass

func set_radius(_radius) -> void:
	pass
