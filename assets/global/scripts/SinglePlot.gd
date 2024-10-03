extends CanvasLayer

@onready var character_body_3d = $"../CharacterBody3D"

var Speed_plot
var Speed_temp: float
var Speed_history: Array[Vector2] = []

var Acceleration_plot
var Acceleration_temp: float
var Acceleration_history: Array[Vector2] = []

var time: float = 0.0

func _ready() -> void:
	Acceleration_plot = $Graph2D.add_plot_item("Acceleration_plot", Color.PURPLE, 0.5)
	Speed_plot = $Graph2D.add_plot_item("Speed_plot", Color.RED, 0.5)

func _process(delta: float) -> void:
	time += delta

	#for x in range(0, 11, 1):
		#var y = randf_range(0, 1)
		#my_plot.add_point(Vector2(x, y))

	#Speed_plot.remove_all()
	Speed_temp = character_body_3d.velocity.length()
	#Speed_plot.add_point(Vector2(time, Speed_temp))
	Speed_history.append(Vector2(time, Speed_temp))
	for x in range(0, $Graph2D.x_max + 1, 1):
		Speed_plot.add_point(Vector2(time, Speed_temp))

	Acceleration_temp = (character_body_3d.velocity.length() - Speed_temp) / delta
	Acceleration_plot.add_point(Vector2(time, Acceleration_temp))
	Acceleration_history.append(Vector2(time, Speed_temp))

	print(Acceleration_temp)
