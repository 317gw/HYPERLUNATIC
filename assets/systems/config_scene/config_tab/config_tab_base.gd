extends Control


var _focusing_control: Control
var _focusable_list: Array[Control]

var _config_container: VBoxContainer

enum ValueType {
	SLIDER = 0,
	OPTION = 1,
}

signal value_changed(key: String, value: Variant)


func _init() -> void:
	_build_node_structure()
	_setup_configs()


func _ready() -> void:
	if _focusable_list.is_empty(): return
	_focusing_control = _focusable_list.front()

	_focusable_list[0].focus_neighbor_top = _focusable_list[-1].get_path()
	_focusable_list[-1].focus_neighbor_bottom = _focusable_list[0].get_path()

	for control in _focusable_list:
		control.focus_entered.connect(
			func(): _focusing_control = control)


func _on_tab_selected() -> void:
	if _focusing_control == null: return
	_focusing_control.grab_focus()


func add_config(data: Dictionary = {}) -> void:
	if data.is_empty(): return add_space()
	match data.get("type", ValueType.SLIDER):
		ValueType.SLIDER: _add_slider(data)
		ValueType.OPTION: _add_option(data)


func add_space(padding_size: float = 72.0) -> void:
	var control: Control = Control.new()
	control.custom_minimum_size.y = padding_size
	_config_container.add_child(control)


func _add_slider(data: Dictionary) -> void:
	var new_slider: HSlider = HSlider.new()
	new_slider.scrollable = false
	new_slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	new_slider.value = data.get("value", 0.0)
	new_slider.max_value = data.get("max_value", 100.0)
	new_slider.value_changed.connect(
		func(value: float):
		var key: String = data.get("name", "")
		_on_value_changed(key, value)
		value_changed.emit(key, value)
	)

	_focusable_list.append(new_slider)
	_add_new_config(new_slider, data)


func _add_option(data: Dictionary) -> void:
	var new_option: OptionButtonCustom = OptionButtonCustom.new()
	var options: Array = data.get("options", []) as Array
	new_option.options = options
	new_option.option_index = options.find(data["value"])\
		if data.has("value") else data.get("option_index", 0)
	new_option.option_loop = data.get("option_loop", false)

	new_option.mouse_filter = Control.MOUSE_FILTER_PASS
	new_option.value_changed.connect(
		func(value: Variant):
		var key: String = data.get("name", "")
		_on_value_changed(key, value)
		value_changed.emit(key, value)
	)

	_focusable_list.append(new_option._center_button)
	_add_new_config(new_option, data, new_option._center_button)


func _add_new_config(
	value_node: Control,
	data: Dictionary,
	focus_node: Control = null,
	) -> void:

	var focus_target: Control = value_node if focus_node == null else focus_node

	var new_config_container: PanelContainer = PanelContainer.new()
	new_config_container.custom_minimum_size.y = 72.0
	new_config_container.self_modulate.a = 0.0
	_config_container.add_child(new_config_container)

	focus_target.focus_entered.connect(
		func(): new_config_container.self_modulate.a = 1.0)
	focus_target.focus_exited.connect(
		func(): new_config_container.self_modulate.a = 0.0)
	new_config_container.mouse_entered.connect(focus_target.grab_focus)

	var new_h_box_container: HBoxContainer = HBoxContainer.new()
	new_config_container.add_child(new_h_box_container)

	var new_label: Label = Label.new()
	new_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_label.clip_text = true
	new_label.text = data.get("name", "")
	new_h_box_container.add_child(new_label)

	value_node.mouse_filter = Control.MOUSE_FILTER_PASS
	value_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	value_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_node.size_flags_stretch_ratio = 3.0
	new_h_box_container.add_child(value_node)

	var control: Control = Control.new()
	control.custom_minimum_size.x = 12.0
	new_h_box_container.add_child(control)


func _build_node_structure() -> void:
	var new_scroll_container: ScrollContainer = ScrollContainer.new()
	new_scroll_container.follow_focus = true
	new_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	new_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	new_scroll_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(new_scroll_container)

	_config_container = VBoxContainer.new()
	_config_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_config_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_scroll_container.add_child(_config_container)


func _setup_configs() -> void: pass
func _on_value_changed(_key: String, _value: Variant) -> void: pass
