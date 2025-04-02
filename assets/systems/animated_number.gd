# https://www.bilibili.com/video/BV1bf9yYSEPU/?spm_id_from=333.1007.tianma.2-1-4.click&vd_source=c94b03c06d9c9a8ac9161e5edeb2be10
extends Label
class_name AnimatedNumber

@export var duration: float = 1.0
@export var start_value: int = 999
@export var default_color: Color = Color.WHITE
@export var increasing_color: Color = Color.GREEN
@export var decreasing_color: Color = Color.CADET_BLUE

var real_value: int = 0: set = _set_real_value
var _fake_value: int = 0: set = _set_fake_value
var _tween: Tween


func _ready() -> void:
	_fake_value = start_value


func set_immediate(value: int) -> void:
	real_value = value
	_fake_value = value
	text = str(value)
	self.self_modulate = default_color


func _set_real_value(value: int) -> void:
	if real_value == value:
		return
	real_value = value
	_show_animation()


func _set_fake_value(value: int) -> void:
	_fake_value = value
	text = str(_fake_value)


func _show_animation() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	self.self_modulate = increasing_color if real_value > _fake_value else decreasing_color
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(self, "_fake_value", real_value, duration)
	_tween.finished.connect(func(): self.self_modulate = default_color)
