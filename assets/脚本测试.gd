@tool
extends Node3D


@onready var node: EarthAstronomyBasic = $Node
@onready var graph: Graph2D = $Node/Graph2D


var DisplayMode: Dictionary = {
	"Windowed": Window.Mode.MODE_WINDOWED,
	"Fullscreen": Window.Mode.MODE_FULLSCREEN,
	"Exclusive Fullscreen": Window.Mode.MODE_EXCLUSIVE_FULLSCREEN,
}


func _ready() -> void:
	print()
	print("Script testing: 脚本测试：")

#region New Code Region

	#for i in range(100):
		#var _in: int = randi_range(0, 255)
		#prints(_in, _in & 3, _in % 4, _in/4.0)
	#prints(1e-2, 1e05)

	#var vvvvvv = Vector3(3, 5, 8)
	#prints(vvvvvv * vvvvvv, vvvvvv.normalized() * vvvvvv.length()**2)
	#prints(AC)

	#var aaaa = TranslationServer.get_translation_object("")
	#print(aaaa)

	#var aaaa
	##aaaa = MathUtilsnext_power_of_two(2001)
	#aaaa = MathUtilsnearest_power_of_two(5)
#
	#prints(-4 ** 0.5, MathUtils.power(-4, 0.5))
	#prints(0 ** 0, pow(0, 0), MathUtils.power(0, 0))


	#for i in 24:
		#print(i- 90, " = ", node.latitude_humidity(float(i) - 90) * 100, " ")
		#print(node.diurnal_coeff(i, 6, 18))


	#var results = MathFunctionTester.test_function(
		#node.diurnal_coeff,            # 目标函数
		#[0],                   # 只测试x变量
		#[[0, 24, 1]],       # x定义域
		#[null, 6, 18, 1]      #
	#)
	#print("Smoothstep test results: ", results)
#
#
	## 设置坐标轴范围
	#graph.x_min = 0.0
	#graph.x_max = 24.0
	#graph.y_min = 1.0
	#graph.y_max = 2.0
#
	## 创建新的绘图项
	#var plot = graph.add_plot_item("My Data Plot", Color.GREEN_YELLOW, 2.0)
#
	#for i in range(results["inputs"].size()):
		#var x = results["inputs"][i][0]
		#var y = results["outputs"][i]
		#plot.add_point(Vector2(x, y))

	#var booool = 1 < 2 < 3

	#print(HL.parse_time("60?0000000000*wdf~36/99"), " CCCCCC")

	#var rs: String = HL.random_string(100, HL.LowercaseAlphabet)
	#var ad:= AlphabetDivision.split_like_english_words(rs, 4, 8)
	#prints("输入： ", rs, " 输出： ", ad)
	#var rs2: String = "helloingworldbeautifulstrength"
	#var ad2:= AlphabetDivision.split_like_english_words(rs2, 3, 8)
	#prints("输入： ", rs2, " 输出： ", ad2)
	#var rs3: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Quis ipsum suspendisse ultrices gravida. Risus commodo viverra maecenas accumsan lacus vel facilisis."
	#var ad3:= AlphabetDivision.split_like_english_words(rs3, 2, 12)
	#prints("输入： ", rs3, " 输出： ", ad3)

#endregion



	#print(DisplayMode.keys().find("Fullscreen"))

	print(str(Vector2(111, 223)))


#var ttt = 0
#func _input(event: InputEvent) -> void:
	#if event.is_action("mouse_wheel_down") or event.is_action("move_forward"):
		#ttt += 1
		#prints("_input", get_tree().get_frame(), ttt)
#

#func _process(delta: float) -> void:
	#ttt += 2
	#prints("_physics_process", get_tree().get_frame(), ttt)

	#var t = MathUtils.exponential_decay(0, 100, delta)
	#print("")
	#print(Global.paused_time_process, t)







pass
