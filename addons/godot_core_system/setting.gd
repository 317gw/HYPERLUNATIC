extends RefCounted


const SETTING_MODULE_ENABLE: String = "godot_core_system/module_enable/"
const SETTING_SAVE_SYSTEM: String = "godot_core_system/save_system/"
const SETTING_CONFIG_SYSTEM: String = "godot_core_system/config_system/"
const SETTING_TRIGGER_SYSTEM: String = "godot_core_system/trigger_system/"

const SETTING_INFO_DICT: Dictionary[StringName, Dictionary] = {
	"module_enable/event_bus":
	{
		"name": SETTING_MODULE_ENABLE + "event_bus",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/logger":
	{
		"name": SETTING_MODULE_ENABLE + "logger",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/input_manager":
	{
		"name": SETTING_MODULE_ENABLE + "input_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/audio_manager":
	{
		"name": SETTING_MODULE_ENABLE + "audio_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/scene_manager":
	{
		"name": SETTING_MODULE_ENABLE + "scene_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/time_manager":
	{
		"name": SETTING_MODULE_ENABLE + "time_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/resource_manager":
	{
		"name": SETTING_MODULE_ENABLE + "resource_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/async_io_manager":
	{
		"name": SETTING_MODULE_ENABLE + "async_io_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/save_manager":
	{
		"name": SETTING_MODULE_ENABLE + "save_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/config_manager":
	{
		"name": SETTING_MODULE_ENABLE + "config_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/state_machine":
	{
		"name": SETTING_MODULE_ENABLE + "state_machine",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/entity_manager":
	{
		"name": SETTING_MODULE_ENABLE + "entity_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/trigger_manager":
	{
		"name": SETTING_MODULE_ENABLE + "trigger_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"module_enable/gameplay_tag_manager":
	{
		"name": SETTING_MODULE_ENABLE + "gameplay_tag_manager",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"save_system/save_directory":
	{
		"name": SETTING_SAVE_SYSTEM + "save_directory",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR,
		"hint_string": "存档目录路径",
		"basic": true,
		"default": "user://saves",
	},

	"save_system/save_extension":
	{
		"name": SETTING_SAVE_SYSTEM + "save_extension",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": "save",
	},

	"save_system/max_auto_saves":
	{
		"name": SETTING_SAVE_SYSTEM + "max_auto_saves",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1, 100, 1, or_greater",
		"basic": true,
		"default": 3,
	},

	"save_system/auto_save_interval":
	{
		"name": SETTING_SAVE_SYSTEM + "auto_save_interval",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0, 3600, 1, or_greater",
		"basic": true,
		"default": 300,
	},

	"save_system/auto_save_enabled":
	{
		"name": SETTING_SAVE_SYSTEM + "auto_save_enabled",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"config_system/config_path":
	{
		"name": SETTING_CONFIG_SYSTEM + "config_path",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "配置文件路径",
		"basic": true,
		"default": "user://config.cfg",
	},

	"config_system/auto_save":
	{
		"name": SETTING_CONFIG_SYSTEM + "auto_save",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	},

	"trigger_system/subscribe_event_bus":
	{
		"name": SETTING_TRIGGER_SYSTEM + "subscribe_event_bus",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"basic": true,
		"default": true,
	}
}
