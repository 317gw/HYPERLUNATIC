extends Control

@onready var speed_graph: Panel = $Graphs/SpeedGraph/Graph # 速度图表的引用
@onready var acceleration_graph: Panel = $Graphs/AccelerationGraph/Graph

@onready var speed_title = $Graphs/SpeedGraph/Title
@onready var acceleration_title = $Graphs/AccelerationGraph/Title

@onready var player_global_position: Label = $Graphs/GlobalPosition
@onready var jumping_time = $Graphs/JumpingTime
@onready var jumping_height = $Graphs/JumpingHeight
@onready var danmaku_count: Label = $Graphs/DanmakuCount

var player: HL.Player

var HISTORY_NUM_FRAMES = 150 # 历史帧数

var speed_history: Array[float] = [] # 速度历史记录，用于图表
var speed_xz_history: Array[float] = []
var acceleration_history: Array[float] = []
var acceleration_xz_history: Array[float] = []

var GRAPH_SIZE := Vector2(150, 25) # 图表尺寸

var GRAPH_MAX_SPEED: float = 10 # 图表最大速度
var GRAPH_MAX_ACCELERATION: float = 10

const GRAPH_MAX_SPEED_MIN = 10 # 图表最小最大速度
const GRAPH_MAX_ACCELERATION_MIN = 10

const GRAPH_MIN_SPEED = 0 # 图表最小速度
const GRAPH_MIN_ACCELERATION = 0

var Speed_temp: float = 0
var Speed_xz_temp: float = 0

var JumpingHeight_temp: float = 0

var gradient := Gradient.new()


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
	HISTORY_NUM_FRAMES = speed_graph.size.x * 200 / 480

	speed_graph.draw.connect(_speed_graph_draw) # 连接图表绘制信号
	acceleration_graph.draw.connect(_acceleration_graph_draw)

	speed_history.resize(HISTORY_NUM_FRAMES) # 调整速度历史记录的大小
	speed_xz_history.resize(HISTORY_NUM_FRAMES)
	acceleration_history.resize(HISTORY_NUM_FRAMES)
	acceleration_xz_history.resize(HISTORY_NUM_FRAMES)


func _up_title(delta: float) -> void:
	if not player:
		return

	# 2 player_speed
	var player_speed = player.velocity.length() # 获取玩家速度
	speed_history.push_back(player_speed) # 将速度添加到历史记录
	if speed_history.size() > HISTORY_NUM_FRAMES: # 如果历史记录超过最大帧数
		speed_history.pop_front() # 移除最旧的速度
	# xz
	var player_speed_xz := Vector3(player.velocity.x, 0, player.velocity.z).length()
	speed_xz_history.push_back(player_speed_xz) # 将速度添加到历史记录
	if speed_xz_history.size() > HISTORY_NUM_FRAMES: # 如果历史记录超过最大帧数
		speed_xz_history.pop_front() # 移除最旧的速度
	# max
	var speed_max = speed_history.max() # 获取历史记录中的最大速度
	GRAPH_MAX_SPEED = speed_max if (speed_max and speed_max > GRAPH_MAX_SPEED_MIN) else GRAPH_MAX_SPEED_MIN


	# 2 player_acceleration
	var player_acceleration = (player.velocity.length() - Speed_temp) / delta
	acceleration_history.push_back(player_acceleration)
	Speed_temp = player.velocity.length()
	if acceleration_history.size() > HISTORY_NUM_FRAMES: # 如果历史记录超过最大帧数
		acceleration_history.pop_front() # 移除最旧的
	# xz
	var player_acceleration_xz = (
		Vector3(player.velocity.x, 0, player.velocity.z).length()
		- Speed_xz_temp) / delta
	acceleration_xz_history.push_back(player_acceleration_xz)
	Speed_xz_temp = Vector3(player.velocity.x, 0, player.velocity.z).length()
	if acceleration_xz_history.size() > HISTORY_NUM_FRAMES: # 如果历史记录超过最大帧数
		acceleration_xz_history.pop_front() # 移除最旧的
	# max
	var acceleration_max = acceleration_history.max() # 获取历史记录中的最大
	GRAPH_MAX_ACCELERATION = acceleration_max if (acceleration_max and acceleration_max > GRAPH_MAX_ACCELERATION_MIN) else GRAPH_MAX_ACCELERATION_MIN


	# pos！！！！！！
	player_global_position.text = HL.format_vector_extended(player.global_position).all

	# speed_title
	speed_title.text = ("Speed↓\n"
		+ str(floor(player_speed * 100) / 100) + "\n"
		+ str(floor(player_speed_xz * 100) / 100))
	var frame_time_color := gradient.sample(remap(
		player_speed,
		GRAPH_MIN_SPEED,
		GRAPH_MAX_SPEED,
		0.0, 1.0))
	speed_title.modulate = frame_time_color

	# acceleration_title
	var player_acceleration_temp: float
	var player_acceleration_xz_temp: float
	for x in range(1, 5): # 平滑显示 筛选数值
		if not acceleration_history.is_empty() and acceleration_history[- x] != 0:
			player_acceleration_temp = acceleration_history[- x]
	for x in range(1, 10):
		if not acceleration_xz_history.is_empty() and acceleration_xz_history[- x] != 0:
			player_acceleration_xz_temp = acceleration_xz_history[- x]
	acceleration_title.text = ("Acceleration↓\n"
		 + str(floor(player_acceleration_temp * 100) / 100) + "\n"
		 + str(floor(player_acceleration_xz_temp * 100) / 100))
	frame_time_color = gradient.sample(remap(
		player_acceleration,
		GRAPH_MIN_ACCELERATION,
		GRAPH_MAX_ACCELERATION,
		0.2, 1.0))
	acceleration_title.modulate = frame_time_color

	# jumping_time
	if player.jumpingtimer:
		jumping_time.text = ("JumpingTime:" + str(floor(player.jumpingtimer.get_time_left() * 100) / 100))
	jumping_height.text = ("JumpingHeight:" + str(floor(player.jumping_height * 100) / 100))


	danmaku_count.text = "Danmaku:" + str(get_tree().get_node_count_in_group("danmaku"))




func _speed_graph_draw() -> void: # _speed_graph_draw函数
	_graph_draw(speed_graph, speed_history, GRAPH_MIN_SPEED, GRAPH_MAX_SPEED, Color.RED)


func _acceleration_graph_draw() -> void:
	_graph_draw(acceleration_graph, acceleration_history, GRAPH_MIN_ACCELERATION, GRAPH_MAX_ACCELERATION, Color.FUCHSIA)


func _graph_draw(_graph: Panel, _history: Array, _min: float, _max: float, color: Color, width: float = -1.0, antialiased: bool = false) -> void:
	var _polyline := PackedVector2Array() # 创建速度折线
	_polyline.resize(HISTORY_NUM_FRAMES) # 调整速度折线的大小
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
