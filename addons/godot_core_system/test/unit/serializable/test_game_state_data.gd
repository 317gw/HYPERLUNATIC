extends GutTest

const TEST_SAVE_NAME = "test_save"
const TEST_GAME_DATA = {
	"player": {
		"position": Vector2(100, 200),
		"health": 100,
		"inventory": ["sword", "shield", "potion"]
	},
	"world": {
		"time": 3600,
		"weather": "sunny",
		"completed_quests": ["quest1", "quest2"]
	}
}

var _state: CoreSystem.GameStateData

func before_each():
	_state = CoreSystem.GameStateData.new(TEST_SAVE_NAME)

func after_each():
	_state = null

func test_initial_state():
	# 验证元数据初始化
	assert_has(_state.metadata, "version", "应该包含版本号")
	assert_has(_state.metadata, "timestamp", "应该包含时间戳")
	assert_has(_state.metadata, "save_name", "应该包含存档名称")
	assert_has(_state.metadata, "play_time", "应该包含游戏时间")
	assert_has(_state.metadata, "screenshot", "应该包含截图")
	
	# 验证初始值
	assert_eq(_state.metadata.save_name, TEST_SAVE_NAME, "存档名称应该正确设置")
	assert_eq(_state.metadata.version, "1.0.0", "版本号应该是1.0.0")
	assert_gt(_state.metadata.timestamp, 0, "时间戳应该大于0")
	assert_eq(_state.metadata.play_time, 0, "初始游戏时间应该是0")
	assert_eq(_state.metadata.screenshot, "", "初始截图应该为空")
	
	# 验证游戏数据为空
	assert_eq(_state.game_data.size(), 0, "初始游戏数据应该为空")

func test_set_get_data():
	# 测试设置和获取数据
	_state.set_data("player", TEST_GAME_DATA.player)
	_state.set_data("world", TEST_GAME_DATA.world)
	
	# 验证数据是否正确保存
	assert_eq(_state.get_data("player"), TEST_GAME_DATA.player)
	assert_eq(_state.get_data("world"), TEST_GAME_DATA.world)
	
	# 测试获取不存在的数据
	assert_null(_state.get_data("nonexistent"), "不存在的键应该返回null")
	assert_eq(_state.get_data("nonexistent", "default"), "default", "应该返回默认值")

func test_remove_data():
	# 先添加数据
	_state.set_data("player", TEST_GAME_DATA.player)
	_state.set_data("world", TEST_GAME_DATA.world)
	
	# 删除数据
	_state.remove_data("player")
	
	# 验证数据是否被删除
	assert_null(_state.get_data("player"), "数据应该被删除")
	assert_eq(_state.get_data("world"), TEST_GAME_DATA.world, "其他数据应该保持不变")

func test_clear_data():
	# 先添加数据
	_state.set_data("player", TEST_GAME_DATA.player)
	_state.set_data("world", TEST_GAME_DATA.world)
	
	# 清空数据
	_state.clear_data()
	
	# 验证所有数据是否被清空
	assert_eq(_state.game_data.size(), 0, "所有数据应该被清空")
	assert_null(_state.get_data("player"))
	assert_null(_state.get_data("world"))

func test_serialize_deserialize():
	# 设置测试数据
	_state.set_data("player", TEST_GAME_DATA.player)
	_state.set_data("world", TEST_GAME_DATA.world)
	
	# 序列化
	var serialized = _state.serialize()
	
	# 验证序列化数据结构
	assert_has(serialized, "metadata", "序列化数据应该包含元数据")
	assert_has(serialized, "game_data", "序列化数据应该包含游戏数据")
	
	# 创建新状态并反序列化
	var new_state = CoreSystem.GameStateData.new()
	new_state.deserialize(serialized)
	
	# 验证元数据
	assert_eq(new_state.metadata.save_name, _state.metadata.save_name)
	assert_eq(new_state.metadata.version, _state.metadata.version)
	assert_eq(new_state.metadata.timestamp, _state.metadata.timestamp)
	assert_eq(new_state.metadata.play_time, _state.metadata.play_time)
	assert_eq(new_state.metadata.screenshot, _state.metadata.screenshot)
	
	# 验证游戏数据
	assert_eq(new_state.get_data("player"), TEST_GAME_DATA.player)
	assert_eq(new_state.get_data("world"), TEST_GAME_DATA.world)
	
	new_state = null

func test_partial_deserialization():
	# 测试只有部分数据的反序列化
	var partial_data = {
		"metadata": {
			"save_name": "partial_save"
		}
	}
	
	_state.deserialize(partial_data)
	
	# 验证已有的数据被更新
	assert_eq(_state.metadata.save_name, "partial_save")
	
	# 验证缺失的数据保持原样
	assert_eq(_state.metadata.version, "1.0.0")
	assert_gt(_state.metadata.timestamp, 0)
	assert_eq(_state.game_data.size(), 0)

func test_complex_data_types():
	# 测试复杂数据类型的处理
	var complex_data = {
		"vectors": [Vector2(1, 2), Vector2(3, 4)],
		"nested": {
			"array": [1, 2, 3],
			"dict": {"key": "value"}
		},
		"mixed": [{"pos": Vector2(5, 6)}, [7, 8, 9]]
	}
	
	_state.set_data("complex", complex_data)
	
	# 序列化和反序列化
	var serialized = _state.serialize()
	var new_state = CoreSystem.GameStateData.new()
	new_state.deserialize(serialized)
	
	# 验证复杂数据是否正确保存
	var restored_data = new_state.get_data("complex")
	assert_eq(restored_data.vectors, complex_data.vectors)
	assert_eq(restored_data.nested.array, complex_data.nested.array)
	assert_eq(restored_data.nested.dict, complex_data.nested.dict)
	assert_eq(restored_data.mixed[0].pos, complex_data.mixed[0].pos)
	assert_eq(restored_data.mixed[1], complex_data.mixed[1])
	
	new_state = null
