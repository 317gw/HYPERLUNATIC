extends OptionTab

@onready var display_mode: PropertieOptionButton = $MarginContainer/VBoxContainer/DisplayMode
@onready var resolution_mode: PropertieOptionButton = $MarginContainer/VBoxContainer/ResolutionMode
@onready var aspect_ratios: PropertieOptionButton = $MarginContainer/VBoxContainer/AspectRatios
@onready var resolutions: PropertieOptionButton = $MarginContainer/VBoxContainer/Resolutions

@onready var vertical_sync: PropertieOptionButton = $MarginContainer/VBoxContainer/VerticalSync
@onready var fov: PropertieSpinBox = $MarginContainer/VBoxContainer/FOV
@onready var exposure: PropertieHSlider = $MarginContainer/VBoxContainer/Exposure

@onready var anisotropic_filtering: PropertieOptionButton = $MarginContainer/VBoxContainer/AnisotropicFiltering
@onready var msaa_2d: PropertieOptionButton = $MarginContainer/VBoxContainer/MSAA2D
@onready var msaa_3d: PropertieOptionButton = $MarginContainer/VBoxContainer/MSAA3D
@onready var ssaa: PropertieOptionButton = $MarginContainer/VBoxContainer/SSAA
@onready var taa: PropertieCheckBox = $MarginContainer/VBoxContainer/TAA
@onready var ssr: PropertieSpinBox = $MarginContainer/VBoxContainer/SSR
@onready var ssao: PropertieCheckBox = $MarginContainer/VBoxContainer/SSAO
@onready var ssil: PropertieCheckBox = $MarginContainer/VBoxContainer/SSIL
@onready var glow: PropertieCheckBox = $MarginContainer/VBoxContainer/Glow


@onready var Display_Mode_Data: Dictionary = {
	"type": "option",
	"func": DisplayServer.window_set_mode,
	"propertie": display_mode,
	"section": GRAPHICS,
	"config_keys": {
		DISPLAY_MODE: {"preset": "Fullscreen"},
	},
	"items": {
		"Windowed": {"set": Window.Mode.MODE_WINDOWED, "hint": ""},
		"Fullscreen": {"set": Window.Mode.MODE_FULLSCREEN, "hint": ""},
		"Exclusive Fullscreen": {"set": Window.Mode.MODE_EXCLUSIVE_FULLSCREEN, "hint": ""},
	},
}

@onready var Resolution_Mode_Data: Dictionary = {
	"type": "option",
	"func": null,
	"propertie": resolution_mode,
	"section": GRAPHICS,
	"config_keys": {
		FULLSCREEN_RESOLUTION_MODE: {"preset": "Native"},
		WINDOWED_RESOLUTION_MODE: {"preset": "Default"},
	},
	"items": {
		"Native": {"set": null, "hint": "Fullscreen or Exclusive Fullscreen"},
		"Custom": {"set": null, "hint": "Windowed"},
		"Default": {"set": null, "hint": "Any"},
	}
}

@onready var Aspect_Ratios_Data: Dictionary = {
	"type": "option",
	"func": null,
	"propertie": aspect_ratios,
	"section": GRAPHICS,
	"config_keys": {
		FULLSCREEN_DEFAULT_ASPECT_RATIOS: {"preset": MATCHING_NATIVE},
		WINDOWED_DEFAULT_ASPECT_RATIOS: {"preset": MATCHING_NATIVE_75},
	},
	"items": {
		"2:1": {"set": null, "hint": ""},
		"4:3": {"set": null, "hint": ""},
		"5:4": {"set": null, "hint": ""},
		"16:9": {"set": null, "hint": ""},
		"16:10": {"set": null, "hint": ""},
		"21:9": {"set": null, "hint": ""},
		"21:9 Precise": {"set": null, "hint": ""},
		"32:9": {"set": null, "hint": ""},
		#MATCHING_NATIVE: {"set": null, "hint": ""},
		#MATCHING_NATIVE_75: {"set": null, "hint": ""},
	},
}

@onready var Resolutions_Data: Dictionary = {
	"type": "option",
	"func": null,
	"propertie": resolutions,
	"section": GRAPHICS,
	"config_keys": {
		FULLSCREEN_DEFAULT_RESOLUTIONS: {"preset": MATCHING_NATIVE},
		WINDOWED_DEFAULT_RESOLUTIONS: {"preset": MATCHING_NATIVE_75},
		WINDOWED_CUSTOM_RESOLUTIONS: {"preset": MATCHING_NATIVE_75},
	},
	"items": Resolutions,
}

# native custom NATIVE CUSTOM
# 2:1, 4:3, 5:4, 16:9, 16:10, 21:9, 21:9 Precise, 32:9
var Ratios: Array = ["2:1", "4:3", "5:4", "16:9", "16:10", "21:9", "21:9 Precise", "32:9"]
var Resolutions: Dictionary = {
	"2:1": { # 2.0
		"640, 320": {"size": Vector2i(640, 320), "hint": ""},
		"960, 480": {"size": Vector2i(960, 480), "hint": ""},
		"1280, 640": {"size": Vector2i(1280, 640), "hint": ""},
		"1920, 960": {"size": Vector2i(1920, 960), "hint": ""},
		"2560, 1280": {"size": Vector2i(2560, 1280), "hint": ""},
		"3840, 1920": {"size": Vector2i(3840, 1920), "hint": ""},
		"4096, 2048": {"size": Vector2i(4096, 2048), "hint": ""},
	},
	"4:3": { # 1.333
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
	"16:9": { # 1.777）
		"640, 360": {"size": Vector2i(640, 360), "hint": "nHD"},
		"854, 480": {"size": Vector2i(854, 480), "hint": "FWVGA 427:240"},
		"960, 540": {"size": Vector2i(960, 540), "hint": "qHD"},
		"1024, 576": {"size": Vector2i(1024, 576), "hint": "WSVGA"},
		"1280, 720": {"size": Vector2i(1280, 720), "hint": "HD"},
		"1366, 768": {"size": Vector2i(1366, 768), "hint": "FWXGA 683:384"},
		"1600, 900": {"size": Vector2i(1600, 900), "hint": "HD+"},
		"1920, 1080": {"size": Vector2i(1920, 1080), "hint": "FHD"},
		"2560, 1440": {"size": Vector2i(2560, 1440), "hint": "2K QHD"},
		"3840, 2160": {"size": Vector2i(3840, 2160), "hint": "4K UHD"},
		"4096, 2304": {"size": Vector2i(4096, 2304), "hint": "4K DCI"},
		"5120, 2880": {"size": Vector2i(5120, 2880), "hint": "5K"},
	},
	"16:10": { # 1.6
		"1280, 800": {"size": Vector2i(1280, 800), "hint": "WXGA"},
		"1440, 900": {"size": Vector2i(1440, 900), "hint": "WXGA+"},
		"1680, 1050": {"size": Vector2i(1680, 1050), "hint": "WSXGA+"},
		"1920, 1200": {"size": Vector2i(1920, 1200), "hint": "WUXGA"},
		"2560, 1600": {"size": Vector2i(2560, 1600), "hint": "WQXGA"},
		"3840, 2400": {"size": Vector2i(3840, 2400), "hint": "WQUXGA"},
	},
	"21:9": { # 64:27 2.370
		"1280, 540": {"size": Vector2i(1280, 540), "hint": "UWqHD 64:27"},
		"1920, 810": {"size": Vector2i(1920, 810), "hint": "UWHD 64:27"},
		"2560, 1080": {"size": Vector2i(2560, 1080), "hint": "UW-FHD 64:27"},
		"3440, 1440": {"size": Vector2i(3440, 1440), "hint": "UWQHD 43:18 "},
		"3840, 1600": {"size": Vector2i(3840, 1600), "hint": "4K UltraWide 12:5"},
		"5120, 2160": {"size": Vector2i(5120, 2160), "hint": "5K UltraWide 64:27"},
	},
	"21:9 Precise": { # 2.333
		"840, 360": {"size": Vector2i(840, 360), "hint": ""},
		"1260, 540": {"size": Vector2i(1260, 540), "hint": ""},
		"1680, 720": {"size": Vector2i(1680, 720), "hint": ""},
		"1890, 810": {"size": Vector2i(1890, 810), "hint": ""},
		"2520, 1080": {"size": Vector2i(2520, 1080), "hint": ""},
		"3360, 1440": {"size": Vector2i(3360, 1440), "hint": ""},
		"3780, 1620": {"size": Vector2i(3780, 1620), "hint": ""},
		"5040, 2160": {"size": Vector2i(5040, 2160), "hint": ""},
	},
	"32:9": { # 3.55555
		"3840, 1080": {"size": Vector2i(3840, 1080), "hint": "2xFHD"},
		"5120, 1440": {"size": Vector2i(5120, 1440), "hint": "2xQHD"},
	},
}

@onready var Vertical_Sync_Data: Dictionary = {
	"type": "option",
	"func": DisplayServer.window_set_vsync_mode,
	"propertie": vertical_sync,
	"section": GRAPHICS,
	"config_keys": {
		VERTICAL_SYNC: {"preset": "Disabled"},
	},
	"items": {
		"Disabled": {"set": DisplayServer.VSyncMode.VSYNC_DISABLED, "hint": ""},
		"Enabled": {"set": DisplayServer.VSyncMode.VSYNC_ENABLED, "hint": ""},
		"Adaptive": {"set": DisplayServer.VSyncMode.VSYNC_ADAPTIVE, "hint": ""},
		"Mailbox": {"set": DisplayServer.VSyncMode.VSYNC_MAILBOX, "hint": ""},
	},
}

@onready var FOV_Data: Dictionary = {
	"type": "float",
	"func": _set_fov,
	"propertie": fov,
	"section": GRAPHICS,
	"config_keys": {
		FOV: {"preset": 90.0},
	},
	"begin": 0.0,
	"end": 180.0,
	"decimals": 0,
}

@onready var Exposure_Data: Dictionary = {
	"type": "float",
	"func": _set_exposure,
	"propertie": exposure,
	"section": GRAPHICS,
	"config_keys": {
		EXPOSURE: {"preset": 0.8},
	},
	"begin": 0.0,
	"end": 16.0,
	"decimals": 2,
}

@onready var Anisotropic_Filtering_Data: Dictionary = {
	"type": "option",
	"func": _set_anisotropic_filtering,
	"propertie": anisotropic_filtering,
	"section": GRAPHICS,
	"config_keys": {
		ANISOTROPIC_FILTERING: {"preset": "4x"},
	},
	"items": {
		"Disabled": {"set": Viewport.AnisotropicFiltering.ANISOTROPY_DISABLED, "hint": "Fastest"},
		"2x": {"set": Viewport.AnisotropicFiltering.ANISOTROPY_2X, "hint": "Faster"},
		"4x": {"set": Viewport.AnisotropicFiltering.ANISOTROPY_4X, "hint": "Fast"},
		"8x": {"set": Viewport.AnisotropicFiltering.ANISOTROPY_8X, "hint": "Average"},
		"16x": {"set": Viewport.AnisotropicFiltering.ANISOTROPY_16X, "hint": "Slow"},
	},
}

@onready var MSAA_2D_Data: Dictionary = {
	"type": "option",
	"func": _set_msaa_2d,
	"propertie": msaa_2d,
	"section": GRAPHICS,
	"config_keys": {
		MSAA_2D: {"preset": "2x"},
	},
	"items": {
		"Disabled": {"set": Viewport.MSAA_DISABLED, "hint": "Fastest"},
		"2x": {"set": Viewport.MSAA_2X, "hint": "Average"},
		"4x": {"set": Viewport.MSAA_4X, "hint": "Slow"},
		"8x": {"set": Viewport.MSAA_8X, "hint": "Slowest"},
	},
}

@onready var MSAA_3D_Data: Dictionary = {
	"type": "option",
	"func": _set_msaa_3d,
	"propertie": msaa_3d,
	"section": GRAPHICS,
	"config_keys": {
		MSAA_3D: {"preset": "2x"},
	},
	"items": {
		"Disabled": {"set": Viewport.MSAA_DISABLED, "hint": "Fastest"},
		"2x": {"set": Viewport.MSAA_2X, "hint": "Average"},
		"4x": {"set": Viewport.MSAA_4X, "hint": "Slow"},
		"8x": {"set": Viewport.MSAA_8X, "hint": "Slowest"},
	},
}

@onready var SSAA_Data: Dictionary = {
	"type": "option",
	"func": _set_ssaa,
	"propertie": ssaa,
	"section": GRAPHICS,
	"config_keys": {
		SSAA: {"preset": "FXAA"},
	},
	"items": {
		"Disabled": {"set": Viewport.SCREEN_SPACE_AA_DISABLED, "hint": "Fastest"},
		"FXAA": {"set": Viewport.SCREEN_SPACE_AA_FXAA, "hint": "Fast"},
	},
}

@onready var TAA_Data: Dictionary = {
	"type": "bool",
	"func": _set_taa,
	"propertie": taa,
	"section": GRAPHICS,
	"config_keys": {
		TAA: {"preset": false},
	},
	true: {"set": true, "hint": ""},
	false: {"set": false, "hint": ""},
}

@onready var SSR_Data: Dictionary = {
	"type": "float",
	"func": _set_ssr,
	"propertie": ssr,
	"section": GRAPHICS,
	"config_keys": {
		SSR: {"preset": 0},
	},
	"begin": 0,
	"end": 512,
	"decimals": 0,
}

@onready var SSAO_Data: Dictionary = {
	"type": "bool",
	"func": _set_ssao,
	"propertie": ssao,
	"section": GRAPHICS,
	"config_keys": {
		SSAO: {"preset": true},
	},
	true: {"set": true, "hint": ""},
	false: {"set": false, "hint": ""},
}

@onready var SSIL_Data: Dictionary = {
	"type": "bool",
	"func": _set_ssil,
	"propertie": ssil,
	"section": GRAPHICS,
	"config_keys": {
		SSIL: {"preset": false},
	},
	true: {"set": true, "hint": ""},
	false: {"set": false, "hint": ""},
}

@onready var Glow_Data: Dictionary = {
	"type": "bool",
	"func": _set_glow,
	"propertie": glow,
	"section": GRAPHICS,
	"config_keys": {
		GLOW: {"preset": true},
	},
	true: {"set": true, "hint": ""},
	false: {"set": false, "hint": ""},
}


var custom_resolution: Array = ["-1:-1*", "-1, -1*"]
var window_id: int ## window_id = DisplayServer.SCREEN_OF_MAIN_WINDOW
var main_screen_size: Vector2
var main_screen_closest_ratio: String
var game_window_size: Vector2
#var graphics_p_default_dic: Dictionary
var _update_resolution_properties_call_handler: CallOnceWhenNeeded = CallOnceWhenNeeded.new(_update_resolution_properties)

@onready var all_option_datas: Array = [Display_Mode_Data, Resolution_Mode_Data, Aspect_Ratios_Data, Resolutions_Data, Vertical_Sync_Data, FOV_Data, Exposure_Data, Anisotropic_Filtering_Data, MSAA_2D_Data, MSAA_3D_Data, SSAA_Data, TAA_Data, SSR_Data, SSAO_Data, SSIL_Data, Glow_Data]
@onready var regular_option_datas: Array = [Vertical_Sync_Data, FOV_Data, Exposure_Data, Anisotropic_Filtering_Data, MSAA_2D_Data, MSAA_3D_Data, SSAA_Data, TAA_Data, SSR_Data, SSAO_Data, SSIL_Data, Glow_Data]
@onready var custom_option_datas: Array = [Display_Mode_Data, Resolution_Mode_Data, Aspect_Ratios_Data, Resolutions_Data]

@onready var resolution_label: Label = %ResolutionLabel



func _ready() -> void:
	check_all_option_data_dic(regular_option_datas + custom_option_datas) # 数据检查

	# 准备控件的属性
	for i in regular_option_datas:
		var propertie: Propertie = i["propertie"]
		propertie.option_tab = self
		propertie.option_data = i
		var config_keys: Dictionary = i["config_keys"]
		propertie.current_config_key = config_keys.keys()[0]

	for i in custom_option_datas:
		var propertie: Propertie = i["propertie"]
		propertie.option_tab = self
		propertie.option_data = i
		propertie.auto_set_config_value = false

	display_mode.current_config_key = DISPLAY_MODE
	resolution_mode.current_config_key = FULLSCREEN_RESOLUTION_MODE
	aspect_ratios.current_config_key = FULLSCREEN_DEFAULT_ASPECT_RATIOS
	resolutions.current_config_key = FULLSCREEN_DEFAULT_RESOLUTIONS

	# 初始化设置控件
	initialize_option_control()

	# 连接信号
	display_mode.main_connect(_on_display_mode_change)
	resolution_mode.main_connect(_on_resolution_mode_change)
	aspect_ratios.main_connect(_on_aspect_ratios_change)
	resolutions.main_connect(_on_resolutions_change)

	#vertical_sync.main_connect(_on_vertical_sync_change)
	#fov.main_connect(_on_fov_change)
	#exposure.main_connect(_on_exposure_change)
#
	#anisotropic_filtering.main_connect(_on_anisotropic_filtering_change)
	#msaa_2d.main_connect(_on_msaa_2d_change)
	#msaa_3d.main_connect(_on_msaa_3d_change)
	#ssaa.main_connect(_on_ssaa_change)
	#taa.main_connect(_on_taa_change)
	#ssr.main_connect(_on_ssr_change)
	#ssao.main_connect(_on_ssao_change)
	#ssil.main_connect(_on_ssil_change)
	#glow.main_connect(_on_glow_change)



func _process(delta: float) -> void:
	_update_resolution_properties_call_handler.execute_if_needed()


## 初始化设置控件
func initialize_option_control() -> void:
	window_id = DisplayServer.SCREEN_OF_MAIN_WINDOW

	## 载入窗口显示模式选项
	#display_mode.option_button.clear()
	#for i in Display_Mode_Data.items:
		#display_mode.option_button.add_item(i)
#
	## 分辨率模式
	#resolution_mode.option_button.clear()
	#for i in ResolutionMode:
		#resolution_mode.option_button.add_item(i)
#
	## 载入屏幕比例选项
	#aspect_ratios.option_button.clear()
	#for ratio in Resolutions:
		#aspect_ratios.option_button.add_item(ratio)
	###aspect_ratios.option_button.item_selected.connect(_on_aspect_ratio_set)
	##aspect_ratios.option_selected.connect(_on_aspect_ratio_set)

	for i in all_option_datas:
		if i["type"] == "option" and i != Resolutions_Data:
			i["propertie"].option_button.clear()
			for j in i["items"]:
				i["propertie"].option_button.add_item(j)
		#if i["type"] == "float":
			#i["propertie"].num_hint_begin = i["begin"]
			#i["propertie"].num_hint_end = i["end"]
			#i["propertie"].num_hint_decimals = i["decimals"]
		i["propertie"].set_option_data()
		i["propertie"].set_ui()

	# 全屏默认比例和分辨率
	_get_window_and_screen()
	# 载入分辨率选项
	aspect_ratios.option_button.select(Ratios.find(main_screen_closest_ratio))
	_on_aspect_ratios_change(Ratios.find(main_screen_closest_ratio))



## 获取窗口和屏幕信息
func _get_window_and_screen() -> void:
	window_id = DisplayServer.SCREEN_OF_MAIN_WINDOW
	main_screen_size = Vector2(DisplayServer.screen_get_size(window_id))
	main_screen_closest_ratio = MathUtils.get_closest_aspect_ratio(main_screen_size)
	game_window_size = Vector2(DisplayServer.window_get_size())

	custom_resolution[0] = MathUtils.simplify_ratio(game_window_size.x, game_window_size.y) + "*"
	custom_resolution[1] = str(game_window_size.x) + ", " + str(game_window_size.y) + "*"
	#print(custom_resolution)
	#aspect_ratios.option_button.set_item_text(0, custom_resolution[0])
	#resolutions.option_button.set_item_text(0, custom_resolution[1])
	resolution_label.text = "screen " + main_screen_closest_ratio + " " + str(int(main_screen_size.x)) + "," + str(int(main_screen_size.y)) + "\n"
	resolution_label.text += "window " + MathUtils.simplify_ratio(game_window_size.x, game_window_size.y, ":", 4, 3) + " " + str(int(game_window_size.x)) + "," + str(int(game_window_size.y))



#var _config: String = config_get_value_graphics()
#var _dic: Dictionary = get_value_in_dic()
## 应用配置   prepare_apply
func apply_config(apply_all: bool = false, reset_ui: bool = false) -> void:
	# 默认设置通常的选项
	var c_regular_option_datas: Array = regular_option_datas if apply_all else GeneralUtils.array_intersection(prepare_apply_arr, regular_option_datas)
	if reset_ui:
		for i in c_regular_option_datas:
			var _value_dic: Dictionary = get_config_value_in_dic(i, i["config_keys"].keys()[0])
			apply_config_value(i, _value_dic)
			match i["type"]:
				"option":
					i["propertie"].set_main_value(_value_dic["index"])
				"float":
					i["propertie"].set_main_value(_value_dic["set"])
				"bool":
					i["propertie"].set_main_value(_value_dic["bool"])
	else:
		for i in c_regular_option_datas:
			var _value_dic: Dictionary = get_config_value_in_dic(i, i["config_keys"].keys()[0])
			apply_config_value(i, _value_dic)

	_get_window_and_screen()
	#graphics_p_default_dic = p_default_dic
	var main_window:= get_tree().get_root()

	# 4个同一组，检查是否处理
	if not apply_all:
		var go_custom_option: bool = false
		for i in custom_option_datas:
			if prepare_apply_arr.has(i):
				go_custom_option = true
		if not go_custom_option:
			return

	# 窗口
	#WINDOW_MODE_WINDOWED
	var display_mode_dic: Dictionary = get_config_value_in_dic(Display_Mode_Data, DISPLAY_MODE)
	apply_config_value(Display_Mode_Data, display_mode_dic)
	#DisplayServer.window_set_mode(display_mode_dic.value)
	var is_windowed: bool = display_mode_dic["key"] == "Windowed"
	var is_fullscreen: bool = display_mode_dic["key"] == "Fullscreen" or display_mode_dic["key"] == "Exclusive Fullscreen"

	# 分辨率模式
	var default_resolution_mode_key: String = WINDOWED_RESOLUTION_MODE if is_windowed else FULLSCREEN_RESOLUTION_MODE
	var resolution_mode_dic: Dictionary = get_config_value_in_dic(Resolution_Mode_Data, default_resolution_mode_key)

	# 分辨率
	var aspect_ratios_dic: Dictionary
	var resolutions_dic: Dictionary
	var default_aspect_ratios_key: String # 全屏和窗口两种情况
	var default_resolutions_key: String
	var is_default_resolutions: bool = resolution_mode_dic["key"] == "Default"
	var is_windowed_custom: bool = is_windowed and resolution_mode_dic["key"] == "Custom"
	var is_fullscreen_native: bool = is_fullscreen and resolution_mode_dic["key"] == "Native"

	# 使用预设
	if is_default_resolutions:
		if is_windowed:
			default_aspect_ratios_key = WINDOWED_DEFAULT_ASPECT_RATIOS
			default_resolutions_key = WINDOWED_DEFAULT_RESOLUTIONS
		if is_fullscreen:
			default_aspect_ratios_key = FULLSCREEN_DEFAULT_ASPECT_RATIOS
			default_resolutions_key = FULLSCREEN_DEFAULT_RESOLUTIONS
		# 获取值
		aspect_ratios_dic = get_aspect_ratios_config_value_in_dic(default_aspect_ratios_key)
		resolutions_dic = get_resolutions_config_value_in_dic(default_resolutions_key, aspect_ratios_dic["key"])

		# 检测是否近似查找，并应用分辨率
		var check_screen_size: Vector2 = Vector2.ZERO
		if (aspect_ratios_dic["key"] == MATCHING_NATIVE or resolutions_dic["key"] == MATCHING_NATIVE): # 近似查找100%
			check_screen_size = main_screen_size
		elif (aspect_ratios_dic["key"] == MATCHING_NATIVE_75 or resolutions_dic["key"] == MATCHING_NATIVE_75): # 近似查找75%
			check_screen_size = main_screen_size * 0.75
		else: # 不近似查找，应用resolutions_dic["key"]
			main_window.size = resolutions_dic["set"]

		# 如果使用近似查找，应用一次结果，防止下次近似查找
		if check_screen_size != Vector2.ZERO:
			var closest_resolution: Dictionary = find_closest_resolution(check_screen_size)
			main_window.size = closest_resolution.size
			CoreSystem.config_manager.set_value(GRAPHICS, default_aspect_ratios_key, closest_resolution.ratio)
			CoreSystem.config_manager.set_value(GRAPHICS, default_resolutions_key, closest_resolution.resolution)
			aspect_ratios_dic["index"] = closest_resolution["ratio_index"]
			resolutions_dic["index"] = closest_resolution["resolution_index"]

	# 窗口时自定义
	if is_windowed_custom:
		var custom_resolutions_config = CoreSystem.config_manager.get_value(GRAPHICS, WINDOWED_CUSTOM_RESOLUTIONS, MATCHING_NATIVE_75)
		var check_screen_size: Vector2 = Vector2.ZERO
		if custom_resolutions_config == MATCHING_NATIVE:
			check_screen_size = main_screen_size
		elif custom_resolutions_config == MATCHING_NATIVE_75:
			check_screen_size = main_screen_size * 0.75
		#else:

		# 如果使用近似查找，应用一次结果，防止下次近似查找
		if check_screen_size > Vector2.ZERO:
			var closest_resolution: Dictionary = find_closest_resolution(check_screen_size)
			main_window.size = closest_resolution.size
			CoreSystem.config_manager.set_value(GRAPHICS, WINDOWED_CUSTOM_RESOLUTIONS, closest_resolution.size)
	# 全屏时原生
	if is_fullscreen_native:
		main_window.size = main_screen_size

	#DisplayServer.window_set_size()
	#DisplayServer.window_set_position()
	main_window.position = (main_screen_size - game_window_size)*0.5




	#var vertical_sync_config: bool = config_get_value_graphics(VERTICAL_SYNC)
	#var fov_config: float = config_get_value_graphics(FOV)
	#var exposure_config: float = config_get_value_graphics(EXPOSURE)
#
	#var anisotropic_filtering_config: String = config_get_value_graphics(ANISOTROPIC_FILTERING)
	#var msaa_2d_config: String = config_get_value_graphics(MSAA_2D)
	#var msaa_3d_config: String = config_get_value_graphics(MSAA_3D)
	#var ssaa_config: String = config_get_value_graphics(SSAA)
	#var taa_config: bool = config_get_value_graphics(TAA)
	#var ssr_config: float = config_get_value_graphics(SSR)
	#var ssao_config: bool = config_get_value_graphics(SSAO)
	#var ssil_config: bool = config_get_value_graphics(SSIL)
	#var glow_config: bool = config_get_value_graphics(GLOW)

	# 清理队列
	prepare_apply_arr.clear()
	prepare_apply_dic.clear()

	# 设置ui
	if not reset_ui:
		return

	display_mode.set_main_value(display_mode_dic["index"])
	resolution_mode.set_main_value(resolution_mode_dic["index"])

	if is_default_resolutions: # 预设分辨率，刷新ui
		aspect_ratios.enable()
		resolutions.enable()
		aspect_ratios.set_main_value(aspect_ratios_dic["index"])
		resolutions.set_main_value(resolutions_dic["index"])
	else:
		aspect_ratios.disabled()
		resolutions.disabled()
	#if is_windowed_custom:
	#
#
	#if is_fullscreen_native:


# 特殊获取 aspect_ratios
func get_aspect_ratios_config_value_in_dic(config_key: String) -> Dictionary:
	if not config_key in Aspect_Ratios_Data["config_keys"]:
		print_debug("This config key does not exist in the config_keys.")
		return {}

	var preset_value = Aspect_Ratios_Data["config_keys"][config_key]["preset"]
	var value = CoreSystem.config_manager.get_value(GRAPHICS, config_key, preset_value)
	var in_dic = value in Aspect_Ratios_Data["items"] or value in [MATCHING_NATIVE, MATCHING_NATIVE_75]
	if not in_dic:
		print_debug("This key does not exist in the option data Dictionary of this option type.")

	var c_value = value if in_dic else preset_value
	if c_value in [MATCHING_NATIVE, MATCHING_NATIVE_75]:
		return{
			"type": "option",
			#"index": Aspect_Ratios_Data["items"].keys().find(c_value),
			"key": c_value,
			#"set": Aspect_Ratios_Data["items"][c_value]["set"],
		}
	else:
		return{
			"type": "option",
			"index": Aspect_Ratios_Data["items"].keys().find(c_value),
			"key": c_value,
			"set": Aspect_Ratios_Data["items"][c_value]["set"],
		}


# 特殊获取 resolutions
func get_resolutions_config_value_in_dic(config_key: String, aspect_ratio: String) -> Dictionary:
	if not config_key in Resolutions_Data["config_keys"]:
		print_debug("This config key does not exist in the config_keys.")
		return {}
	if aspect_ratio in [MATCHING_NATIVE, MATCHING_NATIVE_75]:
		return{
			"type": "option",
			"key": aspect_ratio,
		}

	var preset_value = Resolutions_Data["config_keys"][config_key]["preset"]
	var value = CoreSystem.config_manager.get_value(GRAPHICS, config_key, preset_value)
	var in_dic = value in Resolutions[aspect_ratio] or value in [MATCHING_NATIVE, MATCHING_NATIVE_75]
	if not in_dic:
		print_debug("This key does not exist in the option data Dictionary of this option type.")

	var c_value = value if in_dic else preset_value
	if c_value in [MATCHING_NATIVE, MATCHING_NATIVE_75]:
		return{
			"type": "option",
			#"index": Resolutions[aspect_ratio].keys().find(c_value),
			"key": c_value,
			#"set": Resolutions[aspect_ratio][c_value]["size"],
		}
	else:
		return{
			"type": "option",
			"index": Resolutions[aspect_ratio].keys().find(c_value),
			"key": c_value,
			"set": Resolutions[aspect_ratio][c_value]["size"],
		}


## 从Resolutions查找最近的
func find_closest_resolution(input: Vector2) -> Dictionary:
	var min_distance_sq: float = INF
	var best_match := {}

	for i in Resolutions:
		for j in Resolutions[i]:
			var current_point: Vector2 = Vector2(Resolutions[i][j]["size"])
			var dist_sq: float = input.distance_squared_to(current_point)
			if dist_sq < min_distance_sq:
				min_distance_sq = dist_sq
				best_match = {
					"ratio": i,
					"resolution": j,
					"size": current_point
				}

	return {
		"ratio": best_match["ratio"],
		"ratio_index": Aspect_Ratios_Data["items"].keys().find(best_match["ratio"]),
		"resolution": best_match["resolution"],
		"resolution_index": Resolutions[best_match["ratio"]].keys().find(best_match["resolution"]),
		"size": best_match["size"]
	}


func _set_fov(fov: float) -> void:
	if Global.main_player_camera:
		Global.main_player_camera.fov_base = fov

func _set_exposure(value: float) -> void:
	pass

func _set_anisotropic_filtering(value: float) -> void:
	#func(v): Viewport.anisotropic_filtering_level = v,
	pass

func _set_msaa_2d(value: float) -> void:
	#func(v): Viewport.msaa_2d = v,
	pass

func _set_msaa_3d(value: float) -> void:
	#func(v): Viewport.msaa_3d = v,
	pass

func _set_ssaa(value: float) -> void:
	#func(v): Viewport.screen_space_aa = v,
	pass

func _set_taa(value: float) -> void:
	#func(v): Viewport.use_taa = v,
	pass

func _set_ssr(value: float) -> void:
	pass

func _set_ssao(enabled: bool) -> void:
	pass

func _set_ssil(enabled: bool) -> void:
	pass

func _set_glow(enabled: bool) -> void:
	pass




func _update_resolution_properties() -> void:
	var display_mode_value: String = display_mode.get_main_value()
	var resolution_mode_value: String = resolution_mode.get_main_value()

	var is_windowed: bool = display_mode_value == "Windowed"
	var is_fullscreen: bool = display_mode_value == "Fullscreen" or display_mode_value == "Exclusive Fullscreen"

	var is_default_resolutions: bool = resolution_mode_value == "Default"
	var is_windowed_custom: bool = is_windowed and resolution_mode_value == "Custom"
	var is_fullscreen_native: bool = is_fullscreen and resolution_mode_value == "Native"

	resolution_mode.set_item_disabled_with_text("Native", is_windowed)
	resolution_mode.set_item_disabled_with_text("Custom", is_fullscreen)

	aspect_ratios.set_propertie_disabled(not is_default_resolutions)
	resolutions.set_propertie_disabled(not is_default_resolutions)

"""
设置选项的函数 ！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！
"""

## 窗口模式
func _on_display_mode_change(index: int) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, DISPLAY_MODE, display_mode.get_main_value())
	display_mode.set_config_value()
	_update_resolution_properties_call_handler.call_with_args()


## 分辨率模式
func _on_resolution_mode_change(index: int) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, RESOLUTION_MODE, resolution_mode.get_main_value())
	resolution_mode.set_config_value()
	_update_resolution_properties_call_handler.call_with_args()


## 预设分辨率比例
func _on_aspect_ratios_change(index: int) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, ASPECT_RATIOS, aspect_ratios.get_main_value())
	aspect_ratios.set_config_value()

	resolutions.option_button.clear()
	var _resolutions: Dictionary = Resolutions[aspect_ratios.get_main_value()]
	for ratio in _resolutions:
		resolutions.option_button.add_item(ratio)
	resolutions.set_main_value(0)
	_on_resolutions_change(0)
	#_update_resolution_properties_call_handler.call_with_args()


## 预设分辨率
func _on_resolutions_change(index: int) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, RESOLUTIONS, resolutions.get_main_value())
	resolutions.set_config_value()
	_update_resolution_properties_call_handler.call_with_args()


### 垂直同步
#func _on_vertical_sync_change(toggled_on: bool) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, VERTICAL_SYNC, vertical_sync.get_main_value())
#
#
### 视野
#func _on_fov_change(value: float) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, FOV, fov.get_main_value())
#
#
### 曝光
#func _on_exposure_change(value: float) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, EXPOSURE, exposure.get_main_value())
#
#
### 各向异性过滤
#func _on_anisotropic_filtering_change(index: int) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, ANISOTROPIC_FILTERING, anisotropic_filtering.get_main_value())
#
#
### 多重采样抗锯齿2D
#func _on_msaa_2d_change(index: int) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, MSAA_2D, msaa_2d.get_main_value())
#
#
### 多重采样抗锯齿3D
#func _on_msaa_3d_change(index: int) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, MSAA_3D, msaa_3d.get_main_value())
#
#
### 屏幕空间抗锯齿
#func _on_ssaa_change(index: int) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, SSAA, ssaa.get_main_value())
#
#
### 时间抗锯齿
#func _on_taa_change(toggled_on: bool) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, TAA, taa.get_main_value())
#
#
### 屏幕空间反射
#func _on_ssr_change(value: float) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, SSR, ssr.get_main_value())
#
#
### 屏幕空间环境光遮蔽
#func _on_ssao_change(toggled_on: bool) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, SSAO, ssao.get_main_value())
#
#
### 屏幕空间间接照明
#func _on_ssil_change(toggled_on: bool) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, SSIL, ssil.get_main_value())
#
#
### 辉光
#func _on_glow_change(toggled_on: bool) -> void:
	#CoreSystem.config_manager.set_value(GRAPHICS, GLOW, glow.get_main_value())
