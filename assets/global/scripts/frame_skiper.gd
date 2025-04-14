extends Node
class_name FrameSkiper

"""
*in _physics_process()*
该脚本的主要功能是通过设置一个目标物理帧率，并根据物理引擎当前的物理帧数，确定是否在一个“可执行帧”上，从而可以在指定的帧间隔内执行某些操作。它有助于在游戏中精准地控制更新逻辑的频率，尤其是在需要精确帧同步或者减少某些操作频率从而优化性能的场景中。

var frame_skiper: FrameSkiper
func _ready() -> void:
	frame_skiper = FrameSkiper.new(30, 6)
	self.add_child(frame_skiper)
func _physics_process(_delta: float) -> void:
	if frame_skiper.is_in_executable_frame():
"""

var skiped_delta: float = 0.0

var _randomize_frame: int = 0
var _frames_per_skip: int = 1


func _init(target_frames: int, randomize_frame_range: int = 0) -> void:
	if target_frames <= 0:
		push_error("目标帧数必须大于0")
		return
	self.set_process_mode(Node.PROCESS_MODE_PAUSABLE)
	if randomize_frame_range > 0:
		randomize()
		_randomize_frame = randi_range(0, randomize_frame_range)
	var physics_ticks_per_second = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
	_frames_per_skip = max(1, floori(physics_ticks_per_second / target_frames) )


"""
跳帧后实际需要的delta会变化，使用skiped_delta代表需要的delta，通过在_physics_process函数中给skiped_delta累加_physics_process函数的delta来计算skiped_delta，因为根据程序的运行情况_physics_process函数上的delta会变化它代表了更加准确的时间变化。现在如何确定在_physics_process函数中给skiped_delta累加delta和判定条件给skiped_delta清零的执行顺序
"""
func _physics_process(delta: float) -> void:
	if is_in_executable_frame():
		skiped_delta = 0.0
	skiped_delta += delta


func is_in_executable_frame() -> bool: ## 确定是否在“可执行帧”上
	return Engine.get_physics_frames() % _frames_per_skip == _randomize_frame % _frames_per_skip
	#return (Engine.get_physics_frames() + _randomize_frame) % _frames_per_skip == 0


func skip_frame() -> bool:
	return Engine.get_physics_frames() % _frames_per_skip != _randomize_frame % _frames_per_skip
