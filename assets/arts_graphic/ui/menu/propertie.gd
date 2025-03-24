@tool
extends HBoxContainer

enum ControlMode {H_SLIDER, CHECK_BOX, OPTION_BUTTON}

@export var propertie_name: String = "Name"
	#set(v):
		##propertie_name = v
		#if name_label:
			#name_label.text = v

@export var control_mode: ControlMode = ControlMode.H_SLIDER
	#set(v):
		##control_mode = v
		#_set_controls()

@export var use_num_hint: bool = false
#@export var num_hint_range: Vector2 = Vector2(0, 100)
@export var num_hint_units: String = ""
@export var num_hint_begin: String = ""
@export var num_hint_end: String = ""
@export var use_reset_button: bool = false

var current_control: Control
var default

@onready var name_label: Label = $NameLabel

@onready var h_slider: HSlider = $Control/HSlider
@onready var check_box: CheckBox = $Control/CheckBox
@onready var option_button: OptionButton = $Control/OptionButton
@onready var controls: Array = [h_slider, check_box, option_button]

@onready var num_hint: Label = $NumHintControl/NumHint
@onready var reset_button: TextureButton = $ResetButtonControl/ResetButton


func _ready() -> void:
	if not Engine.is_editor_hint():
		_set_ui()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_set_ui()


func _set_ui() -> void:
	name_label.text = propertie_name
	_set_controls()
	num_hint.visible = use_num_hint
	reset_button.visible = use_reset_button
	reset_button.disabled = !use_reset_button


func _set_controls() -> void:
	if not (h_slider and check_box and option_button):
		return
	match control_mode:
		ControlMode.H_SLIDER:
			current_control = h_slider
			h_slider.editable = true
			h_slider.visible = true
			check_box.disabled = true
			check_box.visible = false
			option_button.disabled = true
			option_button.visible = false

		ControlMode.CHECK_BOX:
			current_control = check_box
			h_slider.editable = false
			h_slider.visible = false
			check_box.disabled = false
			check_box.visible = true
			option_button.disabled = true
			option_button.visible = false

		ControlMode.OPTION_BUTTON:
			current_control = option_button
			h_slider.editable = false
			h_slider.visible = false
			check_box.disabled = true
			check_box.visible = false
			option_button.disabled = false
			option_button.visible = true
