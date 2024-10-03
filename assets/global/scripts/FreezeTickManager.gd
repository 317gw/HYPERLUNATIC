extends Node


func tick_freeze_short():
	Engine.time_scale = 0.01 # E 0:00:05:0459   instance_set_transform: Condition "!v.is_finite()" is true.
#  <C++ 源文件>      servers/rendering/renderer_scene_cull.cpp:922 @ instance_set_transform()
	await get_tree().create_timer(0.03, true, false, true).timeout
	Engine.time_scale = 1


func tick_freeze_medium():
	Engine.time_scale = 0
	await get_tree().create_timer(0.25, true, false, true).timeout
	Engine.time_scale = 1


func tick_freeze_long():
	Engine.time_scale = 0
	await get_tree().create_timer(0.5, true, false, true).timeout
	Engine.time_scale = 1


func slow_motion_short():
	Engine.time_scale = 0.5
	await get_tree().create_timer(0.5, true, false, true).timeout
	Engine.time_scale = 1
