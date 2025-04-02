extends Node2D

const EventBus = CoreSystem.EventBus

var event_bus : EventBus = CoreSystem.event_bus

func _ready():
	# 启用调试模式和历史记录
	event_bus.debug_mode = true
	event_bus.enable_history = true
	
	# 1. 基本订阅（普通优先级）
	event_bus.subscribe("player_move", _on_player_move)
	
	# 2. 高优先级订阅
	event_bus.subscribe("player_move", _on_player_move_high_priority, 
		event_bus.Priority.HIGH)
	
	# 3. 低优先级订阅
	event_bus.subscribe("player_move", _on_player_move_low_priority, 
		event_bus.Priority.LOW)
	
	# 4. 一次性订阅
	event_bus.subscribe_once("player_attack", _on_player_attack_once)
	
	# 5. 带过滤器的订阅（只处理向右移动）
	event_bus.subscribe("player_move", _on_player_move_right,
		event_bus.Priority.NORMAL,
		false,
		func(payload): return payload[0] == "right"
	)
	
	# 延迟1秒后开始演示
	await get_tree().create_timer(1.0).timeout
	_start_demo()

## 开始演示
func _start_demo():
	print("\n=== 开始EventBus演示 ===")
	
	# 1. 测试不同优先级的事件处理
	print("\n1. 测试事件优先级：")
	event_bus.push_event("player_move", ["left", 100])
	
	# 2. 测试一次性订阅
	print("\n2. 测试一次性订阅：")
	event_bus.push_event("player_attack", ["sword", 50])
	print("再次触发player_attack事件（不会有响应）：")
	event_bus.push_event("player_attack", ["sword", 30])
	
	# 3. 测试事件过滤器
	print("\n3. 测试事件过滤器：")
	print("向左移动（过滤器不会响应）：")
	event_bus.push_event("player_move", ["left", 50])
	print("向右移动（过滤器会响应）：")
	event_bus.push_event("player_move", ["right", 50])
	
	# 4. 测试延迟事件
	print("\n4. 测试延迟事件：")
	event_bus.push_event("player_move", ["up", 100], false)
	
	# 5. 测试历史记录
	await get_tree().create_timer(0.5).timeout
	print("\n5. 显示事件历史：")
	var history = event_bus.get_event_history()
	for event in history:
		print("事件：%s，参数：%s" % [event.event_name, event.payload])
	
	print("\n=== EventBus演示结束 ===")

## 玩家移动事件回调
func _on_player_move(direction, distance):
	print("普通优先级：玩家向%s移动了%d单位" % [direction, distance])

## 高优先级玩家移动事件回调
func _on_player_move_high_priority(direction, distance):
	print("高优先级：玩家向%s移动了%d单位" % [direction, distance])

## 低优先级玩家移动事件回调
func _on_player_move_low_priority(direction, distance):
	print("低优先级：玩家向%s移动了%d单位" % [direction, distance])

## 一次性订阅事件回调
func _on_player_attack_once(weapon, damage):
	print("一次性订阅：玩家使用%s造成了%d点伤害" % [weapon, damage])


## 过滤器订阅事件回调
func _on_player_move_right(direction, distance):
	print("过滤器订阅：玩家向右移动了%d单位" % [distance])
