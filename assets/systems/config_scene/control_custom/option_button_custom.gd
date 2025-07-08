extends HBoxContainer
class_name OptionButtonCustom


@export var options: Array
@export var option_index: int
@export var option_loop: bool

var _left_button: Button
var _right_button: Button
var _center_button: Button

signal value_changed(value: Variant)


func _init() -> void:
	_build_node_structure()


func _ready() -> void:
	_center_button.focus_neighbor_left = _center_button.get_path()
	_center_button.focus_neighbor_right = _center_button.get_path()

	if option_loop:
		_center_button.pressed.connect(_on_right_button_pressed)
		_center_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		_center_button.disabled = true
		_center_button.add_theme_color_override("font_disabled_color", Color.WHITE)

	_on_option_changed(option_index)


func _on_option_changed(index: int) -> void:
	if options.is_empty(): return

	var option_size: int = options.size()
	var maximum_index: int = option_size - 1

	option_index = wrapi(index, 0, option_size)\
		if option_loop else clampi(index, 0, maximum_index)

	if not option_loop:
		_left_button.disabled = option_index == 0
		_right_button.disabled = option_index == maximum_index
		_left_button.mouse_default_cursor_shape = Control.CURSOR_ARROW\
			if option_index == 0 else Control.CURSOR_POINTING_HAND
		_right_button.mouse_default_cursor_shape = Control.CURSOR_ARROW\
			if option_index == maximum_index else Control.CURSOR_POINTING_HAND

	var choosed_option: Variant = options[option_index]
	_center_button.text = str(choosed_option)
	value_changed.emit(choosed_option)


func _on_left_button_pressed() -> void:
	_on_option_changed(option_index - 1)


func _on_right_button_pressed() -> void:
	_on_option_changed(option_index + 1)


func _on_center_button_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_left"):
		_on_left_button_pressed()
	if event.is_action_pressed(&"ui_right"):
		_on_right_button_pressed()


func _build_node_structure() -> void:
	var sample_button: Button = Button.new()
	sample_button.custom_minimum_size.x = 72.0
	sample_button.focus_mode = Control.FOCUS_NONE
	sample_button.mouse_filter = Control.MOUSE_FILTER_PASS
	sample_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_left_button = sample_button.duplicate()
	_right_button = sample_button.duplicate()
	sample_button.queue_free()

	_left_button.text = "<"
	_left_button.pressed.connect(_on_left_button_pressed)

	_right_button.text = ">"
	_right_button.pressed.connect(_on_right_button_pressed)

	_center_button = Button.new()
	_center_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center_button.mouse_filter = Control.MOUSE_FILTER_PASS
	_center_button.gui_input.connect(_on_center_button_input)

	add_child(_left_button)
	add_child(_center_button)
	add_child(_right_button)
