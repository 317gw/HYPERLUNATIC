extends Control


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"): exit_menu()


func exit_menu() -> void:
	get_viewport().set_input_as_handled()
	queue_free()
