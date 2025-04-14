extends Control
# HL.FrontSight

# 准星
@export var crosshair_size: float = 8
var amend: Vector2 = Vector2(0.1, 0.1)
var screen_center: Vector2
var front_sight_center: Vector2
var is_auto_aiming: bool
var auto_aim_pos: Vector2

# 瞄准圈
@export var aim_circle_resolution: int = 16
var circle_radius: float = 1

@onready var player_fp_ui: CanvasLayer = $".."
@onready var aim_circle: Line2D = $AimCircle
@onready var crosshair: TextureRect = $AimCircle/Crosshair
@onready var tool_ui: Control = $"../ToolUI"


func _ready() -> void:
	crosshair.scale = Vector2(crosshair_size, crosshair_size) / crosshair.size
	aim_circle.scale = Vector2(circle_radius, circle_radius) / 1
	_update_front_sight_center()
	_calculate_aim_circle_points()
	get_window().size_changed.connect(_calculate_aim_circle_points)
	crosshair.global_position = front_sight_center
	aim_circle.global_position = screen_center


func _physics_process(_delta: float) -> void:
	set_front_sight_visible()
	_update_front_sight_center()
	if is_auto_aiming:
		crosshair.global_position = auto_aim_pos


func _update_front_sight_center() -> void:
	amend = -crosshair.get_size() / 2.0 * crosshair.scale
	screen_center = Vector2(get_viewport().get_size() / 2.0)
	front_sight_center = screen_center + amend


func auto_aim_start(aim_pos: Vector2) -> void:
	is_auto_aiming = true
	auto_aim_pos = aim_pos + amend


func auto_aim_end() -> void:
	is_auto_aiming = false
	crosshair.global_position = front_sight_center
	aim_circle.global_position = screen_center


func _calculate_aim_circle_points() -> void: # 根据圆的半径计算近似组成圆的多边形的点
	aim_circle.clear_points()
	circle_radius = get_viewport().get_size().y / 2 * Global.main_player.auto_aiming_radius
	var angle_step: float = 2 * PI / aim_circle_resolution
	var angle: float = 0
	for i in range(aim_circle_resolution):
		var point: Vector2 = Vector2(cos(angle), sin(angle)) * circle_radius
		aim_circle.add_point(point)
		angle += angle_step


func set_front_sight_visible() -> void:
	aim_circle.visible = not Global.main_menus.visible and not tool_ui.visible
