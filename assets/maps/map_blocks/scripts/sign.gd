@tool

class_name Sign
extends GeometryInstance3D

@export var board_visible: bool = true
@export var stick_visible: bool = true

@onready var board: CSGBox3D = $Board
@onready var stick: CSGBox3D = $Stick

func _process(_delta: float) -> void:
	board.visible = board_visible
	board.use_collision = board_visible
	stick.visible = stick_visible
	stick.use_collision = stick_visible
