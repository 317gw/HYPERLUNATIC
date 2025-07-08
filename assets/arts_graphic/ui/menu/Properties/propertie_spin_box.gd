@tool
class_name PropertieSpinBox
extends Propertie

signal range_value_changed(value: float)

@export var default_value: float = 0.0

@export var use_num_hint: bool = true
@export var num_hint_begin: float = 0.0
@export var num_hint_end: float = 1.0
@export var num_hint_decimals: int = 2


@onready var name_label: Label = $NameLabel
@onready var spin_box: SpinBox = $Control/SpinBox
@onready var reset_button: TextureButton = $ResetButtonControl/ResetButton



func _ready() -> void:
	if not Engine.is_editor_hint():
		_set_ui()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_set_ui()


func _set_ui() -> void:
	name_label.text = propertie_name
	_set_controls()

	spin_box.value = default_value
	#spin_box.apply()
	spin_box.min_value = num_hint_begin
	spin_box.max_value = num_hint_end
	spin_box.step = pow(0.1, num_hint_decimals)

	var _use_reset_button: bool = false
	_use_reset_button = is_equal_approx(spin_box.value, default_value) and use_reset_button


	reset_button.visible = _use_reset_button
	reset_button.disabled = !_use_reset_button


func _set_controls() -> void:
	spin_box.editable = true
	spin_box.visible = true


func _on_range_value_changed(value: float):
	range_value_changed.emit(value)


func _on_reset_button_toggled(toggled_on: bool) -> void:
	spin_box.value = default_value
