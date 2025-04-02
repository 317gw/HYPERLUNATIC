extends Node2D

const ConfigManager = CoreSystem.ConfigManager

@onready var config_manager : ConfigManager = CoreSystem.config_manager
@onready var status_label = $UI/StatusLabel
@onready var config_tree = $UI/ConfigTree
@onready var label: Label = %Label

func _ready():
	# 连接信号
	config_manager.config_loaded.connect(_on_config_loaded)
	config_manager.config_saved.connect(_on_config_saved)
	config_manager.config_reset.connect(_on_config_reset)
	
	# 加载配置
	status_label.text = "正在加载配置..."
	config_manager.load_config(func(success: bool):
		if success:
			status_label.text = "配置加载成功"
		else:
			status_label.text = "配置加载失败，使用默认配置"
		_update_config_tree()
	)
	label.text = "自动保存：{0}".format(["是" if config_manager.auto_save else "否"])

## 更新配置显示
func _update_config_tree():
	config_tree.clear()
	var root = config_tree.create_item()
	root.set_text(0, "配置")
	
	# 遍历所有配置段
	for section in ["game", "graphics", "audio", "input", "gameplay", "accessibility", "debug"]:
		var section_data = config_manager.get_section(section)
		var section_item = config_tree.create_item(root)
		section_item.set_text(0, section)
		
		# 遍历配置段中的所有键值对
		for key in section_data:
			var value_item = config_tree.create_item(section_item)
			value_item.set_text(0, "%s: %s" % [key, str(section_data[key])])

## 修改配置按钮回调
func _on_modify_button_pressed():
	# 修改一些配置值作为演示
	config_manager.set_value("graphics", "fullscreen", true)
	config_manager.set_value("audio", "master_volume", 0.5)
	config_manager.set_value("gameplay", "show_damage_numbers", false)
	
	status_label.text = "配置已修改"
	_update_config_tree()

## 保存配置按钮回调
func _on_save_button_pressed():
	config_manager.save_config(func(success: bool):
		status_label.text = "配置保存" + ("成功" if success else "失败")
	)

## 重置配置按钮回调
func _on_reset_button_pressed():
	config_manager.reset_config(func(success: bool):
		if success:
			status_label.text = "配置已重置为默认值"
			_update_config_tree()
		else:
			status_label.text = "配置重置失败"
	)

## 配置加载回调
func _on_config_loaded():
	print("配置加载事件触发")

## 配置保存回调
func _on_config_saved():
	print("配置保存事件触发")

## 配置重置回调
func _on_config_reset():
	print("配置重置事件触发")
