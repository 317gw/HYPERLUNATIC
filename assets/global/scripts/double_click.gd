extends Node
#class_name DoubleClick

@onready var timer = $Timer
@onready var timer_2 = $Timer2

func Double_Click(event: InputEvent, action: StringName) -> bool:
	if event.is_action_pressed(action):
		if timer.time_left == 0:
			timer.start()
			return false
		else:
			timer.stop()
			return true
	return false
