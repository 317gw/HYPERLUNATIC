extends "../config_tab_base.gd"


#var data_format: Dictionary = {
	#"name": "",
	#"type": ValueType.SLIDER,
	#"value": 12.0,
	#"max_value": 12.0,
#}


func _setup_configs() -> void:
	add_config({
		"name": "",
		"type": ValueType.SLIDER,
		"value": 12.0,
		"max_value": 12.0,
	})


func _on_value_changed(_key: String, _value: Variant) -> void:
	pass
