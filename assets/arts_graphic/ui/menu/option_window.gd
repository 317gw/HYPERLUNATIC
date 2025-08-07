# OptionWindow
extends Window


var visible_save: bool
var input_map: Array

var in_setting: bool = false

#const PROPERTIE = preload("res://assets/arts_graphic/ui/menu/Propertie.tscn")
const PROPERTIE = preload("res://assets/arts_graphic/ui/menu/Properties/menu_propertie.gd")

@onready var main_menus: CanvasLayer = $"../.."
# Field of View
@onready var menu_control: Control = $".."
@onready var option_window_cancel_confirm: ConfirmationDialog = $"../OptionWindowCancelConfirm"
#@onready var input_vbc: VBoxContainer = $PanelContainer/VBoxContainer/TabContainer/输入/MarginContainer/VBoxContainer
@onready var tab_container: TabContainer = $PanelContainer/VBoxContainer/TabContainer

@onready var general: ScrollContainer = $PanelContainer/VBoxContainer/TabContainer/General
@onready var in_game: ScrollContainer = $PanelContainer/VBoxContainer/TabContainer/InGame
@onready var graphics: OptionTab = $PanelContainer/VBoxContainer/TabContainer/Graphics
@onready var audio: ScrollContainer = $PanelContainer/VBoxContainer/TabContainer/Audio
@onready var controls: ScrollContainer = $PanelContainer/VBoxContainer/TabContainer/Controls
@onready var mod: ScrollContainer = $PanelContainer/VBoxContainer/TabContainer/Mod
@onready var misc: ScrollContainer = $PanelContainer/VBoxContainer/TabContainer/Misc



func _ready() -> void:
	# 连接窗口隐藏
	close_requested.connect(hide)
	get_tree().get_root().size_changed.connect(graphics._get_window_and_screen)

	set_up_ui_input_map() # 初始化输入设置
	update_tab_titles() # 初始设置标题

	# 监听语言变更信号（需自行实现信号发射）
	#GlobalSettings.connect("language_changed", update_tab_titles)
func update_tab_titles():
	TranslationServer.set_locale("zh_CN")
	for tab_idx in range(tab_container.get_tab_count()):
		var node = tab_container.get_tab_control(tab_idx)
		var display_name = TranslationServer.tr(node.name)
		tab_container.set_tab_title(tab_idx, display_name)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		main_menus.switch_menu()


#func _process(delta: float) -> void:
	#if pause_menu.visible:
		#visible = visible_save
	#else:
		#visible_save = visible
		#visible = false


## 重制设置菜单缩放和位置
func reset_option_window() -> void:
	size = size.min(menu_control.size * 0.85)
	size = size.snappedi(50)
	position = (menu_control.get_viewport_rect().size - Vector2(size) )*0.5


## 输入设置
func set_up_ui_input_map() -> void:
	input_map = InputMap.get_actions()
	input_map = input_map.filter(func(input_name):
		return not ("ui_" in input_name or "goat_" in input_name) )
	#prints(input_map)
	#for input_name: StringName in input_map:
		#var propertie = PROPERTIE.instantiate()
		#input_vbc.add_child(propertie)
		#propertie.name = input_name.to_pascal_case()


## 应用所有设置
func apply_config(apply_all: bool = false, reset_ui: bool = false) -> void:
	graphics.apply_config(apply_all, reset_ui)
	reset_option_window()


func _on_about_to_popup() -> void:
	SettingsConfigManager.config_file_to_instance()
	in_setting = true
	pass # Replace with function body.


## 关闭设置菜单
func _on_close_requested() -> void:
	SettingsConfigManager.load_compare_config(CoreSystem.config_manager.config_path)
	for section in CoreSystem.config_manager._config_file.get_sections():
		for key in section:
			if SettingsConfigManager._compare_config_file.get_value(section, key) != CoreSystem.config_manager._config_file.get_value(section, key):
				show()
				in_setting = true
				option_window_cancel_confirm.popup_centered()
				print("option_window_cancel_confirm.popup_centered()")
				break


## 确认
func _on_confirm_pressed() -> void:
	if in_setting:
		_on_apply_pressed()
	else:
		CoreSystem.config_manager.save_config()


## 应用
func _on_apply_pressed() -> void:
	apply_config(SettingsConfigManager.preset_config)
	in_setting = false


## 取消
func _on_cancel_pressed() -> void:
	self.hide()
