extends Control


func _play() -> void:
	get_tree().change_scene_to_file("res://levels/level_001.tscn")


func _quit() -> void:
	get_tree().quit()
