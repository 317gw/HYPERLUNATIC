extends "../config_tab_base.gd"


#var data_format: Dictionary = {
	#"name": "",
	#"type": ValueType.SLIDER,
	#"value": 12.0,
	#"max_value": 12.0,
#}


func _setup_configs() -> void:
	add_config({
		"name": "音频总线",
		"type": ValueType.SLIDER,
		"value": 12.0,
		"max_value": 12.0,
	})

	add_config({
		"name": "背景音乐",
		"type": ValueType.SLIDER,
		"value": 12.0,
		"max_value": 12.0,
	})

	add_config({
		"name": "游戏音效",
		"type": ValueType.SLIDER,
		"value": 12.0,
		"max_value": 12.0,
	})
