extends Window

var DisplayMode: Dictionary = {
	"Windowed": Window.Mode.MODE_WINDOWED,
	"Fullscreen": Window.Mode.MODE_FULLSCREEN,
	"Exclusive Fullscreen": Window.Mode.MODE_EXCLUSIVE_FULLSCREEN,
}

# 4:3, 5:4, 16:9, 16:10, 21:9, 32:9
var Ratios: Array = ["4:3", "5:4", "16:9", "16:10", "21:9", "32:9"]
var Resolutions: Dictionary = {
	"4:3": { # 1.33333
		"800, 600": {"size": Vector2i(800, 600), "hint": ""},
		"1024, 768": {"size": Vector2i(1024, 768), "hint": ""},
		"1152, 864": {"size": Vector2i(1152, 864), "hint": ""},
		"1280, 960": {"size": Vector2i(1280, 960), "hint": ""},
		"1400, 1050": {"size": Vector2i(1400, 1050), "hint": ""},
		"1600, 1200": {"size": Vector2i(1600, 1200), "hint": ""},
		"2048, 1536": {"size": Vector2i(2048, 1536), "hint": ""},
	},
	"5:4": { # 1.25
		"1280, 1024": {"size": Vector2i(1280, 1024), "hint": ""},
		"2560, 2048": {"size": Vector2i(2560, 2048), "hint": ""},
		"3200, 2560": {"size": Vector2i(3200, 2560), "hint": ""},
	},
	"16:9": { # 1.77777
		"1280, 720": {"size": Vector2i(1280, 720), "hint": "HD"},
		"1366, 768": {"size": Vector2i(1366, 768), "hint": "683:384"},
		"1600, 900": {"size": Vector2i(1600, 900), "hint": ""},
		"1920, 1080": {"size": Vector2i(1920, 1080), "hint": "FHD"},
		"2560, 1440": {"size": Vector2i(2560, 1440), "hint": "2K QHD"},
		"3840, 2160": {"size": Vector2i(3840, 2160), "hint": "4K UHD"},
		"4096, 2304": {"size": Vector2i(4096, 2304), "hint": "4K DCI"},
	},
	"16:10": { # 1.6
		"1280, 800": {"size": Vector2i(1280, 800), "hint": ""},
		"1440, 900": {"size": Vector2i(1440, 900), "hint": ""},
		"1680, 1050": {"size": Vector2i(1680, 1050), "hint": ""},
		"1920, 1200": {"size": Vector2i(1920, 1200), "hint": "WUXGA"},
		"2560, 1600": {"size": Vector2i(2560, 1600), "hint": "WQXGA"},
		"3840, 2400": {"size": Vector2i(3840, 2400), "hint": ""},
	},
	"21:9": { # 2.33333
		"2560, 1080": {"size": Vector2i(2560, 1080), "hint": "64:27"},
		"3440, 1440": {"size": Vector2i(3440, 1440), "hint": "43:18 UWQHD"},
		"3840, 1600": {"size": Vector2i(3840, 1600), "hint": "12:5 4K UltraWide"},
		"5120, 2160": {"size": Vector2i(5120, 2160), "hint": "64:27 5K UltraWide"},
	},
	"32:9": { # 3.55555
		"3840, 1080": {"size": Vector2i(3840, 1080), "hint": "2xFHD"},
		"5120, 1440": {"size": Vector2i(5120, 1440), "hint": "2xQHD"},
	},
}

var custom_resolution: Array = ["-1:-1*", "-1, -1*"]

var Anti_Aliasing_Mode: Dictionary = {

}

var visible_save: bool
var input_map: Array

# 假设 CoreSystem 单例已设置
var config_manager: CoreSystem.ConfigManager = CoreSystem.config_manager
var _compare_config_file: ConfigFile = ConfigFile.new()
var in_setting: bool = false

var window_id: int ## window_id = DisplayServer.SCREEN_OF_MAIN_WINDOW
var main_screen_size: Vector2
var main_screen_closest_ratio: String
var game_window_size: Vector2

#const PROPERTIE = preload("res://assets/arts_graphic/ui/menu/Propertie.tscn")
const PROPERTIE = preload("res://assets/arts_graphic/ui/menu/Properties/menu_propertie.gd")

@onready var main_menus: CanvasLayer = $"../.."
# Field of View

@onready var menu_control: Control = $".."
@onready var option_window_cancel_confirm: ConfirmationDialog = $"../OptionWindowCancelConfirm"
@onready var input_vbc: VBoxContainer = $PanelContainer/VBoxContainer/TabContainer/输入/MarginContainer/VBoxContainer

@onready var resolution_label: Label = %ResolutionLabel


func _ready() -> void:
	# 连接窗口隐藏
	close_requested.connect(hide)
	get_tree().get_root().size_changed.connect(_get_window_and_screen)

	# 处理此设备首次打开这个项目
	#config_manager.set_value("config_setup", "ok!", false)
	entering_the_game()
	initialize_option_control()

	# 初始化输入设置
	set_up_ui_input_map()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		main_menus.switch_menu()


## 进入游戏
func entering_the_game() -> void:
	config_manager.load_config()
	apply_config() # 应用设置

	# 处理此设备首次打开这个项目
	if (not config_manager.has_section("config_setup")
		or not config_manager.has_key("config_setup", "ok!")
		or config_manager.get_value("config_setup", "ok!", null)
		or config_manager.get_value("config_setup", "ok!", false)):
			first_time_entering_the_game()


## 此设备首次打开这个项目
func first_time_entering_the_game() -> void:
	# 其他东西
	config_manager.set_value("config_setup", "ok!", true)


## 重制设置菜单缩放和位置
func reset_option_window() -> void:
	size = size.min(menu_control.size * 0.85)
	size = size.snappedi(50)
	position = (menu_control.get_viewport_rect().size - Vector2(size) )*0.5


## 初始化设置控件
func initialize_option_control() -> void:
	window_id = DisplayServer.SCREEN_OF_MAIN_WINDOW

	# 载入窗口显示模式选项
	display_mode.option_button.clear()
	for i in DisplayMode:
		display_mode.option_button.add_item(i)

	# 载入屏幕比例选项
	var aspect_ratios_ob: OptionButton = aspect_ratios.option_button
	aspect_ratios_ob.clear()
	#aspect_ratios_ob.add_item(custom_resolution[0])
	for ratio in Resolutions:
		aspect_ratios_ob.add_item(ratio)
	##aspect_ratios_ob.item_selected.connect(_on_aspect_ratio_set)
	#aspect_ratios.option_selected.connect(_on_aspect_ratio_set)

	# 全屏默认比例和分辨率
	_get_window_and_screen()
	# 载入分辨率选项
	aspect_ratios.option_button.select(Ratios.find(main_screen_closest_ratio))
	_on_aspect_ratios_option_selected(Ratios.find(main_screen_closest_ratio))


## 获取窗口和屏幕信息
func _get_window_and_screen() -> void:
	window_id = DisplayServer.SCREEN_OF_MAIN_WINDOW
	main_screen_size = Vector2(DisplayServer.screen_get_size(window_id))
	main_screen_closest_ratio = Global.get_closest_aspect_ratio(main_screen_size)
	game_window_size = Vector2(DisplayServer.window_get_size())

	custom_resolution[0] = HL.simplify_ratio(game_window_size.x, game_window_size.y) + "*"
	custom_resolution[1] = str(game_window_size.x) + ", " + str(game_window_size.y) + "*"
	#print(custom_resolution)
	#aspect_ratios.option_button.set_item_text(0, custom_resolution[0])
	#resolutions.option_button.set_item_text(0, custom_resolution[1])
	resolution_label.text = "屏幕 " + main_screen_closest_ratio + " " + str(main_screen_size.x) + "," + str(main_screen_size.y) + "\n"
	resolution_label.text += "窗口 " + HL.simplify_ratio(game_window_size.x, game_window_size.y) + " " + str(game_window_size.x) + "," + str(game_window_size.y)


## 输入设置
func set_up_ui_input_map() -> void:
	input_map = InputMap.get_actions()
	input_map = input_map.filter(func(input_name): return not ("ui_" in input_name or "goat_" in input_name) )
	#prints(input_map)
	#for input_name: StringName in input_map:
		#var propertie = PROPERTIE.instantiate()
		#input_vbc.add_child(propertie)
		#propertie.name = input_name.to_pascal_case()


#func _process(delta: float) -> void:
	#if pause_menu.visible:
		#visible = visible_save
	#else:
		#visible_save = visible
		#visible = false


## 应用配置
func apply_config() -> void:
	# 图形
	_get_window_and_screen()

	var display_mode: String = config_manager.get_value("graphics", "display_mode", "Fullscreen")
	var aspect_ratios: String = config_manager.get_value("graphics", "aspect_ratios", "16:9")
	var resolution: String = config_manager.get_value("graphics", "resolution", "1920, 1200")
	#WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(DisplayMode[display_mode])

	#if not "*" in aspect_ratios:
	var _aspect_ratios: Dictionary = Resolutions[aspect_ratios]
	if _aspect_ratios.has(resolution):
		DisplayServer.window_set_size(_aspect_ratios[resolution]["size"])
	else:
		DisplayServer.window_set_size(Vector2i(1920, 1200))

	reset_option_window()
	DisplayServer.window_set_position((main_screen_size - game_window_size)*0.5)


## 确认配置
func confirm_config() -> void:
	config_manager.save_config()


func config_file_to_instance() -> void:
	config_manager.reset_config()
	config_manager.load_config()
	pass


func _on_about_to_popup() -> void:
	config_file_to_instance()
	in_setting = true
	pass # Replace with function body.


## 关闭设置菜单
func _on_close_requested() -> void:
	load_compare_config(config_manager.config_path)
	for section in config_manager._config_file.get_sections():
		for key in section:
			if _compare_config_file.get_value(section, key) != config_manager._config_file.get_value(section, key):
				show()
				in_setting = true
				option_window_cancel_confirm.popup_centered()
				print("option_window_cancel_confirm.popup_centered()")
				break


## 载入比较用配置
func load_compare_config(path_to_load: String) -> bool:
	if not path_to_load:
		print("_compare not path_to_load")
		return false

	# 确保目标目录存在，load 不会创建目录
	var dir_path = path_to_load.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		print("_compare Config directory '%s' does not exist, attempting to load will likely fail (or be empty)." % dir_path)
		# ConfigFile.load 在目录不存在时似乎不会返回特定错误码，更像 ERR_FILE_NOT_FOUND

	var err = _compare_config_file.load(path_to_load)
	if err == OK:
		print("_compare Config loaded successfully from '%s'." % path_to_load)
		return true
	elif err == ERR_FILE_NOT_FOUND:
		print("_compare Config file '%s' not found. Will use default values provided by get_value()." % path_to_load)
		_compare_config_file.clear() # 确保内存中是空的，而不是上次加载的内容
		return true # 文件不存在是预期情况，不算加载失败
	else: # 其他加载错误
		printerr("_compare Failed to load config file '%s'. Error code: %d" % [path_to_load, err])
		_compare_config_file.clear() # 加载失败，清空内存状态以防部分加载
		return false


## 确认
func _on_confirm_pressed() -> void:
	if in_setting:
		_on_apply_pressed()
	else:
		config_manager.save_config()

## 应用
func _on_apply_pressed() -> void:
	apply_config()
	in_setting = false

## 取消
func _on_cancel_pressed() -> void:
	self.hide()


"""
设置选项的函数 ！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！
"""

## 窗口模式
@onready var display_mode: MenuPropertie = %DisplayMode
func _on_display_mode_option_selected(index: int) -> void:
	config_manager.set_value("graphics", "display_mode", display_mode.option_button.get_item_text(index))


## 比例
@onready var aspect_ratios: MenuPropertie = %AspectRatios
#func _on_aspect_ratio_set(index) -> void:
func _on_aspect_ratios_option_selected(index: int) -> void:
	config_manager.set_value("graphics", "aspect_ratios", aspect_ratios.option_button.get_item_text(index))
	var resolutions_ob: OptionButton = resolutions.option_button
	resolutions_ob.clear()
	#resolutions_ob.add_item(custom_resolution[1])
	#if index > 0:
	var _resolutions: Dictionary = Resolutions[aspect_ratios.option_button.get_item_text(index)]
	for ratio in _resolutions:
		resolutions_ob.add_item(ratio)
	_on_resolutions_option_selected(0)


## 分辨率
@onready var resolutions: MenuPropertie = %Resolutions
func _on_resolutions_option_selected(index: int) -> void:
	#var _aspect_ratio: String = config_manager.get_value("graphics", "aspect_ratios", "16:9")
	config_manager.set_value("graphics", "resolution", resolutions.option_button.get_item_text(index))
	#print(config_manager.get_value("graphics", "resolution", "no"))


## 垂直同步
@onready var vertical_sync: MenuPropertie = %VerticalSync
func _on_vertical_sync_option_selected(index: int) -> void:
	pass # Replace with function body.
