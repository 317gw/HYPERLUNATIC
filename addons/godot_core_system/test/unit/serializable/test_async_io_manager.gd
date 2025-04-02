extends GutTest

# 测试数据
const TEST_DIR := "user://test_async_io"
const TEST_FILE := "user://test_async_io/test.json"
const TEST_DATA := {"name": "test", "value": 42.0}  # 使用浮点数

var _io_manager: CoreSystem.AsyncIOManager
var _test_completed: bool = false
var _test_result: Dictionary = {}

func before_all():
	# 创建测试目录
	DirAccess.make_dir_recursive_absolute(TEST_DIR)

func after_all():
	# 清理测试目录
	var dir := DirAccess.open(TEST_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(TEST_DIR.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
		DirAccess.remove_absolute(TEST_DIR)

func before_each():
	_io_manager = CoreSystem.AsyncIOManager.new()
	_test_completed = false
	_test_result.clear()
	
func after_each():
	_io_manager._exit()
	_io_manager = null

### 辅助函数 ###

func wait_for_completion(timeout: float = 10.0) -> void:  # 增加超时时间
	var timer := 0.0
	while not _test_completed and timer < timeout:
		timer += get_process_delta_time()
		await get_tree().process_frame
	
	assert_true(_test_completed, "操作应该在超时前完成")

func assert_dict_eq(dict1: Dictionary, dict2: Dictionary, message: String = "") -> void:
	# 自定义字典比较，处理数字类型差异
	var equal := true
	for key in dict1:
		if key not in dict2:
			equal = false
			break
		if typeof(dict1[key]) != typeof(dict2[key]):
			if str(dict1[key]) != str(dict2[key]):  # 转换为字符串比较
				equal = false
				break
		elif dict1[key] != dict2[key]:
			equal = false
			break
	assert_true(equal, message)

class TaskTracker:
	var completed_tasks: Array[String] = []
	var mutex := Mutex.new()
	var total_expected: int
	var on_all_completed: Callable
	
	func _init(expected: int, callback: Callable):
		total_expected = expected
		on_all_completed = callback
	
	func mark_completed(task_id: String) -> void:
		mutex.lock()
		completed_tasks.append(task_id)
		if completed_tasks.size() == total_expected:
			on_all_completed.call()
		mutex.unlock()
	
	func get_completed_count() -> int:
		mutex.lock()
		var count = completed_tasks.size()
		mutex.unlock()
		return count

### 基础API测试 ###

func test_basic_write_and_read():
	watch_signals(_io_manager)
	
	# 测试写入
	_io_manager.write_file(TEST_FILE, TEST_DATA, func(success: bool, _result):
		assert_true(success, "基础写入应该成功")
		_test_completed = true
	)
	await wait_for_completion()
	assert_signal_emitted(_io_manager, "io_completed")
	
	_test_completed = false
	
	# 测试读取
	_io_manager.read_file(TEST_FILE, func(success: bool, result):
		assert_true(success, "基础读取应该成功")
		assert_dict_eq(result, TEST_DATA, "读取的数据应该与写入的数据相同")
		_test_completed = true
	)
	await wait_for_completion()

func test_basic_delete():
	# 先写入文件
	_io_manager.write_file(TEST_FILE, TEST_DATA, func(success: bool, _result):
		assert_true(success, "写入应该成功")
		_test_completed = true
	)
	await wait_for_completion()
	_test_completed = false
	
	# 测试删除
	_io_manager.delete_file(TEST_FILE, func(success: bool, _result):
		assert_true(success, "删除应该成功")
		_test_completed = true
	)
	await wait_for_completion()
	
	# 验证文件已删除
	assert_false(FileAccess.file_exists(TEST_FILE), "文件应该已被删除")

### 进阶API测试 ###

func test_advanced_write_and_read_with_compression():
	# 测试压缩写入
	_io_manager.write_file_advanced(TEST_FILE, TEST_DATA, true, func(success: bool, _result):
		assert_true(success, "压缩写入应该成功")
		_test_completed = true
	)
	await wait_for_completion()
	_test_completed = false
	
	# 测试压缩读取
	_io_manager.read_file_advanced(TEST_FILE, true, func(success: bool, result):
		assert_true(success, "压缩读取应该成功")
		assert_dict_eq(result, TEST_DATA, "解压后的数据应该与原始数据相同")
		_test_completed = true
	)
	await wait_for_completion()

### 完整API测试 ###

func test_full_write_and_read_with_encryption():
	const ENCRYPTION_KEY := "test_key"
	
	# 测试加密写入
	_io_manager.write_file_async(TEST_FILE, TEST_DATA, true, true, ENCRYPTION_KEY, func(success: bool, _result):  # 修正为write_file_async
		assert_true(success, "加密写入应该成功")
		_test_completed = true
	)
	await wait_for_completion()
	_test_completed = false
	
	# 测试加密读取
	_io_manager.read_file_async(TEST_FILE, true, true, ENCRYPTION_KEY, func(success: bool, result):
		assert_true(success, "加密读取应该成功")
		assert_dict_eq(result, TEST_DATA, "解密后的数据应该与原始数据相同")
		_test_completed = true
	)
	await wait_for_completion()

### 错误处理测试 ###

func test_read_nonexistent_file():
	watch_signals(_io_manager)
	
	_io_manager.read_file("user://nonexistent.json", func(success: bool, result):
		assert_false(success, "读取不存在的文件应该失败")
		assert_null(result, "失败时结果应该为null")
		_test_completed = true
	)
	await wait_for_completion()
	
	assert_signal_emitted(_io_manager, "io_error")

func test_write_to_invalid_path():
	watch_signals(_io_manager)
	
	_io_manager.write_file("", TEST_DATA, func(success: bool, _result):
		assert_false(success, "写入无效路径应该失败")
		_test_completed = true
	)
	await wait_for_completion()
	
	assert_signal_emitted(_io_manager, "io_error")

### 并发测试 ###

func test_concurrent_operations():
	var total_operations := 5
	var task_ids := []
	var completed_tasks := {}
	
	# 监听IO完成信号
	var _completed_signal = func(task_id: String, success: bool, _result):
		if success:
			completed_tasks[task_id] = true
	
	_io_manager.io_completed.connect(_completed_signal)
	
	# 启动多个并发操作
	for i in range(total_operations):
		var file_path = TEST_FILE + str(i)
		var task_id = _io_manager.write_file(file_path, {"index": float(i)})
		task_ids.append(task_id)
	
	# 等待所有操作完成或超时
	var start_time := Time.get_ticks_msec()
	var timeout_ms := 20000  # 20秒超时
	
	while completed_tasks.size() < total_operations:
		if (Time.get_ticks_msec() - start_time) >= timeout_ms:
			break
		await get_tree().process_frame
	
	# 断开信号连接
	_io_manager.io_completed.disconnect(_completed_signal)
	
	# 验证结果
	assert_eq(completed_tasks.size(), total_operations, 
		"应该完成所有操作，当前完成 %d/%d" % [completed_tasks.size(), total_operations])
	
	# 验证所有任务ID都被正确完成
	for task_id in task_ids:
		assert_true(completed_tasks.has(task_id), 
			"任务 %s 应该已完成" % task_id)
	
	# 验证所有文件都被正确写入
	for i in range(total_operations):
		var file_path = TEST_FILE + str(i)
		assert_true(FileAccess.file_exists(file_path), 
			"文件 %s 应该存在" % file_path)
		
		_test_completed = false
		_io_manager.read_file(file_path, func(success: bool, result):
			assert_true(success, "读取文件 %d 应该成功" % i)
			assert_dict_eq(result, {"index": float(i)}, "文件 %d 的内容应该正确" % i)
			_test_completed = true
		)
		await wait_for_completion()
