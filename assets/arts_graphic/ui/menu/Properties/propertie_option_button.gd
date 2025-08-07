@tool
class_name PropertieOptionButton
extends Propertie

#signal   .option_button.item_selected.connect()

const type: String = "option"

@export var default_option: int = -1
@export var options: PackedStringArray = []

@onready var name_label: Label = $NameLabel
@onready var option_button: OptionButton = $Control/OptionButton
@onready var reset_button: TextureButton = $ResetButtonControl/ResetButton



func _ready() -> void:
	#if not Engine.is_editor_hint():
		#set_ui()
	pass


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		set_ui()


func set_ui() -> void:
	name_label.text = propertie_name
	option_button.selected = default_option

	var _off: bool = not self.visible or propertie_disabled
	option_button.disabled = _off
	#option_button.visible = !_off

	var _use_reset_button: bool = false
	_use_reset_button = option_button.selected != default_option and use_reset_button
	reset_button.visible = _use_reset_button
	reset_button.disabled = !_use_reset_button

	# 填充选项：
	if option_button.get_item_count() == 0 and options.size() > 0:
		for option in options:
			option_button.add_item(option)


func main_connect(callable: Callable, flags: int = 0) -> int:
	return option_button.item_selected.connect(callable, flags)


## 返回当前选中项目的文本
func get_main_value() -> String:
	return option_button.get_item_text(option_button.selected)


## 设置值，不触发信号
func set_main_value(index: int) -> void:
	option_button.select(index)


## 设置值，不触发信号，使用文本
func set_main_value_with_text(text: String) -> void:
	option_button.select(options.find(text))


## 设置选项禁用，使用文本
func set_item_disabled_with_text(text: String, disabled: bool) -> void:
	option_button.set_item_disabled(options.find(text), disabled)


func _on_reset_button_toggled(toggled_on: bool) -> void:
	option_button.selected = default_option
	value_reset.emit()


func _on_option_button_item_selected(index: int) -> void:
	_on_main_signal_trigger()
