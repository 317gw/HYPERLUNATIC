extends CanvasLayer

@export var crosshair_size: float = 8

var normal_crosshair: bool = true
var amend_x: float = 0.1
var amend_y: float = 0.1
var amend: Vector2
var screen_center: Vector2

@onready var crosshair: TextureRect = $Crosshair
@onready var pause_menu: Control = $"../PauseMenu"
@onready var player: HL.Controller.Player = $"../Player"

func _ready() -> void:
	crosshair.scale = Vector2(crosshair_size, crosshair_size) / crosshair.size

func _physics_process(_delta: float) -> void:
	if pause_menu.visible == true:
		crosshair.visible = false
	else:
		crosshair.visible = true

	amend_x = -crosshair.get_size().x / 2 * crosshair.scale.x
	amend_y = -crosshair.get_size().y / 2 * crosshair.scale.y
	amend = Vector2(amend_x, amend_y)
	screen_center = Vector2(get_viewport().get_size() / 2)
	if normal_crosshair:
		crosshair.position = screen_center + amend
