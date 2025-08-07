class_name Propertie
extends HBoxContainer

signal value_reset()

const font_color_use: Color = Color.WHITE
const font_color_disabled: Color = Color.GRAY

@export var propertie_name: String = "Name"
@export var propertie_disabled: bool = false:
	set(v):
		propertie_disabled = v
		set_propertie_disabled(v)
@export var use_reset_button: bool = true
@export var auto_set_config_value: bool = true

var current_config_key: String ## 当前的用在配置文件的键
var option_data: Dictionary ## 选项的数据
var option_tab: OptionTab ## 所属的选项卡


func main_connect(callable: Callable, flags: int = 0) -> int:
	return -1


func set_option_data() -> void:
	pass


## 返回当前选中项目的文本
func get_main_value():
	pass


## 设置值，不触发信号
#func set_main_value():
	#pass


func enable() -> void:
	pass


func disabled() -> void:
	pass


func set_propertie_disabled(disabled: bool) -> void:
	if disabled:
		disabled()
	else:
		enable()


func _on_main_signal_trigger() -> void:
	if auto_set_config_value:
		set_config_value()


func set_config_value() -> void:
	CoreSystem.config_manager.set_value(option_data["section"], current_config_key, get_main_value())
	option_tab.prepare_apply_arr.append(option_data)
	option_tab.prepare_apply_dic.append({"dic": option_data, "config_key": current_config_key})
