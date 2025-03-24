extends Control

#signal

enum LabelMode {ONE_SCROLL_LABEL, TILE_SCROLL_LABEL}
@export var label_mode: LabelMode = LabelMode.ONE_SCROLL_LABEL
@export var one_scroll_label_wait_time: float = 1
@export var scroll_speed: float = 1
@export var spacing: float = 200  # 文本间隔

var text_width: float
var scroll_width: float
var current_spacing: float
var scroll_label_count: int
var base_scroll_speed_min: float = 50
var base_scroll_speed_max: float = 400
var oslw_time_temp: float = 0

var main_menu_b0_id: int = 1
var current_menu: Array
var tween: Tween

const SCROLL_LABEL = preload("res://assets/arts_graphic/ui/menu/scroll_label.tscn")

@onready var option_window: Window = $OptionWindow
@onready var button_container: Control = $ButtonContainer
@onready var text_timer: Timer = $TextTimer

@onready var scroll_label_timer: Timer = $ScrollLabelTimer
@onready var scroll_label_container: Control = $ScrollLabelContainer
@onready var scroll_label: Label = $ScrollLabelContainer/ScrollLabel


# Dictionary
var MainMenu: Array = [ # 0--6
	[{"name": "Previous Server", "hint": "回到上个服务器", "func": 0},
	 {"name": "Pause Menu", "hint": "回到暂停菜单", "func": _on_to_PauseMenu_button_pressed}],
	{"name": "Find Server", "hint": "寻找服务器", "func": 0},
	{"name": "Create Server", "hint": "创建服务器", "func": 0},
	{"name": "Options", "hint": "游戏设置", "func": _on_to_Options_button_pressed},
	{"name": "Achievement", "hint": "成就和游戏进度", "func": 0},
	{"name": "Museum", "hint": "制作人员博物馆", "func": 0},
	{"name": "Quit", "hint": "退出到桌面", "func": _on_quit_button_pressed},
]

var PauseMenu: Array = [ # 0--2
	{"name": "Resume", "hint": "回到游戏", "func": _on_resume_button_pressed},
	{"name": "Restart", "hint": "重新载入地图", "func": _on_restart_button_pressed},
	{"name": "Main Menu", "hint": "回到主菜单，这不会退出服务器", "func": _on_to_MainMenu_button_pressed},
]

var DefaultHint: Array = [
	"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Quis ipsum suspendisse ultrices gravida. Risus commodo viverra maecenas accumsan lacus vel facilisis.",
	"ESC:菜单  F3:Debug菜单  WASD:移动  Space:跳跃,长按跳的更高  鼠标下滚轮:小跳  Shift:冲刺  Q:转身  Alt:回头  左键:开枪  F:捡起  R:旋转物体,鼠标滚轮,调整物体远近  Z:视野缩放,鼠标滚轮,调整缩放  Ctrl:低速模式,静步,防止掉落,空中低速",
	"测试0.0.1c？ 自己做的游戏，啥也没有 3d fps 平台跳跃 把做的所有东西都放到一起了，所以没有设计完整的地图 纯pc 没有计划手机抱歉，注意导出缓存错误帧数可能好点制作了更好的水着色器，卡+10086",
	"前方到站：东冰港电子科技无限公司  想要下车的乘客请提前准备下车",
	"--- Debugging process stopped ---",
	"This is HYPERLUNATIC",
	"添加自动加载",
	":v",
	"",
]


func _ready() -> void:
	#scroll_label.add_theme_font_size_override("font_size", 32)

	get_window().size_changed.connect(_set_scroll_label_pos)
	#_update_scroll_label(DefaultHint[randi_range(0, DefaultHint.size()-1)])
	_update_scroll_label(DefaultHint[0])

	_update_buttons(PauseMenu)
	for button: Button in button_container.get_children():
		button.mouse_entered.connect(_mouse_entered_update_text.bind(button))

	#for i in Resolutions:
		#print(i)
		#for j in Resolutions[i]:
			#var vec2i = Resolutions[i][j]["size"]
			#print(vec2i.x/float(vec2i.y))

	option_window.visible = visible


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		switch_menu()


func _process(_delta) -> void:
	if label_mode == LabelMode.TILE_SCROLL_LABEL:
		var base_scroll_speed: float = clampf(
			remap(text_width,
				200, get_viewport_rect().size.x/0.5,
				base_scroll_speed_min, base_scroll_speed_max),
			base_scroll_speed_min, base_scroll_speed_max)
		var offset: float = scroll_speed * _delta * base_scroll_speed
		for s_l in scroll_label_container.get_children():
			s_l.position.x = wrap(s_l.position.x - offset, -text_width, get_viewport_rect().size.x)


func _physics_process(delta: float) -> void:
	if Engine.get_physics_frames() % 3 == 0:
		for button in button_container.get_children():
			var ratio: float = 1 - text_timer.time_left / text_timer.wait_time
			button.text = replace_with_random_letters(button.text, button.get_meta("current_name"), ratio, ratio)


func _mouse_entered_update_text(button: Button) -> void:
	_update_scroll_label(button.get_meta("hint"))
	scroll_label_timer.call_deferred(&"set_wait_time", 10.0)
	scroll_label_timer.call_deferred(&"start")


func _update_scroll_label(new_text: String):
	# 清理
	#labels.clear()
	for s_l in scroll_label_container.get_children():
		if s_l == scroll_label:
			s_l.visible = false
			continue
		s_l.queue_free()
	await get_tree().process_frame  # 等待尺寸计算完成

	scroll_label.text = new_text
	scroll_label.size = scroll_label.get_minimum_size()
	text_width = scroll_label.size.x
	scroll_width = text_width + get_viewport_rect().size.x
	scroll_label.position.x = 20

	#labels.resize(floorf(scroll_width / (text_width + spacing)))
	scroll_label_count = floorf(scroll_width / (text_width + spacing))
	current_spacing = scroll_width / scroll_label_count - text_width

	if label_mode == LabelMode.TILE_SCROLL_LABEL:
		# 生成
		for i in scroll_label_count-1:
			var new_s_l:= SCROLL_LABEL.instantiate()
			scroll_label_container.add_child(new_s_l)
			#new_s_l.name = "ScrollLabel" + str(i+1)
			new_s_l.text = new_text
			new_s_l.size = scroll_label.get_minimum_size()
			new_s_l.position.x = 20
			new_s_l.visible = false

		#labels = scroll_label_container.get_children()
		await get_tree().process_frame
	_set_scroll_label_pos()


# 初始位置调整
func _set_scroll_label_pos() -> void:
	if label_mode == LabelMode.ONE_SCROLL_LABEL:
		scroll_label.visible = true
		scroll_label.position.x = 20
		if text_width > get_viewport_rect().size.x:
			var tween_time: float = 5 * text_width / get_viewport_rect().size.x
			scroll_label_timer.call_deferred(&"set_wait_time", 10.0 + tween_time*0.8)
			scroll_label_timer.call_deferred(&"start")
			# 动画
			await get_tree().create_timer(2).timeout
			tween = get_tree().create_tween()
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(scroll_label, ^"position:x", (get_viewport_rect().size.x - text_width)-20, tween_time)
		else:
			if tween:
				tween.kill()


	if label_mode == LabelMode.TILE_SCROLL_LABEL:
		var viewport_rect_width = get_viewport_rect().size.x
		for i in scroll_label_container.get_child_count():
			var s_l: Label = scroll_label_container.get_child(i)
			s_l.position.x = i*(text_width + current_spacing) + 20# - text_width*0.5
			s_l.visible = true


func _update_buttons(menu_data: Array) -> void:
	var buttons:= button_container.get_children()
	current_menu = menu_data
	text_timer.start()

	for i in buttons.size():
		var button: Button = buttons[i]

		# 删除信号连接函数
		if button.pressed.has_connections():
			var connections = button.pressed.get_connections()
			for connection in connections:
				button.pressed.disconnect(connection["callable"])
			if button.pressed.has_connections():
				prints("button.pressed.has_connections BUGGGGG")

		# 处理多余按钮
		if i >= menu_data.size():
			button.disabled = true
			button.set_meta("current_name", "")
			button.set_meta("hint", "")
			continue
		button.disabled = false

		var b_dic: Dictionary
		if i == 0 and menu_data == MainMenu:
			b_dic = menu_data[0][main_menu_b0_id]
		else:
			b_dic = menu_data[i]
		button.set_meta("current_name", b_dic["name"])
		button.set_meta("hint", b_dic["hint"])

		# 信号连接新的函数
		var b_func = b_dic["func"]
		if b_func is Callable:
			button.pressed.connect(b_func)


func open_menu():
	get_tree().paused = true
	self.visible = true
	option_window.visible = option_window.visible_save

func close_menu():
	get_tree().paused = false
	self.visible = false
	option_window.visible_save = option_window.visible
	option_window.visible = false


func switch_menu() -> void:
	if self.visible:
		close_menu()
	else:
		open_menu()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


#const alphabet: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
func replace_with_random_letters(input_string: String, correct_string: String, replace_ratio: float, correct_ratio: float) -> String:
	replace_ratio = clamp(replace_ratio, 0.0, 1.0) # 确保替换比例在0到1之间
	correct_ratio = clamp(correct_ratio, 0.0, 1.0)

	var result_length: int = int(lerpf(input_string.length(), correct_string.length(), correct_ratio))
	var num_to_replace = int(result_length * replace_ratio) # 计算需要替换的字符数量
	var chars: PackedByteArray = input_string.to_utf8_buffer() # 创建一个数组来存储字符串中的字符
	chars.resize(result_length)

	for i in num_to_replace: # 随机替换字符
		var random_index: int = randi() % chars.size()
		var random_letter: String
		if randf() < correct_ratio and correct_string.length() > 0:
			random_letter = correct_string[clampi(random_index, 0, max(correct_string.length()-1, 0))]
		else:
			random_letter = HL.Alphabet[randi() % HL.Alphabet.length()]
		chars[random_index] = random_letter.to_utf8_buffer()[0]
	# 将数组转换回字符串
	var result_string: String = chars.get_string_from_utf8()
	return result_string


func _on_scroll_label_timer_timeout() -> void:
	scroll_label_timer.call_deferred(&"set_wait_time", 10.0)
	scroll_label_timer.call_deferred(&"start")
	var rand_hint: String = DefaultHint[randi_range(0, DefaultHint.size()-1)]
	while rand_hint == scroll_label.text:
		rand_hint = DefaultHint[randi_range(0, DefaultHint.size()-1)]
	_update_scroll_label(rand_hint)


func _on_resume_button_pressed() -> void:
	close_menu()

func _on_restart_button_pressed() -> void:
	close_menu()
	Global.reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_to_MainMenu_button_pressed() -> void:
	_update_buttons(MainMenu)

func _on_to_PauseMenu_button_pressed() -> void:
	_update_buttons(PauseMenu)

func _on_to_Options_button_pressed() -> void:
	option_window.visible_save = option_window.visible
	if option_window.visible:
		option_window.visible = false
	else:
		option_window.position = (get_viewport_rect().size - Vector2(option_window.size) )*0.5
		option_window.visible = true

















pass
