extends Control

const GRAPH_MAX_SPEED_MIN = 10 # 图表最小最大速度
const GRAPH_MAX_ACCELERATION_MIN = 10
const GRAPH_MIN_SPEED = 0 # 图表最小速度
const GRAPH_MIN_ACCELERATION = 0

@export var num_string_decimals: int = 3
@export var history_num_frames = 150 # 历史帧数
@export var interval: String = "  "
@export var forbidden: String = "🚫"


var player: HL.Player
# 速度历史记录，用于图表
var player_velocity_mas_history: Array[float] = []
var player_acceleration_mas_history: Array[float] = []
var player_velocity_pos_history: Array[float] = []
var player_acceleration_pos_history: Array[float] = []

var GRAPH_SIZE := Vector2(150, 25) # 图表尺寸

var GRAPH_MAX_SPEED: float = 10 # 图表最大速度
var GRAPH_MAX_ACCELERATION: float = 10

var JumpingHeight_temp: float = 0

var gradient := Gradient.new()

@onready var speed_graph: Panel = $Graphs/SpeedGraph/Graph # 速度图表的引用
@onready var acceleration_graph: Panel = $Graphs/AccelerationGraph/Graph

@onready var speed_title = $Graphs/SpeedGraph/Title
@onready var acceleration_title = $Graphs/AccelerationGraph/Title

@onready var player_global_position: Label = $Graphs/GlobalPosition
@onready var jumping_time = $Graphs/JumpingTime
@onready var jumping_height = $Graphs/JumpingHeight

@onready var floor_friction: Label = $Graphs/FloorFriction
@onready var movement_decelerate: Label = $Graphs/MovementDecelerate
@onready var air_damp: Label = $Graphs/AirDamp
@onready var water_decelerate: Label = $Graphs/WaterDecelerate

@onready var movement_state: Label = $Graphs/MovementState
@onready var camera_state: Label = $Graphs/CameraState
@onready var weapon: Label = $Graphs/Weapon
@onready var floor_angle: Label = $Graphs/FloorAngle

@onready var danmaku_count: Label = $Graphs/DanmakuCount



func _ready() -> void: # _ready函数
	#await Global.main_player_ready
	player = Global.main_player

	# NOTE: Both FPS and frametimes are colored following FPS logic
	# (red = 10 FPS, yellow = 60 FPS, green = 110 FPS, cyan = 160 FPS).
	# This makes the color gradient non-linear.
	# Colors are taken from <https://tailwindcolor.com/>.
	gradient.set_color(0, Color8(239, 68, 68)) # red-500
	gradient.set_color(1, Color8(56, 189, 248)) # light-blue-400
	gradient.add_point(0.3333, Color8(250, 204, 21)) # yellow-400
	gradient.add_point(0.6667, Color8(128, 226, 95)) # 50-50 mix of lime-400 and green-400

	speed_graph.resized.connect(_set_graph_size)
	_set_graph_size()


func _physics_process(delta: float) -> void:
	speed_graph.queue_redraw() # 请求图表重绘
	acceleration_graph.queue_redraw()
	_up_title(delta)


func _set_graph_size() -> void:
	GRAPH_SIZE = speed_graph.size # 初始化图表尺寸
	history_num_frames = speed_graph.size.x * 200 / 480

	speed_graph.draw.connect(_speed_mas_graph_draw) # 连接图表绘制信号
	acceleration_graph.draw.connect(_acceleration_mas_graph_draw)
	speed_graph.draw.connect(_speed_pos_graph_draw) # 连接图表绘制信号
	acceleration_graph.draw.connect(_acceleration_pos_graph_draw)

	player_velocity_mas_history.resize(history_num_frames) # 调整速度历史记录的大小
	player_acceleration_mas_history.resize(history_num_frames)
	player_velocity_pos_history.resize(history_num_frames)
	player_acceleration_pos_history.resize(history_num_frames)
	#speed_xz_history.resize(history_num_frames)
	#acceleration_xz_history.resize(history_num_frames)


func _up_title(delta: float) -> void:
	if not player:
		return

	# player_velocity
	var player_velocity_mas = player.velocity.length() # 获取玩家速度
	player_velocity_mas_history.push_back(player_velocity_mas) # 将速度添加到历史记录
	if player_velocity_mas_history.size() > history_num_frames: # 如果历史记录超过最大帧数
		player_velocity_mas_history.pop_front() # 移除最旧的速度
	# max
	var speed_max = player_velocity_mas_history.max() # 获取历史记录中的最大速度
	GRAPH_MAX_SPEED = speed_max if (speed_max and speed_max > GRAPH_MAX_SPEED_MIN) else GRAPH_MAX_SPEED_MIN
	# player_velocity_pos
	var player_velocity_pos = player.velocity_pos.length()
	player_velocity_pos_history.push_back(player_velocity_pos) # 将速度添加到历史记录
	if player_velocity_pos_history.size() > history_num_frames: # 如果历史记录超过最大帧数
		player_velocity_pos_history.pop_front() # 移除最旧的速度

	# player_acceleration
	var player_acceleration_mas = player.acceleration_mas
	player_acceleration_mas_history.push_back(player_acceleration_mas.length())
	if player_acceleration_mas_history.size() > history_num_frames: # 如果历史记录超过最大帧数
		player_acceleration_mas_history.pop_front() # 移除最旧的
	# max
	var acceleration_max = player_acceleration_mas_history.max() # 获取历史记录中的最大
	GRAPH_MAX_ACCELERATION = acceleration_max if (acceleration_max and acceleration_max > GRAPH_MAX_ACCELERATION_MIN) else GRAPH_MAX_ACCELERATION_MIN
	# player_acceleration_pos
	var player_acceleration_pos = player.acceleration_pos
	player_acceleration_pos_history.push_back(player_acceleration_pos.length())
	if player_acceleration_pos_history.size() > history_num_frames: # 如果历史记录超过最大帧数
		player_acceleration_pos_history.pop_front() # 移除最旧的


	# speed_title
	speed_title.text = ("Speed: length up hor\n"
		+ HL.string_num_pad_decimals(player_velocity_mas, num_string_decimals, " ") + interval
		+ HL.string_num_pad_decimals(player.vel_up, num_string_decimals, " ") + interval
		+ HL.string_num_pad_decimals(player.vel_hor.length(), num_string_decimals, " ") + interval
		+ "\n"
		+ HL.string_num_pad_decimals(player_velocity_pos, num_string_decimals, " ") + interval
		+ HL.string_num_pad_decimals(player.velocity_up_pos, num_string_decimals, " ") + interval
		+ HL.string_num_pad_decimals(player.velocity_hor_pos.length(), num_string_decimals, " ") + interval
		)
	var frame_time_color := gradient.sample(remap(
		player_velocity_mas,
		GRAPH_MIN_SPEED,
		GRAPH_MAX_SPEED,
		0.0, 1.0))
	speed_title.modulate = frame_time_color

	# acceleration_title
	var _player_acceleration_mas_temp: float
	for x in range(1, 5): # 平滑显示 筛选数值
		if not player_acceleration_mas_history.is_empty() and player_acceleration_mas_history[- x] != 0:
			_player_acceleration_mas_temp = player_acceleration_mas_history[- x]

	var _player_acceleration_pos_temp: float
	for x in range(1, 5): # 平滑显示 筛选数值
		if not player_acceleration_pos_history.is_empty() and player_acceleration_pos_history[- x] != 0:
			_player_acceleration_pos_temp = player_acceleration_pos_history[- x]
	acceleration_title.text = ("Acceleration: length up hor\n"
		+ HL.string_num_pad_decimals(_player_acceleration_mas_temp, num_string_decimals, " ") + interval
		+ HL.string_num_pad_decimals(player.acceleration_up_mas, num_string_decimals, " ") + interval
		+ HL.string_num_pad_decimals(player.acceleration_hor_mas.length(), num_string_decimals, " ") + interval
		+ "\n"
		+ HL.string_num_pad_decimals(_player_acceleration_pos_temp, num_string_decimals, " ") + interval
		+ HL.string_num_pad_decimals(player.acceleration_up_pos, num_string_decimals, " ") + interval
		+ HL.string_num_pad_decimals(player.acceleration_hor_pos.length(), num_string_decimals, " ") + interval
		)
	frame_time_color = gradient.sample(remap(
		player_acceleration_mas.length(),
		GRAPH_MIN_ACCELERATION,
		GRAPH_MAX_ACCELERATION,
		0.2, 1.0))
	acceleration_title.modulate = frame_time_color


	# pos！！！！！！
	player_global_position.text = HL.format_vector_extended(player.global_position).all

	# jumping_time
	jumping_time.text = "JumpingTime:"
	jumping_time.text += HL.string_num_pad_decimals(player.jumpingtimer.get_time_left(), 2) if player.jumpingtimer else "0.00"
	jumping_height.text = "JumpingHeight:" + HL.string_num_pad_decimals(player.jumping_height, 2)

	floor_friction.text = "FloorFriction:" + str(player.floor_friction)
	movement_decelerate.text = "MovementDecelerate:" + str(player.movement_decelerate)
	air_damp.text = "AirDamp:" + str(player.air_damp)
	water_decelerate.text = "WaterDecelerate:" + str(player.water_decelerate)


	movement_state.text = "MovementState:" + player.movement_state_machine._current
	camera_state.text = "CameraState:" + player.camera_state_machine._current
	weapon.text = "Weapon:" + player.weapon_manager._current
	var _floor_angle: String = str(HL.string_num_pad_decimals(rad_to_deg(player.get_floor_angle(player.up_direction)), 3)) + "°" if player.is_on_floor() else forbidden
	floor_angle.text = "FloorAngle:" + _floor_angle

	danmaku_count.text = "Danmaku:" + str(get_tree().get_node_count_in_group("danmaku"))


func _speed_mas_graph_draw() -> void: # _speed_graph_draw函数
	_graph_draw(speed_graph, player_velocity_mas_history, GRAPH_MIN_SPEED, GRAPH_MAX_SPEED, Color.RED)


func _acceleration_mas_graph_draw() -> void:
	_graph_draw(acceleration_graph, player_acceleration_mas_history, GRAPH_MIN_ACCELERATION, GRAPH_MAX_ACCELERATION, Color.FUCHSIA)


func _speed_pos_graph_draw() -> void: # _speed_graph_draw函数
	_graph_draw(speed_graph, player_velocity_pos_history, GRAPH_MIN_SPEED, GRAPH_MAX_SPEED, Color(Color.GREEN, 0.7))


func _acceleration_pos_graph_draw() -> void:
	_graph_draw(acceleration_graph, player_acceleration_pos_history, GRAPH_MIN_ACCELERATION, GRAPH_MAX_ACCELERATION, Color(Color.LAWN_GREEN, 0.7))


func _graph_draw(_graph: Panel, _history: Array, _min: float, _max: float, color: Color, width: float = -1.0, antialiased: bool = false) -> void:
	var _polyline := PackedVector2Array() # 创建速度折线
	_polyline.resize(history_num_frames) # 调整速度折线的大小
	for i in _history.size(): # 遍历速度历史记录
		_polyline[i] = Vector2( # 设置速度折线的点
			remap(i,
				0, _history.size(),
				0, GRAPH_SIZE.x), # X坐标
			remap(clampf(_history[i], _min, _max),
				_min, _max,
				GRAPH_SIZE.y, 0.0)  # Y坐标
		)
	if _polyline.size() > 2:
		_graph.draw_polyline(_polyline, color, width, antialiased) # 绘制速度折线
