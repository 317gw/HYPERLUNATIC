extends GutTest

func test_default_config_structure():
	var config = CoreSystem.ConfigManager.DefaultConfig.get_default_config()
	
	# 验证主要配置段
	assert_has(config, "game", "应该包含游戏配置段")
	assert_has(config, "graphics", "应该包含图形配置段")
	assert_has(config, "audio", "应该包含音频配置段")
	assert_has(config, "input", "应该包含输入配置段")
	assert_has(config, "gameplay", "应该包含游戏玩法配置段")
	assert_has(config, "accessibility", "应该包含无障碍配置段")
	assert_has(config, "debug", "应该包含调试配置段")

func test_game_settings():
	var config = CoreSystem.ConfigManager.DefaultConfig.get_default_config()
	
	# 验证游戏设置
	assert_has(config.game, "language", "应该包含语言设置")
	assert_has(config.game, "difficulty", "应该包含难度设置")
	assert_has(config.game, "first_run", "应该包含首次运行标志")
	
	assert_eq(config.game.language, "en", "默认语言应该是英语")
	assert_eq(config.game.difficulty, "normal", "默认难度应该是普通")
	assert_true(config.game.first_run, "首次运行标志应该为true")

func test_graphics_settings():
	var config = CoreSystem.ConfigManager.DefaultConfig.get_default_config()
	
	# 验证图形设置
	assert_has(config.graphics, "fullscreen", "应该包含全屏设置")
	assert_has(config.graphics, "vsync", "应该包含垂直同步设置")
	assert_has(config.graphics, "resolution", "应该包含分辨率设置")
	assert_has(config.graphics, "quality", "应该包含画质设置")
	
	assert_false(config.graphics.fullscreen, "默认不应该是全屏")
	assert_true(config.graphics.vsync, "默认应该启用垂直同步")
	assert_eq(config.graphics.resolution, Vector2i(1920, 1080), "默认分辨率应该是1920x1080")
	assert_eq(config.graphics.quality, "high", "默认画质应该是高")

func test_audio_settings():
	var config = CoreSystem.ConfigManager.DefaultConfig.get_default_config()
	
	# 验证音频设置
	assert_has(config.audio, "master_volume", "应该包含主音量设置")
	assert_has(config.audio, "music_volume", "应该包含音乐音量设置")
	assert_has(config.audio, "sfx_volume", "应该包含音效音量设置")
	assert_has(config.audio, "voice_volume", "应该包含语音音量设置")
	assert_has(config.audio, "mute", "应该包含静音设置")
	
	assert_eq(config.audio.master_volume, 1.0, "默认主音量应该是1.0")
	assert_eq(config.audio.music_volume, 0.8, "默认音乐音量应该是0.8")
	assert_eq(config.audio.sfx_volume, 0.8, "默认音效音量应该是0.8")
	assert_eq(config.audio.voice_volume, 0.8, "默认语音音量应该是0.8")
	assert_false(config.audio.mute, "默认不应该静音")

func test_input_settings():
	var config = CoreSystem.ConfigManager.DefaultConfig.get_default_config()
	
	# 验证输入设置
	assert_has(config.input, "mouse_sensitivity", "应该包含鼠标灵敏度设置")
	assert_has(config.input, "gamepad_enabled", "应该包含手柄启用设置")
	assert_has(config.input, "vibration_enabled", "应该包含震动启用设置")
	
	assert_eq(config.input.mouse_sensitivity, 1.0, "默认鼠标灵敏度应该是1.0")
	assert_true(config.input.gamepad_enabled, "默认应该启用手柄")
	assert_true(config.input.vibration_enabled, "默认应该启用震动")

func test_gameplay_settings():
	var config = CoreSystem.ConfigManager.DefaultConfig.get_default_config()
	
	# 验证游戏玩法设置
	assert_has(config.gameplay, "tutorial_enabled", "应该包含教程启用设置")
	assert_has(config.gameplay, "auto_save", "应该包含自动保存设置")
	assert_has(config.gameplay, "auto_save_interval", "应该包含自动保存间隔设置")
	assert_has(config.gameplay, "show_damage_numbers", "应该包含显示伤害数字设置")
	assert_has(config.gameplay, "show_floating_text", "应该包含显示浮动文本设置")
	
	assert_true(config.gameplay.tutorial_enabled, "默认应该启用教程")
	assert_true(config.gameplay.auto_save, "默认应该启用自动保存")
	assert_eq(config.gameplay.auto_save_interval, 300, "默认自动保存间隔应该是300秒")
	assert_true(config.gameplay.show_damage_numbers, "默认应该显示伤害数字")
	assert_true(config.gameplay.show_floating_text, "默认应该显示浮动文本")

func test_accessibility_settings():
	var config = CoreSystem.ConfigManager.DefaultConfig.get_default_config()
	
	# 验证无障碍设置
	assert_has(config.accessibility, "subtitles", "应该包含字幕设置")
	assert_has(config.accessibility, "colorblind_mode", "应该包含色盲模式设置")
	assert_has(config.accessibility, "screen_shake", "应该包含屏幕震动设置")
	assert_has(config.accessibility, "text_size", "应该包含文本大小设置")
	
	assert_true(config.accessibility.subtitles, "默认应该启用字幕")
	assert_eq(config.accessibility.colorblind_mode, "none", "默认色盲模式应该是none")
	assert_true(config.accessibility.screen_shake, "默认应该启用屏幕震动")
	assert_eq(config.accessibility.text_size, "medium", "默认文本大小应该是medium")

func test_debug_settings():
	var config = CoreSystem.ConfigManager.DefaultConfig.get_default_config()
	
	# 验证调试设置
	assert_has(config.debug, "logging_enabled", "应该包含日志启用设置")
	assert_has(config.debug, "log_level", "应该包含日志级别设置")
	assert_has(config.debug, "show_fps", "应该包含显示FPS设置")
	assert_has(config.debug, "show_debug_info", "应该包含显示调试信息设置")
	
	assert_true(config.debug.logging_enabled, "默认应该启用日志")
	assert_eq(config.debug.log_level, "info", "默认日志级别应该是info")
	assert_false(config.debug.show_fps, "默认不应该显示FPS")
	assert_false(config.debug.show_debug_info, "默认不应该显示调试信息")
