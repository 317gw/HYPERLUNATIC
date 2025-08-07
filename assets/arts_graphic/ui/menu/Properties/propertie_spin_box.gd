@tool
class_name PropertieSpinBox
extends Propertie

#signal   .spin_box.value_changed.connect()

const type: String = "float"

@export var default_value: float = 0.0

@export var use_num_hint: bool = true
@export var num_hint_begin: float = 0.0
@export var num_hint_end: float = 1.0
@export var num_hint_decimals: int = 2


@onready var name_label: Label = $NameLabel
@onready var spin_box: SpinBox = $Control/SpinBox
@onready var reset_button: TextureButton = $ResetButtonControl/ResetButton



func _ready() -> void:
	#if not Engine.is_editor_hint():
		#set_ui()
	pass


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		set_ui()


func set_option_data() -> void:
	default_value = option_data["config_keys"][current_config_key]["preset"]
	num_hint_begin = option_data["begin"]
	num_hint_end = option_data["end"]
	num_hint_decimals = option_data["decimals"]


func set_ui() -> void:
	name_label.text = propertie_name
	_set_controls()

	#spin_box.value = default_value
	set_main_value(default_value)
	#spin_box.apply()
	spin_box.min_value = num_hint_begin
	spin_box.max_value = num_hint_end
	spin_box.step = pow(0.1, num_hint_decimals)

	var _use_reset_button: bool = false
	_use_reset_button = not is_equal_approx(spin_box.value, default_value) and use_reset_button


	reset_button.visible = _use_reset_button
	reset_button.disabled = !_use_reset_button


func _set_controls() -> void:
	spin_box.editable = true
	spin_box.visible = true


func main_connect(callable: Callable, flags: int = 0) -> int:
	return spin_box.value_changed.connect(callable, flags)


func get_main_value() -> float:
	return spin_box.value


## 设置值，不触发信号
func set_main_value(value: float) -> void:
	#spin_box.value = value
	spin_box.set_value_no_signal(value)

#func set_num_hint(dic: )
			#i["propertie"].num_hint_begin = i["begin"]
			#i["propertie"].num_hint_end = i["end"]
			#i["propertie"].num_hint_decimals = i["decimals"]


func _on_reset_button_toggled(toggled_on: bool) -> void:
	spin_box.value = default_value
	value_reset.emit()


func _on_spin_box_value_changed(value: float) -> void:
	_on_main_signal_trigger()
