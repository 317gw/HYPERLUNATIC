extends Resource
class_name GameplayTrigger

## 触发器

enum TRIGGER_TYPE {
	IMMEDIATE,				## 立即触发
	ON_EVENT,				## 侦听事件触发
	PERIODIC				## 周期触发
}

@export var trigger_type : TRIGGER_TYPE = TRIGGER_TYPE.IMMEDIATE	## 触发类型
@export var conditions : Array[TriggerCondition] = []				## 触发条件
@export var persistent : bool = false								## 是否持久化
@export var max_triggers : int = -1								## 最大触发次数
@export_storage var trigger_count : int = 0						## 触发次数
@export var trigger_event : StringName = ""							## 触发事件
@export var period : float = 1.0									## 周期
@export var trigger_chance: float = 1.0							## 触发概率

var _time_since_last_tirgger : float = 0.0						
var _is_active : bool = false
var _context : Dictionary = {}

var _trigger_manager: CoreSystem.TriggerManager:
	get:
		if not _trigger_manager:
			_trigger_manager = CoreSystem.trigger_manager
		return _trigger_manager


signal triggered(context: Dictionary)


## 构造触发器
func _init(config : Dictionary = {}) -> void:
	for condition_config in config.get("conditions", {}):
		var condition : TriggerCondition = _trigger_manager.create_condition(condition_config)
		if condition:
			conditions.append(condition)
	persistent = config.get("persistent", false)
	max_triggers = config.get("max_triggers", -1)
	trigger_count = config.get("trigger_count", 0)
	trigger_type = config.get("trigger_type", TRIGGER_TYPE.IMMEDIATE)
	period = config.get("period", 1.0)
	trigger_chance = config.get("trigger_chance", 1.0)
	trigger_event = config.get("trigger_event", "")


## 激活触发器
func activate(initial_context : Dictionary = {}) -> void:
	if _is_active:
		CoreSystem.logger.warning("Trigger is already active")
		return
	_is_active = true

	match trigger_type:
		TRIGGER_TYPE.IMMEDIATE:
			_try_trigger(initial_context)
		TRIGGER_TYPE.ON_EVENT:
			if trigger_event.is_empty():
				CoreSystem.logger.warning("Trigger event is empty")
			else:
				_trigger_manager.register_event_trigger(trigger_event, self)
		TRIGGER_TYPE.PERIODIC:
			_trigger_manager.register_periodic_trigger(self)

	_context = initial_context


## 停用触发器
func deactivate() -> void:
	if not _is_active:
		CoreSystem.logger.warning("Trigger is not active")
		return
	_is_active = false
	
	match trigger_type:
		TRIGGER_TYPE.ON_EVENT:
			if trigger_event.is_empty():
				CoreSystem.logger.warning("Trigger event is empty")
			else:
				_trigger_manager.unregister_event_trigger(trigger_event, self)
		TRIGGER_TYPE.PERIODIC:
			_trigger_manager.unregister_periodic_trigger(self)

	_context.clear()


func update(delta : float) -> void:
	if not _is_active:
		return
	if trigger_type == TRIGGER_TYPE.PERIODIC:
		_time_since_last_tirgger += delta
		if _time_since_last_tirgger >= period:
			_time_since_last_tirgger -= period
			_try_trigger(_context)


## 判断是否触发
func should_trigger(context : Dictionary) -> bool:
	return conditions.all(func(condition : TriggerCondition) -> bool: return condition.evaluate(context))


## 触发
func execute(context: Dictionary) -> void:
	_try_trigger(context)


## 尝试触发
func _try_trigger(context: Dictionary) -> void:
	# 触发次数达到限制
	if max_triggers > 0 and trigger_count >= max_triggers:
		CoreSystem.logger.debug("Trigger count reached limit")
		return
	
	# 概率不满足
	if randf() > trigger_chance:
		CoreSystem.logger.debug("Trigger chance not satisfied")
		return

	## 条件不满足
	if not should_trigger(context):
		CoreSystem.logger.debug("Trigger conditions not satisfied")
		return

	trigger_count += 1
	triggered.emit(context)


func reset() -> void:
	trigger_count = 0
	_time_since_last_tirgger = 0.0
