extends Node

## 异步IO管理器
## 提供三个层次的API：
## 1. 基础API - 简单的异步读写操作
## 2. 进阶API - 支持压缩功能
## 3. 完整API - 支持压缩和加密功能

# 信号
## IO完成
signal io_completed(task_id: String, success: bool, result: Variant)
## IO错误
signal io_error(task_id: String, error: String)

## IO任务类型
enum TaskType {
	READ,   # 读取
	WRITE,  # 写入
	DELETE  # 删除
}

## IO任务状态
enum TaskStatus {
	PENDING,   # 未开始
	RUNNING,   # 运行中
	COMPLETED, # 完成
	ERROR      # 错误
}

# 私有变量
var _tasks: Array[IOTask] = []
var _thread: Thread
var _semaphore: Semaphore
var _running: bool = true
var _mutex: Mutex
var _task_counter: int = 0  # 任务计数器

## 加密提供者
var encryption_provider: EncryptionProvider:
	get:
		if not _encryption_provider:
			_encryption_provider = XOREncryptionProvider.new()
		return _encryption_provider
	set(value):
		_encryption_provider = value

## 内部加密提供者实例
var _encryption_provider: EncryptionProvider = null

func _init(_data:Dictionary = {}):
	_semaphore = Semaphore.new()
	_mutex = Mutex.new()
	_thread = Thread.new()
	_thread.start(_thread_function)

func _exit() -> void:
	_running = false
	_semaphore.post()
	_thread.wait_to_finish()

### 基础API ###

## 异步读取文件（基础版本）
## [param path] 文件路径
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func read_file(path: String, callback: Callable = func(_s, _r): pass) -> String:
	return read_file_advanced(path, false, callback)

## 异步写入文件（基础版本）
## [param path] 文件路径
## [param data] 要写入的数据
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func write_file(path: String, data: Variant, callback: Callable = func(_s, _r): pass) -> String:
	return write_file_advanced(path, data, false, callback)

## 异步删除文件（基础版本）
## [param path] 文件路径
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func delete_file(path: String, callback: Callable = func(_s, _r): pass) -> String:
	return delete_file_async(path, callback)

### 进阶API ###

## 异步读取文件（进阶版本）
## [param path] 文件路径
## [param use_compression] 是否使用压缩
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func read_file_advanced(path: String, use_compression: bool = false, callback: Callable = func(_s, _r): pass) -> String:
	return read_file_async(path, use_compression,  "", callback)

## 异步写入文件（进阶版本）
## [param path] 文件路径
## [param data] 要写入的数据
## [param use_compression] 是否使用压缩
## [param callback] 回调函数，接收(success: bool, result: Variant)
## [return] 任务ID
func write_file_advanced(path: String, data: Variant, use_compression: bool = false, callback: Callable = func(_s, _r): pass) -> String:
	return write_file_async(path, data, use_compression,  "", callback)

### 完整API ###

## 异步读取文件（完整版本）
## [param path] 文件路径
## [param compression] 是否压缩
## [param encryption_key] 加密密钥，为空表示不加密
## [param callback] 回调函数
## [return] 任务ID
func read_file_async(
	path: String, 
	compression: bool = false,
	encryption_key: String = "",
	callback: Callable = func(_s, _r): pass
) -> String:
	var task_id = _generate_task_id()
	var task = IOTask.new(
		task_id,
		TaskType.READ,
		path,
		null,
		compression,
		encryption_key,
		callback
	)
	
	_add_task(task)
	return task_id

## 异步写入文件（完整版本）
## [param path] 文件路径
## [param data] 数据
## [param compression] 是否压缩
## [param encryption_key] 加密密钥，为空表示不加密
## [param callback] 回调函数
## [return] 任务ID
func write_file_async(
	path: String, 
	data: Variant,
	compression: bool = false,
	encryption_key: String = "",
	callback: Callable = func(_s, _r): pass
) -> String:
	var task_id = _generate_task_id()
	var task = IOTask.new(
		task_id,
		TaskType.WRITE,
		path,
		data,
		compression,
		encryption_key,
		callback
	)
	
	_add_task(task)
	return task_id

## 异步删除文件
## [param path] 文件路径
## [param callback] 回调函数
## [return] 任务ID
func delete_file_async(path: String, callback: Callable = func(_s, _r): pass) -> String:
	var task_id = _generate_task_id()
	var task = IOTask.new(
		task_id,
		TaskType.DELETE,
		path,
		null,
		false,
		"",
		callback
	)
	
	_add_task(task)
	return task_id

### 私有方法 ###

## 工作线程函数
func _thread_function() -> void:
	while _running:
		_semaphore.wait()  # 等待任务
		
		if not _running:  # 再次检查，以防在等待时被终止
			break
			
		var task: IOTask
		_mutex.lock()
		if not _tasks.is_empty():
			task = _tasks.pop_front()
			print("[AsyncIOManager] Processing task: ", task.id)
		_mutex.unlock()
		
		if task == null:
			continue
			
		# 处理任务
		match task.type:
			TaskType.READ:
				_handle_read_task(task)
			TaskType.WRITE:
				_handle_write_task(task)
			TaskType.DELETE:
				_handle_delete_task(task)

		# 处理下一个任务
		if not _tasks.is_empty():
			print("[AsyncIOManager] Posting semaphore for next task.")
			_semaphore.post()

## 添加任务到队列
func _add_task(task: IOTask) -> void:
	if not _running:
		call_deferred("_complete_task", task, false, null, "Manager is not running")
		return
	
	_mutex.lock()
	_tasks.append(task)
	var was_empty = _tasks.size() == 1
	_mutex.unlock()
	
	if was_empty:
		print("[AsyncIOManager] Task queue was empty, posting semaphore.")
		_semaphore.post()  # 只在队列从空变为非空时发送信号

## 处理写入任务
func _handle_write_task(task: IOTask) -> void:
	# 确保目录存在
	var dir := DirAccess.open(task.path.get_base_dir())
	if dir == null:
		var err := DirAccess.make_dir_recursive_absolute(task.path.get_base_dir())
		if err != OK:
			call_deferred("_complete_task", task, false, null, "Failed to create directory")
			return
	
	var file := FileAccess.open(task.path, FileAccess.WRITE)
	if file == null:
		call_deferred("_complete_task", task, false, null, "Failed to open file")
		return
	
	var processed_data = _process_data_for_write(task.data, task.compression, task.encryption_key)
	if processed_data.is_empty():
		file.close()
		call_deferred("_complete_task", task, false, null, "Failed to process data")
		return
	
	file.store_buffer(processed_data)
	file.close()
	
	if FileAccess.file_exists(task.path):
		call_deferred("_complete_task", task, true, null)
	else:
		call_deferred("_complete_task", task, false, null, "File was not written successfully")

## 处理读取任务
func _handle_read_task(task: IOTask) -> void:
	if not FileAccess.file_exists(task.path):
		call_deferred("_complete_task", task, false, null, "File does not exist")
		return
	
	var file := FileAccess.open(task.path, FileAccess.READ)
	if file == null:
		call_deferred("_complete_task", task, false, null, "Failed to open file")
		return
	
	var content = file.get_buffer(file.get_length())
	file.close()
	
	var processed_data = _process_data_for_read(content, task.compression, task.encryption_key)
	if processed_data == null:
		call_deferred("_complete_task", task, false, null, "Failed to process data")
		return
	
	call_deferred("_complete_task", task, true, processed_data)

## 处理删除任务
func _handle_delete_task(task: IOTask) -> void:
	if not FileAccess.file_exists(task.path):
		call_deferred("_complete_task", task, false, null, "File not found")
		return
	
	var error = DirAccess.remove_absolute(task.path)
	if error != OK:
		call_deferred("_complete_task", task, false, null, "Failed to delete file")
		return
	
	call_deferred("_complete_task", task, true, null)

## 完成任务
## [param task] 任务
## [param success] 成功
## [param result] 结果
## [param error] 错误
func _complete_task(task: IOTask, success: bool, result: Variant = null, error: String = "") -> void:
	print("[AsyncIOManager] Completing task: ", task.id, " Success: ", success, " Error: ", error)
	task.status = TaskStatus.COMPLETED if success else TaskStatus.ERROR
	task.error = error
	
	if success:
		io_completed.emit(task.id, true, result)
	else:
		io_error.emit(task.id, error)
		io_completed.emit(task.id, false, null)
	
	if task.callback.is_valid():
		task.callback.call(success, result)

## 处理数据（写入）
## [param data] 数据
## [param compression] 是否压缩
## [param encryption_key] 加密密钥
## [return] 处理后的数据
func _process_data_for_write(data: Variant, compression: bool, encryption_key: String = "") -> PackedByteArray:
	# 将数据转换为JSON字符串
	var json_str := JSON.stringify(data)
	var byte_array := json_str.to_utf8_buffer()
	
	# 压缩
	if compression:
		byte_array = byte_array.compress(FileAccess.COMPRESSION_GZIP)
	
	# 加密
	if not encryption_key.is_empty():
		var key := encryption_key.sha256_buffer()
		byte_array = _encrypt_data(byte_array, key)
	
	return byte_array

## 处理数据（读取）
## [param byte_array] 数据
## [param compression] 是否压缩
## [param encryption_key] 加密密钥
## [return] 处理后的数据
func _process_data_for_read(byte_array: PackedByteArray, compression: bool, encryption_key: String = "") -> Variant:
	# 解密
	if not encryption_key.is_empty():
		var key := encryption_key.sha256_buffer()
		byte_array = _decrypt_data(byte_array, key)
	
	# 解压
	if compression:
		byte_array = byte_array.decompress(byte_array.size() * 10, FileAccess.COMPRESSION_GZIP)
	
	# 解析JSON
	var json_str := byte_array.get_string_from_utf8()
	var json := JSON.new()
	var error := json.parse(json_str)
	if error == OK:
		return json.get_data()
	return null

## 加密数据
## [param data] 要加密的数据
## [param key] 密钥
## [return] 加密后的数据
func _encrypt_data(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	return encryption_provider.encrypt(data, key)

## 解密数据
## [param data] 要解密的数据
## [param key] 密钥
## [return] 解密后的数据
func _decrypt_data(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	return encryption_provider.decrypt(data, key)

## 设置加密提供者
## [param provider] 加密提供者实例
func set_encryption_provider(provider: EncryptionProvider) -> void:
	encryption_provider = provider

## 生成唯一的任务ID
func _generate_task_id() -> String:
	_mutex.lock()
	_task_counter += 1
	var counter = _task_counter
	_mutex.unlock()
	return "%d_%d" % [Time.get_ticks_msec(), counter]

## IO任务
class IOTask:
	## 任务ID
	var id: String
	## 任务类型
	var type: TaskType
	## 路径
	var path: String
	## 数据
	var data: Variant
	## 状态
	var status: TaskStatus
	## 错误
	var error: String
	## 回调
	var callback: Callable
	## 压缩
	var compression: bool
	## 加密密钥, 为空表示不加密
	var encryption_key: String
	
	func _init(
		_id: String, 
		_type: TaskType, 
		_path: String, 
		_data: Variant = null,
		_compression: bool = false,
		_encryption_key: String = "",
		_callback: Callable = func(_s, _r): pass
	) -> void:
		id = _id
		type = _type
		path = _path
		data = _data
		status = TaskStatus.PENDING
		compression = _compression
		encryption_key = _encryption_key
		callback = _callback
