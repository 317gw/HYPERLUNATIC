extends Line2D

@export var number_of_points: int = 16

var screen_center: Vector2
var circle_radius: float = 1

@onready var player_fp_ui: CanvasLayer = $"../.."

func _ready() -> void:
	scale = Vector2(circle_radius, circle_radius) / 1 # size

func _physics_process(_delta: float) -> void:
	if Global.main_menus.visible == true:
		visible = false
	else:
		visible = true
	screen_center = Vector2(get_viewport().get_size() / 2)
	position = screen_center

	calculate_points()

func calculate_points() -> void: # 根据圆的半径计算近似组成圆的多边形的点
	clear_points()
	circle_radius = get_viewport().get_size().y / 2 * Global.main_player.auxiliary_aiming_radius
	var angle_step: float = 2 * PI / number_of_points
	var angle: float = 0
	for i in range(number_of_points):
		var point: Vector2 = Vector2(cos(angle), sin(angle)) * circle_radius
		add_point(point)
		angle += angle_step
