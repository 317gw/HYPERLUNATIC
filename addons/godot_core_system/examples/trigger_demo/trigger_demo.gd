extends Node2D

## 触发器系统示例

@onready var trigger_manager : CoreSystem.TriggerManager = CoreSystem.trigger_manager
@onready var player = $Player
@onready var status_label = $UI/StatusLabel

func _ready() -> void:
	# 创建进入区域的触发器
	var enter_area_trigger = GameplayTrigger.new({
		"trigger_type": GameplayTrigger.TRIGGER_TYPE.ON_EVENT,
		"trigger_event": "enter_area",
		"conditions": [
			{
				"type": "state_trigger_condition",
				"state_name": "player_in_area",
				"required_state": "true"
			}
		]
	})
	enter_area_trigger.triggered.connect(_on_enter_area)
	enter_area_trigger.activate()
	
	# 创建点击按钮的触发器
	var click_button_trigger = GameplayTrigger.new({
		"trigger_type": GameplayTrigger.TRIGGER_TYPE.ON_EVENT,
		"trigger_event": "button_click",
		"conditions": [
			{
				"type": "state_trigger_condition",
				"state_name": "button_clicked",
				"required_state": "true"
			}
		]
	})
	click_button_trigger.triggered.connect(_on_button_clicked)
	click_button_trigger.max_triggers = 1
	click_button_trigger.activate()
	
	# 创建周期性触发器
	var periodic_trigger = GameplayTrigger.new({
		"trigger_type": GameplayTrigger.TRIGGER_TYPE.PERIODIC,
		"period": 2.0,  # 每2秒触发一次
		"trigger_chance": 0.5  # 50%触发概率
	})
	periodic_trigger.triggered.connect(_on_periodic_trigger)
	periodic_trigger.activate()


func _on_area_2d_body_entered(_body: Node2D) -> void:
	trigger_manager.handle_event("enter_area", {
		"state_name": "player_in_area",
		"state_value": "true"
	})
	
func _on_area_2d_body_exited(_body: Node2D) -> void:
	trigger_manager.handle_event("enter_area", {
		"state_name": "player_in_area",
		"state_value": "false"
	})

func _on_button_pressed() -> void:
	trigger_manager.handle_event("button_click", {
		"state_name": "button_clicked",
		"state_value": "true"
	})

func _on_enter_area(context: Dictionary) -> void:
	status_label.text = "Player entered area!"
	status_label.modulate.a = 1.0
	create_tween().tween_property(status_label, "modulate:a", 0.0, 1.0)

func _on_button_clicked(context: Dictionary) -> void:
	status_label.text = "Button clicked!"
	status_label.modulate.a = 1.0
	create_tween().tween_property(status_label, "modulate:a", 0.0, 1.0)

func _on_periodic_trigger(context: Dictionary) -> void:
	status_label.text = "Periodic trigger activated!"
	status_label.modulate.a = 1.0
	create_tween().tween_property(status_label, "modulate:a", 0.0, 1.0)

func _physics_process(delta: float) -> void:
	# 简单的玩家移动控制
	var input := Vector2.ZERO
	input.x = Input.get_axis("ui_left", "ui_right")
	input.y = Input.get_axis("ui_up", "ui_down")
	player.position += input * 200 * delta
