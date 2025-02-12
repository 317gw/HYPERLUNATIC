extends CanvasLayer

@onready var fps_graph: Panel = $DebugMenu/VBoxContainer/Graphs/SpeedGraph/Graph
@onready var graph = $DebugMenu/VBoxContainer/Graphs/SpeedGraph/Graph
#@onready var speed_graph: Panel = $DebugMenu/VBoxContainer/Graphs/SpeedGraph

const HISTORY_NUM_FRAMES = 150

var fps_history: Array[float] = []  # Only used for graphs.

var frametime_avg := GRAPH_MIN_FRAMETIME

const GRAPH_SIZE = Vector2(150, 25)
const GRAPH_MIN_FPS = 10
const GRAPH_MAX_FPS = 170
const GRAPH_MIN_FRAMETIME = 1.0 / GRAPH_MIN_FPS
const GRAPH_MAX_FRAMETIME = 1.0 / GRAPH_MAX_FPS

var frame_time_gradient := Gradient.new()

var frames_per_second := float(GRAPH_MIN_FPS)

var last_tick := 0

func _ready() -> void:
	fps_graph.draw.connect(_fps_graph_draw)
	fps_history.resize(HISTORY_NUM_FRAMES)
	
	var frametime_last := (Time.get_ticks_usec() - last_tick) * 0.001
	fps_history.fill(1000.0 / frametime_last)


func _process(_delta: float) -> void:
	fps_graph.queue_redraw()
	
	# var frametime := (Time.get_ticks_usec() - last_tick) * 0.001
	
	frames_per_second = 1000.0 / frametime_avg
	fps_history.push_back(frames_per_second)
	if fps_history.size() > HISTORY_NUM_FRAMES:
		fps_history.pop_front()


func _fps_graph_draw() -> void:
	var fps_polyline := PackedVector2Array()
	fps_polyline.resize(HISTORY_NUM_FRAMES)
	for fps_index in fps_history.size():
		fps_polyline[fps_index] = Vector2(
				remap(fps_index, 0, fps_history.size(), 0, GRAPH_SIZE.x),
				remap(clampf(fps_history[fps_index], GRAPH_MIN_FPS, GRAPH_MAX_FPS), GRAPH_MIN_FPS, GRAPH_MAX_FPS, GRAPH_SIZE.y, 0.0))
	fps_graph.draw_polyline(fps_polyline, frame_time_gradient.sample(remap(frames_per_second, GRAPH_MIN_FPS, GRAPH_MAX_FPS, 0.0, 1.0)), 1.0)
