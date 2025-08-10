@tool
class_name PropertieHSlider
extends Propertie

#signal   .h_slider.value_changed.connect()

const type: String = "float"

@export var default_value: float = 0.0

@export var use_num_hint: bool = true
@export var num_hint_begin: float = 0.0
@export var num_hint_end: float = 1.0
@export var num_hint_decimals: int = 2
@export var num_hint_units: String = ""


@onready var name_label: Label = $NameLabel
@onready var h_slider: HSlider = $Control/HSlider
@onready var scale_mark_line: ColorRect = $Control/ScaleMarkLine
@onready var num_hint_line_edit: LineEdit = $NumHintControl/NumHintLineEdit
@onready var reset_button: TextureButton = $ResetButtonControl/ResetButton




func _ready() -> void:
	#if not Engine.is_editor_hint():
		#set_ui()
	pass


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		set_ui()
		#_connect_signals()
	if num_hint_line_edit.visible:
		num_hint_line_edit.text = FormatUtils.string_num_pad_decimals(h_slider.value, num_hint_decimals) + num_hint_units


func set_option_data() -> void:
	default_value = option_data["config_keys"][current_config_key]["preset"]
	num_hint_begin = option_data["begin"]
	num_hint_end = option_data["end"]
	num_hint_decimals = option_data["decimals"]


func set_ui() -> void:
	name_label.text = propertie_name
	_set_controls()

	num_hint_line_edit.visible = use_num_hint
	#if num_hint_line_edit.visible:
	#h_slider.value = default_value
	set_main_value(default_value)
	h_slider.min_value = num_hint_begin
	h_slider.max_value = num_hint_end
	h_slider.step = pow(0.1, num_hint_decimals)

	var _use_reset_button: bool = false
	_use_reset_button = not is_equal_approx(h_slider.value, default_value) and use_reset_button

	reset_button.visible = _use_reset_button
	reset_button.disabled = !_use_reset_button

	scale_mark_line.force_update()


func _set_controls() -> void:
	h_slider.editable = true
	h_slider.visible = true


func main_connect(callable: Callable, flags: int = 0) -> int:
	return h_slider.value_changed.connect(callable, flags)


func get_main_value() -> float:
	return h_slider.value


## 设置值，不触发信号
func set_main_value(value: float) -> void:
	h_slider.set_value_no_signal(value)


func _on_h_slider_value_changed(value: float) -> void:
	if use_num_hint:
		num_hint_line_edit.text = "%d%s" % [value, num_hint_units]
	_on_main_signal_trigger()


func _on_reset_button_toggled(toggled_on: bool) -> void:
	h_slider.value = default_value
	value_reset.emit()


func _on_num_hint_line_edit_editing_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_num_hint_line_edit_text_changed(new_text: String) -> void:
	# 定义允许的基础字符（数字和小数点）
	var allowed_chars = "-0123456789.,"
	# 若有单位，将单位字符加入白名单
	if num_hint_units != "":
		allowed_chars += num_hint_units

	var filtered_text: String = ""
	for char in new_text:
		# 仅保留白名单字符
		if char in allowed_chars:
			# 特殊处理小数点：仅允许出现一次
			if char == "." && filtered_text.count(".") >= 1:
				continue
			if char == "," && filtered_text.count(",") >= 1:
				continue
			filtered_text += char

	# 避免因文本修改触发无限循环
	if new_text != filtered_text:
		num_hint_line_edit.text = filtered_text


func _on_num_hint_line_edit_text_submitted(new_text: String) -> void:
	# 实现文本提交功能：
	var value = new_text.to_float()
	if value != null:
		value = clamp(value, num_hint_begin, num_hint_end)
		h_slider.value = value
