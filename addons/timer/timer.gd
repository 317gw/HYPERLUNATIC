@tool

extends EditorPlugin

const main_panel = preload("res://addons/timer/timer.tscn")
const time_file_path = "res://addons/timer/time.txt"
const save_interval : int = 60 # Save interval in seconds

# Nodes
var main_panel_instance : Control
var progress_bar : ProgressBar
var main_button : Button

var time_file : FileAccess

var time : float = 0.0
var save_completed := true

#region Plugin Boilerplate

func _has_main_screen():
	return false


func _get_plugin_name():
	return "Timer Plugin"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Timer", "EditorIcons")

#endregion

func _ready():
	# Place timer in title bar
	var title_bar = EditorInterface.get_base_control().get_child(0).get_child(0)
	main_panel_instance = main_panel.instantiate()
	title_bar.add_child(main_panel_instance)
	title_bar.move_child(main_panel_instance, 1) # Reorder after the explorer menu (Scene Project, etc...)

	# Find essential nodes
	main_button = main_panel_instance # The button is the scene root node
	progress_bar = main_panel_instance.find_child("ProgressBar")

	# Create time file if needed on first run
	if !FileAccess.file_exists(time_file_path):
		_log("Creating time file")
		_save_time()

	# Load last time
	time_file = FileAccess.open(time_file_path, FileAccess.READ)
	if time_file.get_error() != 0:
		_log("Failed to read time from time file")
		time = 0.0
	else:
		time = float(time_file.get_as_text())
		time_file.close()
		_log("Loaded time from time file: " + _get_time_string(int(time)))


func _get_time_string(seconds: int):
	return (
		(str(seconds / 86400) + # Days
		":" if seconds / 86400 > 0 else "") + # Only if days > 0
		str(seconds / 3600 % 24).pad_zeros(2) + # Hours
		":" +
		str(seconds / 60 % 60).pad_zeros(2) + # Minutes
		":" +
		str(seconds % 60).pad_zeros(2) # Seconds
	)


func _save_time():
	time_file = FileAccess.open(time_file_path, FileAccess.WRITE)
	if time_file.get_error() != 0:
		_log("Failed to save time to time file")
	else:
		time_file.store_string(str(round(time)))
		time_file.close()


func _process(delta):
	var paused = main_button.button_pressed
	var last_second = int(time) # Save the second before delta time is added to run code only when the second changes
	time += delta * int(!paused) # Only add to time if not paused
	var current_second = int(time)

	# Save time after every save interval
	if last_second != current_second and current_second % save_interval == 0:
		_save_time()

	# Update timer text
	var time_string = "  " + ("PAUSED: " if paused else "Timer: ") + _get_time_string(current_second) + "  "
	main_button.text = time_string

	# Show progress for current day
	progress_bar.value = current_second % 86400 / 86400.0


# Logging is put into a function to append text before each log message
func _log(message: String):
	print("Timer Plugin: " + message)


func _exit_tree():
	_save_time()
	if main_panel_instance:
		main_panel_instance.queue_free()
