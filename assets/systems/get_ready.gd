class_name GetReady
extends Node

var _condition: Callable = func(): return true
var _function: Callable = func(): pass

# add_child(GetReady.new(func(): return Global.sky_limit, _set_curve))
func _init(condition: Callable, function: Callable) -> void:
	_condition = condition
	_function = function

func _process(delta: float) -> void:
	if _condition.call():
		_function.call_deferred()
		self.queue_free()
