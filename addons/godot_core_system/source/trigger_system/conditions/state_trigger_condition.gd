extends TriggerCondition
class_name StateTriggerCondition

## 状态触发条件，条件示例

## 状态名称
@export var state_name : StringName
## 状态值
@export var required_state : StringName

func _init(config : Dictionary = {}) -> void:
	state_name = config.get("state_name", "")
	required_state = config.get("required_state", "")

func evaluate(context: Dictionary) -> bool:
	var p_state_name = context.get("state_name", "")
	var p_state_value = context.get("state_value", "")
	if state_name != p_state_name:
		return true
	return p_state_value == required_state
