class_name OptionTab
extends ScrollContainer

#const NATIVE: String = "native"
const MATCHING_NATIVE: String = "MatchingNative"
const MATCHING_NATIVE_75: String = "MatchingNative75%"
#const CUSTOM: String = "custom"

# tabs
const GENERAL: String = "general"
const INGAME: String = "ingame"
const GRAPHICS: String = "graphics"
const AUDIO: String = "audio"
const CONTROLS: String = "controls"
const MOD: String = "mod"
const MISC: String = "misc"


#general
#ingame

# graphics
const DISPLAY_MODE: String = "display_mode"
const RESOLUTION_MODE: String = "resolution_mode"
const FULLSCREEN_RESOLUTION_MODE: String = "fullscreen_resolution_mode"
const FULLSCREEN_DEFAULT_ASPECT_RATIOS: String = "fullscreen_default_aspect_ratios"
const FULLSCREEN_DEFAULT_RESOLUTIONS: String = "fullscreen_default_resolutions"
const WINDOWED_RESOLUTION_MODE: String = "windowed_resolution_mode"
const WINDOWED_CUSTOM_RESOLUTIONS: String = "windowed_custom_resolutions"
const WINDOWED_DEFAULT_ASPECT_RATIOS: String = "windowed_default_aspect_ratios"
const WINDOWED_DEFAULT_RESOLUTIONS: String = "windowed_default_resolutions"
#const ASPECT_RATIOS: String = "aspect_ratios"
#const RESOLUTIONS: String = "resolutions"

const VERTICAL_SYNC: String = "vertical_sync"
const FOV: String = "fov"
const EXPOSURE: String = "exposure"
const ANISOTROPIC_FILTERING: String = "anisotropic_filtering"
const MSAA_2D: String = "msaa_2d"
const MSAA_3D: String = "msaa_3d"
const SSAA: String = "ssaa"
const TAA: String = "taa"
const SSR: String = "ssr"
const SSAO: String = "ssao"
const SSIL: String = "ssil"
const GLOW: String = "glow"
#display_mode
#aspect_ratios
#resolutions
#vertical_sync
#fov
#exposure
#anisotropic_filtering
#msaa_2d
#msaa_3d
#ssaa
#taa
#ssr
#ssao
#ssil
#glow


#audio
#controls
#mod
#misc


	#"items": {
		#"Disabled": {"set": Viewport., "hint": ""},
		#"2x": {"set": 2, "hint": "Fastest"},
		#"4x": {"set": 4, "hint": "Faster"},
		#"8x": {"set": 8, "hint": "Fast"},
		#"16x": {"set": 16, "hint": "Average"},
		#"32x": {"set": 32, "hint": "Slow"},
		#"64x": {"set": 64, "hint": "Slower"},
		#"128x": {"set": 128, "hint": "Slowest"},
	#},

## [dic]
var prepare_apply_arr: Array = []
## [{"dic": Dictionary, "config_key": String}]
var prepare_apply_dic: Array[Dictionary] = []



func apply_config(apply_all: bool = false, reset_ui: bool = false) -> void:
	pass


func apply_config_value(dic: Dictionary, value_dic: Dictionary):
	var _func: Callable = dic["func"]
	_func.call(value_dic["set"])


## 获取值在字典内，进行了数据检查，没有则使用默认值
func get_config_value_in_dic(dic: Dictionary, config_key: String) -> Dictionary:
	if not config_key in dic["config_keys"]:
		print_debug("This config key does not exist in the config_keys.")
		return {}

	var preset_value = dic["config_keys"][config_key]["preset"]
	var value = CoreSystem.config_manager.get_value(dic["section"], config_key, preset_value)
	var in_dic = check_value_in_dic(dic, value)

	return _get_value_in_dic(dic, value) if in_dic else _get_value_in_dic(dic, preset_value)


## 获取值在字典内
## 需要结构完整的字典，使用前先调用 check_option_data_dic() 检验完整性
func _get_value_in_dic(dic: Dictionary, value) -> Dictionary:
	match dic["type"]:
		"option":
			return {
				"type": "option",
				"index": dic["items"].keys().find(value),
				"key": value,
				"set": dic["items"][value]["set"],
				}
		"float":
			return {
				"type": "float",
				"set": value,
				}
		"bool":
			return {
				"type": "bool",
				"bool": value,
				"set": dic[value]["set"],
				}
	return{}


## 检查 value 是否在结构字典内
## 需要结构完整的字典，使用前先调用 check_option_data_dic() 检验完整性
func check_value_in_dic(dic: Dictionary, value) -> bool:
	match dic["type"]:
		"option":
			if value in dic["items"]:
				return true
			else:
				print_debug("This key does not exist in the option data Dictionary of this option type.")
		"float":
			if value is float:
				if value >= dic["begin"] and value <= dic["end"]:
					return true
				else:
					print_debug("This value is beyond the value range of this float type.")
			else:
				print_debug("This value should be of the float type.")
		"bool":
			if value in [true, false]:
				return true
			else:
				print_debug("This value does not exist in the option data Dictionary of this bool type.")
	return false


## 检查所有 option_data_dic ，请自行在 _ready() 开头使用
func check_all_option_data_dic(dics: Array) -> void:
	var check: bool = true
	for i in dics:
		if not check_option_data_dic(i):
			check = false
	assert(check, "This Dictionary has a formatting error.") # 数据字典错误


## 检查 option_data_dic 的 key 组成，在一次运行后把所有问题打印出来
func check_option_data_dic(dic: Dictionary) -> bool:
	var errors: Array = []
	var required_keys: Array = ["type", "func", "propertie", "section", "config_keys"]

	# 检查通用必填键
	for key in required_keys:
		if key not in dic:
			errors.append('The key "%s" does not exist in the option data Dictionary.' % key)

	# 如果有错误，先不返回，继续检查其他可能的错误
	if dic.has("type"):
		if dic.has("propertie") and dic["propertie"] is Propertie and dic["type"] != dic["propertie"].type:
			errors.append('The type of the "property" does not match the data.')

		# 根据类型检查特定的键
		var type_specific_keys = {
			"option": ["items"],
			"float": ["begin", "end", "decimals"],
			"bool": [true, false]
		}

		var dic_type = dic["type"]
		if dic_type in type_specific_keys:
			for key in type_specific_keys[dic_type]:
				if key not in dic:
					errors.append('The key "%s" does not exist in the option data Dictionary.' % key)
		else:
			errors.append('There is no correct "type" in the option data Dictionary.')

	# 打印所有错误
	if not errors.is_empty():
		print()
		print("dic: ", HL.format_dict_recursive(dic))
		for error in errors:
			print_debug(error)

	return errors.is_empty()


"""
@onready var option_Data: Dictionary = {
	"type": "option",
	"func": null,
	"propertie": null,
	"section": null,
	"config_keys": {
		null: {"preset": null},
	},
	"items": {
		"null": {"set": null, "hint": ""},
	},
}

@onready var float_Data: Dictionary = {
	"type": "float",
	"func": null,
	"propertie": null,
	"section": null,
	"config_keys": {
		null: {"preset": null},
	},
	"begin": 0.0,
	"end": 1.0,
	"decimals": 0,
}

通常 set 是 true false
@onready var bool_Data: Dictionary = {
	"type": "bool",
	"func": null,
	"propertie": null,
	"section": null,
	"config_keys": {
		null: {"preset": null},
	},
	true: {"set": true, "hint": ""},
	false: {"set": false, "hint": ""},
}
"""
