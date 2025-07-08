extends "../config_tab_base.gd"


#var data_format: Dictionary = {
	#"name": "",
	#"type": ValueType.SLIDER,
	#"value": 12.0,
	#"max_value": 12.0,
#}


func _setup_configs() -> void:
	add_config({
		"name": "显示模式",
		"type": ValueType.OPTION,
		"value": "全屏显示",
		"options": ["全屏显示", "窗口显示"],
		"option_loop": true,
	})

	add_config({
		"name": "画面尺寸",
		"type": ValueType.OPTION,
		"value": "1920×1080",
		"options": ["1280×720", "1920×1080", "2560×1440"],
	})


func _on_value_changed(_key: String, _value: Variant) -> void:
	pass
