extends Control

var terminal: Node3D
@onready var interactive_screen: StaticBody3D = $"../.."
@onready var label_name: Label = $LabelName
@onready var label_time: Label = $LabelTime
@onready var button_teleport: Button = $VBoxContainer/ButtonTeleport


func _ready() -> void:
	label_time.text = ""
	label_name.text = ""
	var _max = max(size.x, size.y)
	interactive_screen.content_size = Vector2(_max, _max)
	button_teleport.disabled = true

func _physics_process(_delta: float) -> void:
	label_time.text = terminal.route.get_time_record()


#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion:
		#prints(event)
	#elif event is InputEventMouseButton:
		#prints(event)

func teleport_enable() -> void:
	button_teleport.disabled = false


func change_name(_name) -> void:
	label_name.text = _name
