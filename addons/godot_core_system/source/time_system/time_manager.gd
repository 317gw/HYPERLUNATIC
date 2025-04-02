extends Node

signal time_scale_changed(new_scale: float)
signal timer_completed(timer_id: String)
signal time_state_changed(is_paused: bool)

## 计时器数据结构
class GameTimer:
	var id: String
	var duration: float
	var elapsed: float
	var loop: bool
	var paused: bool
	var callback: Callable
	
	func _init(p_id: String, p_duration: float, p_loop: bool = false, p_callback: Callable = Callable()):
		id = p_id
		duration = p_duration
		elapsed = 0.0
		loop = p_loop
		paused = false
		callback = p_callback

var _time_scale: float = 1.0
var _paused: bool = false
var _timers: Dictionary = {}
var _game_time: float = 0.0

func _process(delta: float):
	if _paused:
		return
	
	var scaled_delta = delta * _time_scale
	_game_time += scaled_delta
	
	# 更新所有计时器
	var completed_timers = []
	
	for timer in _timers.values():
		if timer.paused:
			continue
		
		timer.elapsed += scaled_delta
		if timer.elapsed >= timer.duration:
			if timer.callback.is_valid():
				timer.callback.call()
			
			timer_completed.emit(timer.id)
			
			if timer.loop:
				timer.elapsed = 0.0
			else:
				completed_timers.append(timer.id)
	
	# 移除已完成的非循环计时器
	for timer_id in completed_timers:
		_timers.erase(timer_id)

## 设置时间缩放
func set_time_scale(scale: float) -> void:
	_time_scale = max(0.0, scale)
	time_scale_changed.emit(_time_scale)

## 获取时间缩放
func get_time_scale() -> float:
	return _time_scale

## 暂停/恢复时间
func set_paused(paused: bool) -> void:
	_paused = paused
	time_state_changed.emit(_paused)

## 检查是否暂停
func is_paused() -> bool:
	return _paused

## 获取游戏运行时间
func get_game_time() -> float:
	return _game_time

## 创建计时器
func create_timer(id: String, duration: float, loop: bool = false, 
				 callback: Callable = Callable()) -> void:
	if has_timer(id):
		push_warning("Timer with id '%s' already exists. Overwriting..." % id)
	
	_timers[id] = GameTimer.new(id, duration, loop, callback)

## 暂停计时器
func pause_timer(timer_id: String) -> bool:
	if has_timer(timer_id):
		_timers[timer_id].paused = true
		return true
	return false

## 恢复计时器
func resume_timer(timer_id: String) -> bool:
	if has_timer(timer_id):
		_timers[timer_id].paused = false
		return true
	return false
	
## 重置计时器
func reset_timer(timer_id: String) -> bool:
	if has_timer(timer_id):
		_timers[timer_id].elapsed = 0.0
		return true
	return false

## 移除计时器
func remove_timer(timer_id: String) -> void:
	_timers.erase(timer_id)

## 获取计时器剩余时间
func get_timer_remaining(timer_id: String) -> float:
	if has_timer(timer_id):
		return max(0.0, _timers[timer_id].duration - _timers[timer_id].elapsed)
	return 0.0

## 检查计时器是否存在
func has_timer(timer_id: String) -> bool:
	return _timers.has(timer_id)

## 清除所有计时器
func clear_all_timers() -> void:
	_timers.clear()
