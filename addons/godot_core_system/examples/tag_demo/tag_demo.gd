extends Node2D

## 标签系统示例

@onready var tag_manager : CoreSystem.GameplayTagManager = CoreSystem.tag_manager
@onready var status_label = $UI/StatusLabel
@onready var player: Node2D = $Player
@onready var enemy: Node2D = $Enemy

func _ready() -> void:
	# 给玩家添加标签
	player.add_tag("character")
	player.add_tag("character.player")
	player.add_tag("state.idle")
	
	# 给敌人添加标签
	enemy.add_tag("character")
	enemy.add_tag("character.enemy")
	enemy.add_tag("state.idle")
	

func _on_player_move_button_pressed() -> void:
	# 切换玩家移动状态
	if player.has_tag("state.moving"):
		player.remove_tag("state.moving")
		player.add_tag("state.idle")
		$Player.modulate = Color.WHITE
		_update_status("Player stopped moving")
	else:
		player.remove_tag("state.idle")
		player.add_tag("state.moving")
		$Player.modulate = Color.GREEN
		_update_status("Player started moving")


func _on_player_attack_button_pressed() -> void:
	# 玩家攻击状态
	if player.has_tag("state.attacking"):
		return
		
	player.add_tag("state.attacking")
	$Player.modulate = Color.RED
	_update_status("Player is attacking!")
	
	# 2秒后移除攻击状态
	await get_tree().create_timer(2.0).timeout
	player.remove_tag("state.attacking")
	$Player.modulate = Color.WHITE if player.has_tag("state.idle") else Color.GREEN
	_update_status("Player finished attacking")


func _on_buff_button_pressed() -> void:
	# 给玩家添加随机增益
	var buffs = ["buff.speed_up", "buff.attack_up"]
	var random_buff = buffs[randi() % buffs.size()]
	
	if player.has_tag(random_buff):
		player.remove_tag(random_buff)
		_update_status("Removed buff: " + random_buff.split(".")[-1])
	else:
		player.add_tag(random_buff)
		_update_status("Added buff: " + random_buff.split(".")[-1])
	
	# 更新buff显示
	_update_buff_display()


func _on_query_button_pressed() -> void:
	# 查询并显示所有标签
	var player_tag_list = player.get_tags()
	var enemy_tag_list = enemy.get_tags()
	
	var status_text = "Player tags: %s\nEnemy tags: %s" % [player_tag_list, enemy_tag_list]
	_update_status(status_text)

func _update_status(text: String) -> void:
	status_label.text = text


func _update_buff_display() -> void:
	var buff_text = ""
	if player.has_tag("buff.speed_up"):
		buff_text += "[Speed Up] "
	if player.has_tag("buff.attack_up"):
		buff_text += "[Attack Up] "
	
	$UI/BuffLabel.text = "Active Buffs: " + (buff_text if not buff_text.is_empty() else "None")
