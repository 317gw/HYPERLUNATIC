@tool
class_name PropertieOptionButton
extends Propertie

signal option_selected(index: int)

@export var default_option: int = -1

@onready var name_label: Label = $NameLabel
@onready var option_button: OptionButton = $Control/OptionButton
@onready var reset_button: TextureButton = $ResetButtonControl/ResetButton



func _ready() -> void:
	if not Engine.is_editor_hint():
		_set_ui()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_set_ui()


func _set_ui() -> void:
	name_label.text = propertie_name
	option_button.selected = default_option

	var _off: bool = not self.visible or propertie_disabled
	option_button.disabled = _off
	#option_button.visible = !_off

	var _use_reset_button: bool = false
	_use_reset_button = option_button.selected != default_option and use_reset_button
	reset_button.visible = _use_reset_button
	reset_button.disabled = !_use_reset_button


func _on_option_button_selected(index: int):
	option_selected.emit(index)


func _on_reset_button_toggled(toggled_on: bool) -> void:
	option_button.selected = default_option
