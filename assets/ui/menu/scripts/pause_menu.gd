extends Control


func _process(_delta):
	if Input.is_action_just_pressed("pause"): # 如果按下退出键
		switch()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	#if self.visible:
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func switch():
	get_tree().paused = not get_tree().paused
	self.visible = not self.visible


func _on_resume_button_pressed():
	switch()


func _on_restart_pressed() -> void:
	switch()
	for child in Global.effects.get_children():
		child.queue_free()
	get_tree().reload_current_scene()


func _on_quit_button_pressed():
	get_tree().quit()
