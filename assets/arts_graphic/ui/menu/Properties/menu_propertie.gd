@tool
#class_name MenuPropertie
extends HBoxContainer

signal range_value_changed(value: float)
signal checkbox_toggled(button_pressed: bool)
signal option_selected(index: int)

enum ControlMode {H_SLIDER, Spin_Box, CHECK_BOX, OPTION_BUTTON}
enum NumHintControlMode {Hide, NumHint, NumHintLineEdit}

@export var propertie_name: String = "Name"
	#set(v):
		##propertie_name = v
		#if name_label:
			#name_label.text = v

@export var control_mode: ControlMode = ControlMode.CHECK_BOX
	#set(v):
		##control_mode = v
		#_set_controls()
@export var use_reset_button: bool = true

@export_group("Default")
@export var default_value: float = 0.0
@export var default_check: bool = false
@export var default_option: int = -1
#@export var default_option_items: int = -1

@export_group("Num Hint")
@export var use_num_hint: bool = true
@export var num_hint_control_mode: NumHintControlMode = NumHintControlMode.Hide
#@export var num_hint_range: Vector2 = Vector2(0, 100)
@export var num_hint_begin: float = 0.0
@export var num_hint_end: float = 1.0
@export var num_hint_decimals: int = 2
@export var num_hint_units: String = ""


var current_control: Control

@onready var name_label: Label = $NameLabel

@onready var h_slider: HSlider = $Control/HSlider
@onready var spin_box: SpinBox = $Control/SpinBox
@onready var check_box: CheckBox = $Control/CheckBox
@onready var option_button: OptionButton = $Control/OptionButton
@onready var controls: Array = [h_slider, spin_box, check_box, option_button]

#@onready var num_hint: Label = $NumHintControl/NumHint
@onready var num_hint_line_edit: LineEdit = $NumHintControl/NumHintLineEdit
@onready var reset_button: TextureButton = $ResetButtonControl/ResetButton



func _ready() -> void:
	if not Engine.is_editor_hint():
		_set_ui()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_set_ui()
		#_connect_signals()
	if num_hint_line_edit.visible:
		num_hint_line_edit.text = HL.string_num_pad_decimals(h_slider.value, num_hint_decimals) + num_hint_units


func _set_ui() -> void:
	name_label.text = propertie_name
	_set_controls()

	num_hint_line_edit.visible = use_num_hint and control_mode == ControlMode.H_SLIDER
	#if num_hint_line_edit.visible:
	h_slider.value = default_value
	h_slider.min_value = num_hint_begin
	h_slider.max_value = num_hint_end
	h_slider.step = pow(0.1, num_hint_decimals)

	spin_box.value = default_value
	#spin_box.apply()
	spin_box.min_value = num_hint_begin
	spin_box.max_value = num_hint_end
	spin_box.step = pow(0.1, num_hint_decimals)

	check_box.button_pressed = default_check

	option_button.selected = default_option

	var _use_reset_button: bool = false
	match control_mode:
		ControlMode.H_SLIDER:
			_use_reset_button = is_equal_approx(h_slider.value, default_value) and use_reset_button

		ControlMode.Spin_Box:
			_use_reset_button = is_equal_approx(spin_box.value, default_value) and use_reset_button

		ControlMode.CHECK_BOX:
			_use_reset_button = check_box.button_pressed != default_check and use_reset_button

		ControlMode.OPTION_BUTTON:
			_use_reset_button = option_button.selected != default_option and use_reset_button

	reset_button.visible = _use_reset_button
	reset_button.disabled = !_use_reset_button





func _set_controls() -> void:
	#if not (h_slider and check_box and option_button):
		#return

	match control_mode:
		ControlMode.H_SLIDER:
			current_control = h_slider
			h_slider.editable = true
			h_slider.visible = true
			spin_box.editable = false
			spin_box.visible = false
			check_box.disabled = true
			check_box.visible = false
			option_button.disabled = true
			option_button.visible = false

		ControlMode.Spin_Box:
			current_control = spin_box
			h_slider.editable = false
			h_slider.visible = false
			spin_box.editable = true
			spin_box.visible = true
			check_box.disabled = true
			check_box.visible = false
			option_button.disabled = true
			option_button.visible = false

		ControlMode.CHECK_BOX:
			current_control = check_box
			h_slider.editable = false
			h_slider.visible = false
			spin_box.editable = false
			spin_box.visible = false
			check_box.disabled = false
			check_box.visible = true
			option_button.disabled = true
			option_button.visible = false

		ControlMode.OPTION_BUTTON:
			current_control = option_button
			h_slider.editable = false
			h_slider.visible = false
			spin_box.editable = false
			spin_box.visible = false
			check_box.disabled = true
			check_box.visible = false
			option_button.disabled = false
			option_button.visible = true


#func _connect_signals():
	#h_slider.value_changed.connect(_on_h_slider_value_changed)
	#check_box.toggled.connect(_on_check_box_toggled)
	#option_button.item_selected.connect(_on_option_button_selected)


func _on_range_value_changed(value: float):
	range_value_changed.emit(value)

	match control_mode:
		ControlMode.H_SLIDER:
			if use_num_hint:
				num_hint_line_edit.text = "%d%s" % [value, num_hint_units]

		#ControlMode.Spin_Box:
			#spin_box.value = default_value


func _on_check_box_toggled(button_pressed: bool):
	checkbox_toggled.emit(button_pressed)

func _on_option_button_selected(index: int):
	option_selected.emit(index)


func _on_reset_button_toggled(toggled_on: bool) -> void:
	#if not (h_slider and check_box and option_button):
		#return

	match control_mode:
		ControlMode.H_SLIDER:
			h_slider.value = default_value

		ControlMode.Spin_Box:
			spin_box.value = default_value

		ControlMode.CHECK_BOX:
			check_box.button_pressed = default_check

		ControlMode.OPTION_BUTTON:
			option_button.selected = default_option


func _on_num_hint_line_edit_editing_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_num_hint_line_edit_text_changed(new_text: String) -> void:
	# 定义允许的基础字符（数字和小数点）
	var allowed_chars = "0123456789.,"
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
	pass # Replace with function body.
