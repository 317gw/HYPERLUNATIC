# by 摇滚烤面包机
extends RefCounted
class_name SignalAwaiter

var check_pass: bool
var wait_signal: Signal
var wait_condition: Callable

func _init(
		_wait_signal: Signal,
		_wait_condition: Callable,
		) -> void:
	check_pass = false
	wait_signal = _wait_signal
	wait_condition = _wait_condition

func _check_condition(value: Variant) -> void:
	check_pass = wait_condition.call(value) as bool

func check_out() -> void:
	if not wait_signal.is_connected(_check_condition):
		wait_signal.connect(_check_condition)
	while not check_pass: await wait_signal
	check_pass = false
	wait_signal.disconnect(_check_condition)
