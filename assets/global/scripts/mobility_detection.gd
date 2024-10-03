extends CanvasLayer # 继承自CanvasLayer

@onready var player: Player = $"../Player" # 3D角色体的引用

@onready var speed_graph: Panel = $DebugMenu/VBoxContainer/Graphs/SpeedGraph/Graph # 速度图表的引用
@onready var acceleration_graph: Panel = $DebugMenu/VBoxContainer/Graphs/AccelerationGraph/Graph

@onready var speed_title = $DebugMenu/VBoxContainer/Graphs/SpeedGraph/Title
@onready var acceleration_title = $DebugMenu/VBoxContainer/Graphs/AccelerationGraph/Title

@onready var jumping_time = $DebugMenu/VBoxContainer/Graphs/JumpingTime
@onready var jumping_height = $DebugMenu/VBoxContainer/Graphs/JumpingHeight

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
	GRAPH_SIZE = speed_graph.size # 初始化图表尺寸
	HISTORY_NUM_FRAMES = speed_graph.size.x * 200 / 480

	speed_graph.draw.connect(_speed_graph_draw) # 连接图表绘制信号
	acceleration_graph.draw.connect(_acceleration_graph_draw)

	speed_history.resize(HISTORY_NUM_FRAMES) # 调整速度历史记录的大小
	speed_xz_history.resize(HISTORY_NUM_FRAMES)
	acceleration_history.resize(HISTORY_NUM_FRAMES)
	acceleration_xz_history.resize(HISTORY_NUM_FRAMES)

	# NOTE: Both FPS and frametimes are colored following FPS logic
	# (red = 10 FPS, yellow = 60 FPS, green = 110 FPS, cyan = 160 FPS).
	# This makes the color gradient non-linear.
	# Colors are taken from <https://tailwindcolor.com/>.
	gradient.set_color(0, Color8(239, 68, 68)) # red-500
	gradient.set_color(1, Color8(56, 189, 248)) # light-blue-400
	gradient.add_point(0.3333, Color8(250, 204, 21)) # yellow-400
	gradient.add_point(0.6667, Color8(128, 226, 95)) # 50-50 mix of lime-400 and green-400

func _physics_process(delta: float) -> void:
	speed_graph.queue_redraw() # 请求图表重绘
	acceleration_graph.queue_redraw()

	var player_speed = player.velocity.length() # 获取玩家速度
	speed_history.push_back(player_speed) # 将速度添加到历史记录
	if speed_history.size() > HISTORY_NUM_FRAMES: # 如果历史记录超过最大帧数
		speed_history.pop_front() # 移除最旧的速度

	var player_speed_xz := Vector3(player.velocity.x, 0, player.velocity.z).length()
	speed_xz_history.push_back(player_speed_xz) # 将速度添加到历史记录
	if speed_xz_history.size() > HISTORY_NUM_FRAMES: # 如果历史记录超过最大帧数
		speed_xz_history.pop_front() # 移除最旧的速度

	var speed_max = speed_history.max() # 获取历史记录中的最大速度
	if speed_max and speed_max > GRAPH_MAX_SPEED_MIN: # 如果最大速度存在且大于最小最大速度
		GRAPH_MAX_SPEED = speed_max # 图表最大速度等于最大速度
	else: # 否则
		GRAPH_MAX_SPEED = GRAPH_MAX_SPEED_MIN # 图表最大速度等于最小最大速度

	speed_title.text = ("Speed↓\n"
		+ str(floor(player_speed * 100) / 100) + "\n"
		+ str(floor(player_speed_xz * 100) / 100))
	var frame_time_color := gradient.sample(remap(
		player_speed,
		GRAPH_MIN_SPEED,
		GRAPH_MAX_SPEED,
		0.0, 1.0))
	speed_title.modulate = frame_time_color

	# 2 player_acceleration
	var player_acceleration = (player.velocity.length() - Speed_temp) / delta
	acceleration_history.push_back(player_acceleration)
	Speed_temp = player.velocity.length()
	if acceleration_history.size() > HISTORY_NUM_FRAMES: # 如果历史记录超过最大帧数
		acceleration_history.pop_front() # 移除最旧的

	var player_acceleration_xz = (
		Vector3(player.velocity.x, 0, player.velocity.z).length()
		- Speed_xz_temp) / delta
	acceleration_xz_history.push_back(player_acceleration_xz)
	Speed_xz_temp = Vector3(player.velocity.x, 0, player.velocity.z).length()
	if acceleration_xz_history.size() > HISTORY_NUM_FRAMES: # 如果历史记录超过最大帧数
		acceleration_xz_history.pop_front() # 移除最旧的

	var acceleration_max = acceleration_history.max() # 获取历史记录中的最大
	if acceleration_max and acceleration_max > GRAPH_MAX_ACCELERATION_MIN:
		GRAPH_MAX_ACCELERATION = acceleration_max
	else:
		GRAPH_MAX_ACCELERATION = GRAPH_MAX_ACCELERATION_MIN

	var player_acceleration_temp: float
	var player_acceleration_xz_temp: float
	for x in range(1, 5): # 平滑显示 筛选数值
		if acceleration_history[- x] != 0:
			player_acceleration_temp = acceleration_history[- x]
	for x in range(1, 10):
		if acceleration_xz_history[- x] != 0:
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

	if player.jumpingtimer:
		jumping_time.text = ("JumpingTime:" + str(floor(player.jumpingtimer.get_time_left() * 100) / 100))
	jumping_height.text = ("JumpingHeight:" + str(floor(player.jumping_height * 100) / 100))
	jumping_height.text = ("JumpingHeight:"
		 + str(floor(player.jumping_height * 100) / 100) + "\n"
		 + str(floor(player.jumping_height * 100) / 100))

func _speed_graph_draw() -> void: # _speed_graph_draw函数
	var speed_polyline := PackedVector2Array() # 创建速度折线
	speed_polyline.resize(HISTORY_NUM_FRAMES) # 调整速度折线的大小
	for speed_index in speed_history.size(): # 遍历速度历史记录
		speed_polyline[speed_index] = Vector2( # 设置速度折线的点
				# X坐标
				remap(speed_index, 0, speed_history.size(), 0, GRAPH_SIZE.x),
				# Y坐标
				remap(clampf(speed_history[speed_index], GRAPH_MIN_SPEED, GRAPH_MAX_SPEED), GRAPH_MIN_SPEED, GRAPH_MAX_SPEED, GRAPH_SIZE.y, 0.0)
		)
	speed_graph.draw_polyline(speed_polyline, Color.RED, 1.0) # 绘制速度折线，使用红色

func _acceleration_graph_draw() -> void:
	var acceleration_polyline := PackedVector2Array() # 创建速度折线
	acceleration_polyline.resize(HISTORY_NUM_FRAMES) # 调整速度折线的大小
	for acceleration_index in acceleration_history.size(): # 遍历速度历史记录
		acceleration_polyline[acceleration_index] = Vector2( # 设置速度折线的点
				# X坐标
				remap(acceleration_index, 0, acceleration_history.size(), 0, GRAPH_SIZE.x),
				# Y坐标
				remap(clampf(acceleration_history[acceleration_index], GRAPH_MIN_ACCELERATION, GRAPH_MAX_ACCELERATION), GRAPH_MIN_ACCELERATION, GRAPH_MAX_ACCELERATION, GRAPH_SIZE.y, 0.0)
		)
	acceleration_graph.draw_polyline(acceleration_polyline, Color.FUCHSIA, 1.0) # 绘制速度折线
# E 0:03:14:0818   instance_set_transform: Condition "!v.is_finite()" is true.
#  <C++ 源文件>      servers/rendering/renderer_scene_cull.cpp:922 @ instance_set_transform()
