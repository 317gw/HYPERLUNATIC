class_name GetReady
extends Node

signal condition_ready

var _condition: Callable = func(): return true
var _function: Callable = func(): pass

# add_child(GetReady.new(func(): return Global.sky_limit, _set_curve))
func _init(condition: Callable = _condition, function: Callable = _function) -> void:
	_condition = condition
	_function = function

func _process(delta: float) -> void:
	if _condition.call():
		_function.call_deferred()
		condition_ready.emit()
		self.queue_free()
