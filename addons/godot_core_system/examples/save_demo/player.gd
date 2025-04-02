extends Node

## 玩家基本属性
@export var player_name: String = "Player"
@export var player_level: int = 1
@export var player_exp: int = 0
@export var player_position: Vector2 = Vector2.ZERO

## 组件引用
@onready var serializable_component: SerializableComponent = $SerializableComponent

## 信号
signal stats_changed
signal position_changed(new_position: Vector2)

func _ready() -> void:
	# 注册需要序列化的属性
	serializable_component.register_property("player_name", player_name, 
		func(): return player_name,  # 序列化回调
		func(value): set_player_name(value)  # 反序列化回调
	)
	
	serializable_component.register_property("player_level", player_level,
		func(): return player_level,
		func(value): set_player_level(value)
	)
	
	serializable_component.register_property("player_exp", player_exp,
		func(): return player_exp,
		func(value): set_player_exp(value)
	)
	
	serializable_component.register_property("player_position", player_position,
		func(): return {"x": player_position.x, "y": player_position.y},
		func(value): set_player_position(Vector2(value.x, value.y))
	)

## 设置玩家名称
func set_player_name(new_name: String) -> void:
	if player_name != new_name:
		player_name = new_name
		stats_changed.emit()

## 设置玩家等级
func set_player_level(new_level: int) -> void:
	if player_level != new_level:
		player_level = new_level
		stats_changed.emit()

## 设置玩家经验
func set_player_exp(new_exp: int) -> void:
	if player_exp != new_exp:
		player_exp = new_exp
		stats_changed.emit()
		# 检查是否可以升级
		check_level_up()

## 设置玩家位置
func set_player_position(new_position: Vector2) -> void:
	if player_position != new_position:
		player_position = new_position
		position_changed.emit(new_position)

## 增加经验值
func add_exp(amount: int) -> void:
	set_player_exp(player_exp + amount)

## 检查是否可以升级
func check_level_up() -> void:
	# 简单的升级规则：每100经验升一级
	var exp_needed = player_level * 100
	if player_exp >= exp_needed:
		set_player_level(player_level + 1)
		set_player_exp(player_exp - exp_needed)
		print("玩家升级！现在等级：", player_level)

## 移动到指定位置
func move_to(target_position: Vector2) -> void:
	set_player_position(target_position)

## 获取玩家状态文本
func get_status_text() -> String:
	return """
	名称: %s
	等级: %d
	经验: %d
	位置: (%d, %d)
	""" % [player_name, player_level, player_exp, player_position.x, player_position.y]
