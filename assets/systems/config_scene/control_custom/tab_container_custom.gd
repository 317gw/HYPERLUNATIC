extends TabContainer
class_name TabContainerCustom


@export var tab_bar: TabBar
@export var tab_index: int

@export var tab_name: Array[String]
@export var tab_icon: Array[Texture2D]

@export var always_show: bool


func _init() -> void:
	tabs_visible = false
	use_hidden_tabs_for_min_size = true


func _ready() -> void:
	_setup_tab_bar()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_prev"): move_tab(-1)
	if event.is_action_pressed(&"ui_next"): move_tab(+1)


func move_tab(index: int) -> void:
	if tab_bar == null: return
	var tab_count: int = get_tab_count()
	if tab_count <= 0: return
	tab_bar.current_tab = wrapi(current_tab + index, 0, tab_count)


func _setup_tab_bar() -> void:
	if tab_bar == null: return

	var tab_count: int = get_tab_count()
	tab_icon.resize(tab_count)
	tab_name.resize(tab_count)

	tab_bar.clip_tabs = false
	tab_bar.scrolling_enabled = false
	tab_bar.focus_mode = Control.FOCUS_NONE
	tab_bar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tab_bar.tab_changed.connect(_on_tab_changed)

	for index in tab_count:
		var tab_title: String = _get_tab_name(index) if always_show else ""
		tab_bar.add_tab(tab_title, tab_icon[index])

	tab_bar.current_tab = wrapi(tab_index, 0, tab_count)


func _get_tab_name(index: int) -> String:
	return tab_name[index] + " "


func _on_tab_changed(tab: int) -> void:
	if not always_show:
		tab_bar.set_tab_title(current_tab, "")
		tab_bar.set_tab_title(tab, _get_tab_name(tab))

	current_tab = tab

	var current_control: Control = get_current_tab_control()
	if current_control.has_method("_on_tab_selected"):
		current_control.call_deferred("_on_tab_selected")
