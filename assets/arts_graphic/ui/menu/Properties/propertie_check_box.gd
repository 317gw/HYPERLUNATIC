@tool
class_name PropertieCheckBox
extends Propertie

signal checkbox_toggled(button_pressed: bool)

@export var default_check: bool = false

@onready var name_label: Label = $NameLabel
@onready var check_box: CheckBox = $Control/CheckBox
@onready var reset_button: TextureButton = $ResetButtonControl/ResetButton



func _ready() -> void:
	if not Engine.is_editor_hint():
		_set_ui()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_set_ui()
		#_connect_signals()
	if num_hint_line_edit.visible:
		num_hint_line_edit.text = HL.string_num_pad_decimals(h_slider.value, num_hint_decimals) + num_hint_units


func _set_ui() -> void:
	name_label.text = propertie_name
	_set_controls()


	check_box.button_pressed = default_check

	var _use_reset_button: bool = false
	_use_reset_button = check_box.button_pressed != default_check and use_reset_button

	reset_button.visible = _use_reset_button
	reset_button.disabled = !_use_reset_button


func _set_controls() -> void:
	check_box.disabled = false
	check_box.visible = true


func _on_check_box_toggled(button_pressed: bool):
	checkbox_toggled.emit(button_pressed)


func _on_reset_button_toggled(toggled_on: bool) -> void:
	check_box.button_pressed = default_check
