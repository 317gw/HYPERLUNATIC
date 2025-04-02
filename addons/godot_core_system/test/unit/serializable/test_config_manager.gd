extends GutTest

const TEST_CONFIG_DATA := {
	"graphics": {
		"resolution": Vector2(1920, 1080),
		"fullscreen": false,
		"vsync": true
	},
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.9
	},
	"game": {
		"difficulty": "normal",
		"language": "en"
	}
}

class TestStore:
	var completed := false
	var load_success := false
	var save_success := false
	var reset_success := false
	
	func clear():
		completed = false
		load_success = false
		save_success = false
		reset_success = false

var _config_manager: CoreSystem.ConfigManager
var _test_store: TestStore


func before_each():
	_test_store = TestStore.new()
	_config_manager = CoreSystem.config_manager
	
	# 等待一帧以确保配置管理器初始化完成
	await get_tree().process_frame


func after_each():
	_config_manager.reset_config()
	_test_store.clear()
	await get_tree().process_frame


func test_save_load_config():
	# 设置配置值
	_config_manager.set_value("graphics", "resolution", TEST_CONFIG_DATA.graphics.resolution)
	_config_manager.set_value("graphics", "fullscreen", TEST_CONFIG_DATA.graphics.fullscreen)
	_config_manager.set_value("audio", "master_volume", TEST_CONFIG_DATA.audio.master_volume)
	_config_manager.set_value("game", "difficulty", TEST_CONFIG_DATA.game.difficulty)
	
	# 保存配置
	_config_manager.save_config(func(success: bool):
		_test_store.save_success = success
		assert_true(success, "保存配置应该成功")
		
		# 加载并验证配置
		_config_manager.load_config(func(load_success: bool):
			_test_store.load_success = load_success
			assert_true(load_success, "加载配置应该成功")
			
			# 验证配置值
			var resolution = _config_manager.get_value("graphics", "resolution")
			assert_eq(resolution, TEST_CONFIG_DATA.graphics.resolution, "分辨率应该匹配")
			
			assert_eq(_config_manager.get_value("graphics", "fullscreen"), TEST_CONFIG_DATA.graphics.fullscreen)
			assert_eq(_config_manager.get_value("audio", "master_volume"), TEST_CONFIG_DATA.audio.master_volume)
			assert_eq(_config_manager.get_value("game", "difficulty"), TEST_CONFIG_DATA.game.difficulty)
			_test_store.completed = true
		)
	)
	
	await wait_for_test_completion()

func test_reset_config():
	# 设置一些非默认值
	_config_manager.set_value("graphics", "resolution", Vector2(800, 600))
	_config_manager.set_value("audio", "master_volume", 0.5)
	
	# 重置配置
	_config_manager.reset_config(func(success: bool):
		_test_store.reset_success = success
		assert_true(success, "重置配置应该成功")
		
		# 验证值已重置为默认值
		var default_config = CoreSystem.ConfigManager.DefaultConfig.get_default_config()
		var resolution = _config_manager.get_value("graphics", "resolution")
		assert_eq(resolution, default_config.graphics.resolution)
		
		assert_eq(_config_manager.get_value("audio", "master_volume"), default_config.audio.master_volume)
		_test_store.completed = true
	)
	
	await wait_for_test_completion()

func test_auto_save():
	# 启用自动保存
	_config_manager.auto_save = true
	
	# 修改配置
	_config_manager.set_value("graphics", "fullscreen", true)
	_config_manager.set_value("audio", "master_volume", 0.7)
	
	# 等待自动保存
	await get_tree().create_timer(0.2).timeout
	
	# 重新加载配置并验证
	_config_manager.load_config(func(success: bool):
		_test_store.load_success = success
		assert_true(success, "加载配置应该成功")
		
		assert_true(_config_manager.get_value("graphics", "fullscreen"), "fullscreen应该为true")
		assert_eq(_config_manager.get_value("audio", "master_volume"), 0.7, "master_volume应该为0.7")
		_test_store.completed = true
	)
	
	await wait_for_test_completion()

func wait_for_test_completion() -> void:
	var timer := 0.0
	while not _test_store.completed and timer < 5.0:
		await get_tree().create_timer(0.1).timeout
		timer += 0.1
	assert_true(_test_store.completed, "测试应该在超时前完成")
