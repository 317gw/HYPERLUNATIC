class_name Bullet
extends Node3D

#@export var collision: CollisionShape3D
var speed: float
var lifetime: float
var color: Color = Color.WHITE :
	set(value):
		set_albedo(value)

var bullet_radius: float = 0.25 : # m
	set(value):
		set_radius(value)

var first_frame_fired: bool = true
var need_to_change_colour: bool = true

func set_albedo(_albedo: Color) -> void:
	pass

func set_radius(_radius) -> void:
	pass
