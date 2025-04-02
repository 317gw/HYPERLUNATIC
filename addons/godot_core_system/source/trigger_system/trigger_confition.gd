extends Resource
class_name TriggerCondition

## 触发条件
func _init(config : Dictionary = {}) -> void:
	pass

func evaluate(context: Dictionary) -> bool:
	return true
