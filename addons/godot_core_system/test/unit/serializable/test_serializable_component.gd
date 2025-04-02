extends GutTest

# 测试数据
const TEST_DATA := {
	"position": Vector2(100, 200),
	"health": 100,
	"inventory": ["sword", "shield", "potion"],
	"stats": {
		"strength": 15,
		"dexterity": 12,
		"intelligence": 10
	}
}

class TestSerializable extends SerializableComponent:
	var _position: Vector2
	var _health: int
	var _inventory: Array
	var _stats: Dictionary
	
	func _init() -> void:
		_position = Vector2()
		_health = 0
		_inventory = []
		_stats = {}
		
		# 注册基本属性，并设置 getter/setter
		register_property("position", _position)
		register_property("health", _health)
		register_property("inventory", _inventory)
		register_property("stats", _stats)
	
var _test_obj: TestSerializable
var _property_changed_count := 0
var _last_changed_property := ""
var _last_changed_value = null

func before_each():
	_test_obj = TestSerializable.new()
	add_child(_test_obj)
	
	# 连接信号
	_test_obj.property_changed.connect(_on_property_changed)
	_property_changed_count = 0
	_last_changed_property = ""
	_last_changed_value = null
	
	await get_tree().process_frame

func after_each():
	if is_instance_valid(_test_obj):
		if _test_obj.property_changed.is_connected(_on_property_changed):
			_test_obj.property_changed.disconnect(_on_property_changed)
		_test_obj.queue_free()
	_test_obj = null
	await get_tree().process_frame


func _on_property_changed(property: String, value: Variant) -> void:
	_property_changed_count += 1
	_last_changed_property = property
	_last_changed_value = value


func test_register_property():
	# 测试注册新属性
	_test_obj.register_property("test_prop", "default")
	assert_eq(_test_obj.get_property("test_prop"), "default")
	
	# 测试更新属性值
	_test_obj.set_property("test_prop", "new_value")
	assert_eq(_test_obj.get_property("test_prop"), "new_value")
	assert_eq(_property_changed_count, 1)
	assert_eq(_last_changed_property, "test_prop")
	assert_eq(_last_changed_value, "new_value")


func test_serialize_basic():
	# 设置基本属性值
	_test_obj.set_property("position", TEST_DATA.position)
	_test_obj.set_property("health", TEST_DATA.health)
	_test_obj.set_property("inventory", TEST_DATA.inventory.duplicate())
	_test_obj.set_property("stats", TEST_DATA.stats.duplicate())
	
	# 等待属性更新
	await get_tree().process_frame
	
	# 序列化并验证
	var serialized = _test_obj.serialize()
	assert_eq(serialized.position, TEST_DATA.position)
	assert_eq(serialized.health, TEST_DATA.health)
	assert_eq(serialized.inventory, TEST_DATA.inventory)
	assert_eq(serialized.stats, TEST_DATA.stats)

func test_deserialize_basic():
	# 反序列化数据
	_test_obj.deserialize(TEST_DATA)
	
	# 等待属性更新
	await get_tree().process_frame
	
	# 验证属性值
	assert_eq(_test_obj.get_property("position"), TEST_DATA.position)
	assert_eq(_test_obj.get_property("health"), TEST_DATA.health)
	assert_eq(_test_obj.get_property("inventory"), TEST_DATA.inventory)
	assert_eq(_test_obj.get_property("stats"), TEST_DATA.stats)

func test_signals():
	# 使用数组来存储数据，这样可以在闭包中修改
	var data_store := {
		"serialized": null,
		"deserialized": null
	}
	
	# 连接序列化信号
	_test_obj.serialized.connect(func(data): data_store.serialized = data)
	_test_obj.deserialized.connect(func(data): data_store.deserialized = data)
	
	# 设置初始数据并序列化
	_test_obj.set_property("health", 100)
	await get_tree().process_frame
	
	var data = _test_obj.serialize()
	
	# 验证序列化信号
	assert_not_null(data_store.serialized, "序列化信号应该被触发")
	assert_eq(data_store.serialized, data, "序列化数据应该匹配")
	
	# 反序列化并验证
	var test_data = {"health": 200}
	_test_obj.deserialize(test_data)
	await get_tree().process_frame
	
	# 验证反序列化信号
	assert_not_null(data_store.deserialized, "反序列化信号应该被触发")
	assert_eq(data_store.deserialized, test_data, "反序列化数据应该匹配")
	assert_eq(_test_obj.get_property("health"), 200, "属性值应该被更新")
