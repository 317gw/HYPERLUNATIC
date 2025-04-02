extends Node2D

const TimeManager = CoreSystem.TimeManager

@onready var time_manager : TimeManager = CoreSystem.time_manager
@onready var game_time_label = $UI/GameTimeLabel
@onready var timer_label = $UI/TimerLabel
@onready var status_label = $UI/StatusLabel

# 计时器ID
const TIMER_IDS = {
	"countdown": "demo_countdown",
	"loop": "demo_loop"
}

func _ready():
	# 连接信号
	time_manager.time_scale_changed.connect(_on_time_scale_changed)
	time_manager.timer_completed.connect(_on_timer_completed)
	time_manager.time_state_changed.connect(_on_time_state_changed)
	
	# 创建一个5秒倒计时
	time_manager.create_timer(TIMER_IDS.countdown, 5.0, false, 
		func(): print("倒计时结束！"))
	# 创建一个2秒循环计时器
	time_manager.create_timer(TIMER_IDS.loop, 2.0, true,
		func(): print("循环计时器触发！"))
	
	# 设置状态标签
	status_label.text = "时间系统演示"

func _process(_delta):
	# 更新游戏时间显示
	game_time_label.text = "游戏时间：%.2f 秒" % time_manager.get_game_time()
	
	# 更新计时器显示
	var countdown_time = time_manager.get_timer_remaining(TIMER_IDS.countdown)
	if countdown_time > 0:
		timer_label.text = "倒计时：%.1f 秒" % countdown_time
	else:
		timer_label.text = "倒计时已结束"

## 时间缩放按钮回调
func _on_speed_button_pressed(scale: float):
	time_manager.set_time_scale(scale)
	status_label.text = "时间缩放：%.1fx" % scale

## 暂停按钮回调
func _on_pause_button_pressed():
	var new_state = !time_manager.is_paused()
	time_manager.set_paused(new_state)

## 重置倒计时按钮回调
func _on_reset_button_pressed():
	var success = time_manager.reset_timer(TIMER_IDS.countdown)
	if success:
		status_label.text = "倒计时已重置"
	else:
		time_manager.create_timer(TIMER_IDS.countdown, 5.0, false, 
		func(): print("倒计时结束！"))
## 时间缩放变化回调
func _on_time_scale_changed(new_scale: float):
	status_label.text = "时间缩放已更改为：%.1fx" % new_scale

## 计时器完成回调
func _on_timer_completed(timer_id: String):
	if timer_id == TIMER_IDS.countdown:
		status_label.text = "倒计时完成！"

## 时间状态变化回调
func _on_time_state_changed(is_paused: bool):
	status_label.text = "时间已%s" % ("暂停" if is_paused else "恢复")
