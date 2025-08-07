@tool
class_name PropertieCheckBox
extends Propertie

#signal   .check_box.toggled.connect()

const type: String = "bool"

@export var default_check: bool = false

@onready var name_label: Label = $NameLabel
@onready var check_box: CheckBox = $Control/CheckBox
@onready var reset_button: TextureButton = $ResetButtonControl/ResetButton



func _ready() -> void:
	#if not Engine.is_editor_hint():
		#set_ui()
	pass


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		set_ui()
		#_connect_signals()


func set_ui() -> void:
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


func main_connect(callable: Callable, flags: int = 0) -> int:
	return check_box.toggled.connect(callable, flags)


func get_main_value() -> bool:
	return check_box.button_pressed


## 设置值，不触发信号
func set_main_value(value: bool) -> void:
	check_box.set_pressed_no_signal(value)


func _on_reset_button_toggled(toggled_on: bool) -> void:
	check_box.button_pressed = default_check
	value_reset.emit()


func _on_check_box_toggled(toggled_on: bool) -> void:
	_on_main_signal_trigger()
