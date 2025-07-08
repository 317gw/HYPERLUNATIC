extends TextEdit


#@export var paragraph_cap: int = 30
@export var max_line: int = 8
@export var clear_cd: float = 0.01

var is_new_line: bool = true
var last_event1: String
var last_event2: String
var clear_cd_count: float

@onready var line_feed_timer: Timer = $LineFeedTimer
@onready var clear_up_timer: Timer = $ClearUpTimer

# func _ready() -> void:

func _physics_process(delta: float) -> void:
	#if get_paragraph_count() > paragraph_cap:
		#remove_paragraph(get_paragraph_count()-paragraph_cap-1) # [0, get_paragraph_count() - 1]
	if clear_up_timer.time_left <= 0 and text.length() > 0:
		# var text = get_text()
		#await get_tree().create_timer(0.1)
		if clear_cd_count >= clear_cd:
			#var _text = text.substr(1) # 从开头删除最老的字符
			text = text.substr(1)
			clear_cd_count = 0
		clear_cd_count += delta


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		if is_new_line:
			text += " --"
			is_new_line = false

		if event.as_text() == last_event1 or event.as_text() == last_event2:
			text += "."
		else:
			text += " "
			text += event.as_text()
		last_event1 = event.as_text()
		last_event2 = last_event1
		line_feed_timer.start()
		clear_up_timer.start()
		clear_cd_count = 0

	#if get_paragraph_count() > paragraph_cap:
		#remove_paragraph(get_paragraph_count()-paragraph_cap) # [0, get_paragraph_count() - 1]
	#if text.
	if get_line_count() > max_line:
		remove_line_at(0)

func _on_line_feed_timer_timeout() -> void:
	text += "\n"
	is_new_line = true
	last_event1 = "初始化"
	last_event2 = "初始化"

# func _on_clear_up_timer_timeout() -> void:
# 	#clear()
# 	if get_total_character_count() > 0:
# 		var text = get_text()
# 		set_text(text.substr(1))  # 从开头删除最老的字符
