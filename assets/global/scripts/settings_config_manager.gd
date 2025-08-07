# class_name SettingsConfigManager
extends Node

const MAX_BACKUPS: int = 20  # 最大备份文件数
const VERSION_ERR: String = "v0.0.0-err.0"

# CoreSystem 单例已设置
var _compare_config_file: ConfigFile = ConfigFile.new()


func _ready() -> void:
	# 处理此设备首次打开这个项目
	#CoreSystem.config_manager.set_value("config_setup", "ok!", false)
	add_child(GetReady.new(func(): return Global.main_menus, entering_the_game)) # 等待配置菜单并应用游戏配置初始化


## 进入游戏
func entering_the_game() -> void:
	CoreSystem.logger.info("SettingsConfigManager: entering_the_game")
	CoreSystem.config_manager.load_config()
	# 处理此设备首次打开这个项目
	var no_ok:bool =(not CoreSystem.config_manager.has_section("config_setup")
		or not CoreSystem.config_manager.has_key("config_setup", "ok!")
		or not CoreSystem.config_manager.get_value("config_setup", "ok!", false))
	var version_err:bool = (not CoreSystem.config_manager.has_key("config_setup", "version")
		or CoreSystem.config_manager.get_value("config_setup", "version", VERSION_ERR) != ProjectSettings.get_setting("application/config/version")
	)
	if no_ok or version_err:
		# 备份当前配置文件（如果存在）
		backup_config_file(CoreSystem.config_manager.config_path)
		first_time_entering_the_game()
	Global.main_menus.option_window.apply_config(true, true)
	confirm_config()


## 此设备首次打开这个项目/此游戏
func first_time_entering_the_game() -> void:
	# config_setup
	CoreSystem.config_manager.set_value("config_setup", "ok!", true)
	#var version = ProjectSettings.get_setting("application/config/version", null)
	CoreSystem.config_manager.set_value("config_setup", "version", ProjectSettings.get_setting("application/config/version", null))
	CoreSystem.config_manager.set_value("config_setup", "setup_datetime_utc", Time.get_datetime_dict_from_system(true))
	CoreSystem.config_manager.set_value("config_setup", "setup_datetime_local", Time.get_datetime_dict_from_system(false))


## 确认配置  保存到文件
func confirm_config() -> void:
	CoreSystem.config_manager.save_config()


## 重制配置从文件到实例
func config_file_to_instance() -> void:
	CoreSystem.config_manager.reset_config()
	CoreSystem.config_manager.load_config()


## 载入比较用配置
func load_compare_config(path_to_load: String) -> bool:
	if not path_to_load:
		print("_compare not path_to_load")
		return false
	# 确保目标目录存在，load 不会创建目录
	var dir_path = path_to_load.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		print("_compare Config directory '%s' does not exist, attempting to load will likely fail (or be empty)." % dir_path)
		# ConfigFile.load 在目录不存在时似乎不会返回特定错误码，更像 ERR_FILE_NOT_FOUND
	var err = _compare_config_file.load(path_to_load)
	if err == OK:
		# 验证配置格式
		#if not _validate_config_format(_compare_config_file):
			#printerr("_compare Config file has invalid format")
			#_compare_config_file.clear()
			#return false
		print("_compare Config loaded successfully from '%s'." % path_to_load)
		return true
	elif err == ERR_FILE_NOT_FOUND:
		print("_compare Config file '%s' not found. Will use default values provided by get_value()." % path_to_load)
		_compare_config_file.clear() # 确保内存中是空的，而不是上次加载的内容
		return true # 文件不存在是预期情况，不算加载失败
	else: # 其他加载错误
		printerr("_compare Failed to load config file '%s'. Error code: %d" % [path_to_load, err])
		_compare_config_file.clear() # 加载失败，清空内存状态以防部分加载
		return false


## 备份配置文件
func backup_config_file(config_path: String) -> void:
	# 检查配置文件是否存在
	if not FileAccess.file_exists(config_path):
		CoreSystem.logger.info("No config file to backup: " + config_path)
		return
	var backup_dir = "user://config_backup/"
	# 确保备份目录存在
	if DirAccess.make_dir_recursive_absolute(backup_dir) != OK:
		CoreSystem.logger.error("Failed to create backup directory: " + backup_dir)
		return
	# 获取版本号
	var version_str: String = VERSION_ERR
	if CoreSystem.config_manager.has_section("config_setup") and CoreSystem.config_manager.has_key("config_setup", "version"):
		version_str = CoreSystem.config_manager.get_value("config_setup", "version", VERSION_ERR)
	# 清理版本号字符串中的非法字符（针对文件名）
	version_str = version_str.replace(":", "-").replace(" ", "_").replace("/", "_")
	# 生成带版本号和时间戳的备份文件名
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var config_file = config_path.get_file()
	var backup_path = backup_dir.path_join(config_file.replace(".cfg", "_" + version_str + "_" + timestamp + ".cfg"))
	# 执行备份
	if DirAccess.copy_absolute(config_path, backup_path) != OK:
		CoreSystem.logger.error("Failed to backup config file: " + config_path)
		return
	CoreSystem.logger.info("Config file backed up to: " + backup_path)
	# 清理旧备份文件
	cleanup_old_backups(backup_dir)


## 清理旧备份文件（在备份文件数量大于 MAX_BACKUPS 时删除一个月前的最老备份文件）
func cleanup_old_backups(backup_dir: String) -> void:
	var dir = DirAccess.open(backup_dir)
	if dir == null:
		CoreSystem.logger.error("Failed to open backup directory: " + backup_dir)
		return
	# 计算一个月前的时间戳（30天）
	var current_time = Time.get_unix_time_from_system()
	var one_month_ago = current_time - (30 * 24 * 60 * 60)  # 30天前的Unix时间戳
	# 获取所有备份文件
	var files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension() == "cfg":
			var file_path = backup_dir.path_join(file_name)
			var modified_time = FileAccess.get_modified_time(file_path)
			files.append({
				"path": file_path,
				"modified": modified_time
			})
		file_name = dir.get_next()
	# 如果备份数量未超过限制，直接返回
	if files.size() <= MAX_BACKUPS:
		return
	# 查找一个月前的最老备份文件
	var oldest_month_ago_file = null
	for file in files:
		# 检查文件是否超过一个月
		if file.modified < one_month_ago:
			# 查找最老的文件
			if oldest_month_ago_file == null or file.modified < oldest_month_ago_file.modified:
				oldest_month_ago_file = file
	# 如果找到符合条件的文件，删除它
	if oldest_month_ago_file != null:
		if DirAccess.remove_absolute(oldest_month_ago_file.path) == OK:
			CoreSystem.logger.info("Deleted old backup (over 1 month): " + oldest_month_ago_file.path)
		else:
			CoreSystem.logger.error("Failed to delete old backup: " + oldest_month_ago_file.path)
	else:
		CoreSystem.logger.info("No backups older than 1 month found for deletion")


## 备份文件恢复
func restore_backup(backup_path: String) -> bool:
	if not FileAccess.file_exists(backup_path):
		CoreSystem.logger.error("Backup file not found: " + backup_path)
		return false
	if DirAccess.copy_absolute(backup_path, CoreSystem.config_manager.config_path) != OK:
		CoreSystem.logger.error("Failed to restore backup")
		return false
	CoreSystem.logger.info("Config restored from backup: " + backup_path)
	config_file_to_instance()  # 重新加载配置
	return true
