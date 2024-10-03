extends AnimatableBody3D
#RigidBody3D
#AnimatableBody3D
@onready var player: Player = $"../Player"
@onready var player_CollisionShape: CollisionShape3D = $"../Player/CollisionShape3D"

func _physics_process(_delta: float) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "global_position", player_CollisionShape.global_position, 0.1)


	#constant_force = -player.acceleration
	#linear_velocity = player.velocity
	#global_position = player_CollisionShape.global_position
