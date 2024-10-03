@tool
extends EditorPlugin

func get_name():
	return "ProtonTrail"

func _enter_tree():
	add_custom_type(
		"ProtonTrail",
		"Node3D",
		preload ("res://addons/proton_trail-master/proton_trail.gd"),
		preload ("res://addons/proton_trail-master/proton_trail.svg")
	)

func _exit_tree():
	remove_custom_type("ProtonTrail")
