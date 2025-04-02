extends Window

var DisplayMode: Dictionary = {
	"Windowed": Window.Mode.MODE_WINDOWED,
	"Fullscreen": Window.Mode.MODE_FULLSCREEN,
	"Exclusive Fullscreen": Window.Mode.MODE_EXCLUSIVE_FULLSCREEN,
}

# 4:3, 5:4, 16:9, 16:10, 21:9, 32:9
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

var Anti_Aliasing_Mode: Dictionary = {

}

var visible_save: bool
var input_map: Array

const PROPERTIE = preload("res://assets/arts_graphic/ui/menu/Propertie.tscn")

@onready var main_menus: CanvasLayer = $"../.."
# Field of View
@onready var display_mode: HBoxContainer = %DisplayMode
@onready var aspect_ratios: HBoxContainer = %AspectRatios
@onready var resolutions: HBoxContainer = %Resolutions
#@onready var anti_aliasing_mode: HBoxContainer = %"Anti-aliasingMode"

@onready var input_vbc: VBoxContainer = $PanelContainer/VBoxContainer/TabContainer/输入/MarginContainer/VBoxContainer



func _ready() -> void:
	var ob: OptionButton = aspect_ratios.option_button
	ob.clear()
	for ratio in Resolutions:
		ob.add_item(ratio)
	ob.item_selected.connect(_on_aspect_ratio_set)
	_on_aspect_ratio_set(0)

	display_mode.option_button.clear()
	for i in DisplayMode:
		display_mode.option_button.add_item(i)

	set_up_ui_input_map()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		main_menus.switch_menu()


func set_up_ui_input_map() -> void:
	input_map = InputMap.get_actions()
	input_map = input_map.filter(func(input_name): return not ("ui_" in input_name or "goat_" in input_name) )
	prints(input_map)
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


func _on_aspect_ratio_set(index) -> void:
	var resolution: Dictionary = Resolutions[aspect_ratios.option_button.get_item_text(index)]
	var ob: OptionButton = resolutions.option_button
	ob.clear()
	for ratio in resolution:
		ob.add_item(ratio)


func _on_close_requested() -> void:
	visible = false
