class_name SpeedLine1 extends Node3D

@export var scale_curve: Curve

var process_material
var threshold: float = 0.0

@onready var player: Player = $"../.."
@onready var airflow_particles: GPUParticles3D = $SpeedLineParticles

func _ready() -> void:
	process_material = airflow_particles.process_material


func _physics_process(_delta: float) -> void:
	threshold = lerp(player.speed_normal, player.speed_max, 0.5)
	#var curve_y = scale_curve.sample(velocity)

	#var target = velocity
	var Deadlocks = player.direction == Vector3.UP or player.direction == Vector3.DOWN
	if player.velocity and player.velocity.length() > threshold:
		self.visible = true
		if Deadlocks:
			self.global_rotation = player.direction.y * Vector3.RIGHT * PI / 2
		#else :
			#self.look_at(player.velocity + self.global_position)
	else :
		self.visible = false



	#process_material.color.a =curve_y

	#amount_ratio
	#scale.z

	#process_material.initial_velocity_min = velocity.length()
	#process_material.initial_velocity_max = velocity.length() * 1.5
