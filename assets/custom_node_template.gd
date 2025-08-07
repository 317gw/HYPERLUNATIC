# meta-name: Custom Node
# meta-description: 可高度自定义节点模板。
@tool
extends Node


# Tips:
# 脚本内定义的变量与通过 _get_property_list() 定义的变量会出现在 get_property_list() 中。
# 用 _get_property_list() 定义的变量无法直接在脚本内调用，只能用 get() 方法获得。
# 另一方面，直接在脚本内定义的变量无法调用 _get() 和 _set() 内覆写的方法。
# 总结下来，最佳的实践就是在脚本内定义变量后，再用 _get_property_list() 复写一次。


#region property define

# 注意：
# 在定义 get set 方法时，不能直接使用 get: return get() 定义方法，否则就会造成无限循环引用。
# 正确做法是使用 get: return _get() 或 get: return _get_process() 等自定义函数。

var sample_node: Node:
	get: return _get_process(&"sample_node")
	set(value): _set_process(&"sample_node", value)

# 内部自定义储存变量
var _internal_properties: Dictionary[StringName, Variant]

#endregion


#region property setting

func _get_property_list() -> Array[Dictionary]: return [

	# 格式注意：
	# class_name 仅适用于类型 Object
	# hint_string 提示之间不要留空格

	{
		"name": "sample_node",
		"class_name": "Node",
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_NODE_TYPE,
		"hint_string": "Node",
		"usage": PROPERTY_USAGE_DEFAULT,
	},

	{
		"name": "Sample Group 01",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP,
	},

	{
		"name": "sample_enum",
		"class_name": "",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Enum01,Enum02,Enum03",
		"usage": PROPERTY_USAGE_DEFAULT,
	},

	{
		"name": "sample_float",
		"class_name": "",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,5.0,0.1,or_greater",
		"usage": PROPERTY_USAGE_DEFAULT,
	},

	{
		"name": "Sample Sub Group",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_SUBGROUP,
	},

	{
		"name": "sample_string",
		"class_name": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
		"hint_string": "Place Holder",
		"usage": PROPERTY_USAGE_DEFAULT,
	},

	{
		"name": "sample_file",
		"class_name": "",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tscn,*.scn",
		"usage": PROPERTY_USAGE_DEFAULT,
	},

	{
		"name": "Sample Group 02",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP,
	},

	{
		"name": "sample_array",
		"class_name": "",
		"type": TYPE_ARRAY,
		"hint": PROPERTY_HINT_ARRAY_TYPE,
		"hint_string": "%d/%d:%s" % [
			TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "CompressedTexture2D"],
		"usage": PROPERTY_USAGE_DEFAULT,
	},

	{
		"name": "sample_dictionary",
		"class_name": "",
		"type": TYPE_DICTIONARY,
		"hint": PROPERTY_HINT_DICTIONARY_TYPE,
		"hint_string": "%d/%d:%s;%d/%d:%s" % [
			TYPE_OBJECT, PROPERTY_HINT_NODE_TYPE, "Node2D",
			TYPE_FLOAT, PROPERTY_HINT_RANGE, "0.0,1.0,0.1,or_greater"],
		"usage": PROPERTY_USAGE_DEFAULT,
	},

]


func _property_can_revert(property: StringName) -> bool:
	var prop_dict_can_revert: Dictionary[StringName, bool] = {
		"sample_node": true,
		"sample_enum": true,
		"sample_float": true,
		"sample_string": true,
		"sample_file": true,
		"sample_array": true,
		"sample_dictionary": true,
	}
	return prop_dict_can_revert.get(property, false)


func _property_get_revert(property: StringName) -> Variant:
	var prop_dict_get_revert: Dictionary[StringName, Variant] = {
		"sample_node": null,
		"sample_enum": 0,
		"sample_float": 5.0,
		"sample_string": "",
		"sample_file": "",
		"sample_array": [],
		"sample_dictionary": {},
	}
	return prop_dict_get_revert.get(property, null)


## 当属性列表中存在该属性时返回true。
func has_property(property: StringName) -> bool:
	for prop in get_property_list():
		if prop.get("name", "") == property: return true
	return false

#endregion


#region property setting advance

# 在 _get() 和 _set() 内覆写的方法，
# 只会作用于用 _get_property_list() 定义的变量，以及直接调用 get() 和 set() 的情况。

func _get(property: StringName) -> Variant:
	var property_list: Array[StringName] = [
		"sample_node",
		"sample_enum",
		"sample_float",
		"sample_string",
		"sample_file",
		"sample_array",
		"sample_dictionary",
	]
	if not property_list.has(property): return null
	return _get_process(property)


func _set(property: StringName, value: Variant) -> bool:
	var property_list: Array[StringName] = [
		"sample_node",
		"sample_enum",
		"sample_float",
		"sample_string",
		"sample_file",
		"sample_array",
		"sample_dictionary",
	]
	if not property_list.has(property): return false
	_set_process(property, value)
	return true


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if sample_node == null:
		warnings.append("节点警告示例：需要选择一个Sample Node节点")
	return warnings


## 用于覆写 get() 方法的执行。
func _get_process(property: StringName) -> Variant:
	var default: Variant = _property_get_revert(property)
	return _internal_properties.get(property, default)


## 用于覆写 set() 方法的执行。
func _set_process(property: StringName, value: Variant) -> void:
	update_configuration_warnings()

	_internal_properties.set(property, value)


func _refresh_inspector() -> void:
	var inspector: EditorInspector = EditorInterface.get_inspector()
	inspector.edit.call_deferred(null)
	inspector.edit.call_deferred(self)

#endregion


func _ready() -> void:
	if Engine.is_editor_hint(): return
