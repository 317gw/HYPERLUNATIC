extends TriggerCondition
class_name CompositeTriggerCondition

## 组合触发条件

@export var conditions : Array[TriggerCondition]
@export_enum("AND", "OR", "XOR", "NAND", "NOR") var operator : String = "AND"

func _init(config : Dictionary = {}) -> void:
	for condition_config in config.get("conditions", {}):
		conditions.append(TriggerCondition.new(condition_config))
	operator = config.get("operator", "AND")

func evaluate(context: Dictionary) -> bool:
	match operator:
		"AND":
			return conditions.all(func(condition : TriggerCondition) -> bool: return condition.evaluate(context))
		"OR":
			return conditions.any(func(condition : TriggerCondition) -> bool: return condition.evaluate(context))
		"XOR":
			# XOR is equivalent to having an odd number of true values
			var result : Array[bool] = conditions.map(func(condition : TriggerCondition) -> bool: return condition.evaluate(context))
			return result.count(true) % 2 == 1
		"NAND":
			# NAND is equivalent to not (AND)
			return not conditions.all(func(condition : TriggerCondition) -> bool: return condition.evaluate(context))
		"NOR":
			# NOR is equivalent to not (OR)
			return not conditions.any(func(condition : TriggerCondition) -> bool: return condition.evaluate(context))
		_:
			return false
