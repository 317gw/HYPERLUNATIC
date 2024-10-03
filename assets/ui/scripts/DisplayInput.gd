extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


@export var paragraph_cap: int = 30

#func _process(delta: float) -> void:
	#if get_paragraph_count() > paragraph_cap:
		#remove_paragraph(get_paragraph_count()-paragraph_cap-1) # [0, get_paragraph_count() - 1]

var last_event1: String
var last_event2: String
@onready var line_feed_timer: Timer = $LineFeedTimer
@onready var clear_up_timer: Timer = $ClearUpTimer

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		if event.as_text() == last_event1 or event.as_text() == last_event2:
			append_text(".")
		else:
			append_text("  ")
			append_text(event.as_text())
		last_event1 = event.as_text()
		last_event2 = last_event1
		line_feed_timer.start()

	if get_paragraph_count() > paragraph_cap:
		remove_paragraph(get_paragraph_count()-paragraph_cap) # [0, get_paragraph_count() - 1]

func _on_line_feed_timer_timeout() -> void:
	append_text("\n")
	last_event1 = "初始化"
	last_event2 = "初始化"

#func _on_clear_up_timer_timeout() -> void:
	#clear()
