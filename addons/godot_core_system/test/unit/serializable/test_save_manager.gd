extends GutTest

const TEST_SAVE_NAME := "test_save"
const TEST_SAVE_DATA := {
	"player": {
		"position": Vector2(100, 200),
		"health": 100,
		"inventory": ["sword", "shield", "potion"]
	},
	"world": {
		"level": 1,
		"time": 3600,
		"completed_quests": ["quest1", "quest2"]
	}
}

class TestStore:
	var completed := false
	var auto_saves_created := 0
	var cleanups_completed := 0
	
	func clear():
		completed = false
		auto_saves_created = 0
		cleanups_completed = 0

var _test_state: CoreSystem.GameStateData
# 测试状态存储
var _test_store := TestStore.new()

var save_manager: CoreSystem.SaveManager = CoreSystem.save_manager

func before_each():
	# 重置测试状态存储
	_test_store.clear()

	# 创建测试数据
	_test_state = CoreSystem.GameStateData.new(TEST_SAVE_NAME)
	_test_state.set_data("player", TEST_SAVE_DATA.player)
	_test_state.set_data("world", TEST_SAVE_DATA.world)
	
	# 等待一帧以确保设置生效
	await get_tree().process_frame

func after_each():
	_test_state = null
	_test_store.clear()
	
	# 清理测试文件
	var dir := DirAccess.open(CoreSystem.save_manager.save_directory)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	# 删除测试目录
	if DirAccess.dir_exists_absolute(CoreSystem.save_manager.save_directory):
		DirAccess.remove_absolute(CoreSystem.save_manager.save_directory)
	
	await get_tree().process_frame

func test_create_load_save():
	_test_store.completed = false
	var save_manager = CoreSystem.save_manager
	
	# 创建存档
	save_manager.create_save(TEST_SAVE_NAME, func(success: bool):
		assert_true(success, "创建存档应该成功")
		
		# 等待文件写入完成
		await get_tree().create_timer(0.1).timeout
		
		# 加载并验证存档
		save_manager.load_save(TEST_SAVE_NAME, func(load_success: bool):
			assert_true(load_success, "加载存档应该成功")
			var current_save = save_manager.get_current_save()
			assert_not_null(current_save, "当前存档不应为空")
			assert_eq(current_save.metadata.save_name, TEST_SAVE_NAME)
			_test_store.completed = true
		)
	)
	
	await wait_for_test_completion()

func test_delete_save():
	_test_store.completed = false
	var save_manager = CoreSystem.save_manager
	
	# 先创建存档
	save_manager.create_save(TEST_SAVE_NAME, func(success: bool):
		assert_true(success)
		
		# 等待文件写入完成
		await get_tree().create_timer(0.1).timeout
		
		# 删除存档
		save_manager.delete_save(TEST_SAVE_NAME, func(delete_success: bool):
			assert_true(delete_success, "删除存档应该成功")
			var save_path = CoreSystem.save_manager.save_directory.path_join(TEST_SAVE_NAME + "." + save_manager.save_extension)
			assert_false(FileAccess.file_exists(save_path), "存档文件应该被删除")
			_test_store.completed = true
		)
	)
	
	await wait_for_test_completion()

func test_save_list():
	_test_store.completed = false
	var save_manager = CoreSystem.save_manager
	
	# 创建多个存档
	save_manager.create_save(TEST_SAVE_NAME + "_1", func(success1: bool):
		assert_true(success1)
		save_manager.create_save(TEST_SAVE_NAME + "_2", func(success2: bool):
			assert_true(success2)
			
			# 等待文件写入完成
			await get_tree().create_timer(0.1).timeout
			
			# 获取存档列表
			save_manager.get_save_list(func(save_list: Array):
				assert_eq(save_list.size(), 2, "应该有两个存档")
				assert_true(save_list.has(TEST_SAVE_NAME + "_1"), "存档列表应该包含第一个存档")
				assert_true(save_list.has(TEST_SAVE_NAME + "_2"), "存档列表应该包含第二个存档")
				_test_store.completed = true
			)
		)
	)
	
	await wait_for_test_completion()


## 等待测试完成的辅助函数
func wait_for_test_completion() -> void:
	var timeout := 5.0  # 5秒超时
	var timer := 0.0
	while not _test_store.completed and timer < timeout:
		await get_tree().create_timer(0.1).timeout
		timer += 0.1
	assert_true(_test_store.completed, "测试应该在超时前完成")
