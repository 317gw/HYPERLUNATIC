class_name CallOnceWhenNeeded
extends RefCounted

var target_func: Callable # 存储目标函数
var func_args: Array = [] # 存储函数参数
var has_pending_call: bool = false # 标记是否有等待执行的调用

## 构造函数，接收目标函数
func _init(callable: Callable) -> void:
	target_func = callable

## 呼叫函数（仅标记，不立即执行）
func call_with_args(args: Array = []) -> void:
	has_pending_call = true
	# 保存最新的参数
	func_args = args.duplicate()

## 执行已标记的函数调用（如果有的话）
func execute_if_needed() -> void:
	if has_pending_call and target_func.is_valid():
		# 执行函数调用
		target_func.callv(func_args)
		# 重置状态
		has_pending_call = false
		func_args.clear()

## 重置状态，取消等待中的调用
func reset() -> void:
	has_pending_call = false
	func_args.clear()

## 检查是否有等待执行的调用
func has_pending() -> bool:
	return has_pending_call
