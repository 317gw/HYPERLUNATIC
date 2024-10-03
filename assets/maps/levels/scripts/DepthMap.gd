extends GridMap

@onready var conway_s_game_of_life: Node3D = $"../.."
@onready var turn_timer: Timer = $"../../TurnTimer"

func _on_conways_game_of_life_tween_move() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "position:y", -conway_s_game_of_life.game_plane * cell_size.y, turn_timer.wait_time)
