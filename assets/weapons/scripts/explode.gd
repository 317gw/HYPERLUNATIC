extends Node3D

enum Explod_Type {WHITE, ORANGE, RED, NUKE}

const IMPACT_WAVE = preload ("res://assets/special_effects/impact_wave.tscn")
const EXPLODE_WHITE = preload ("res://assets/special_effects/explode_white.tscn")
const EXPLODE_ORANGE = preload ("res://assets/special_effects/explode_orange.tscn")
const EXPLODE_RED = preload ("res://assets/special_effects/explode_red.tscn")

@export var difference: float = 1.4
@export var white_explode_limit: float = 3.0
@export var orange_explode_limit: float = 7.0
@export var red_explode_limit: float = 10.0
@export var died_time: float = 0.6
@export_range(0, 1, 0.01) var disappear_time: float = 0.5

var damage: float = 3.0
var radius: float = 2.5
var force: float = 2.0
var particle_speed: float = 8.0
var explod_type = Explod_Type.WHITE
var explod_meshs: Array = []
var waves: Array = []
var time: float = 0.0

var entered_body: Array = []

@onready var area: Area3D = $Area3D
@onready var collision: CollisionShape3D = $Area3D/CollisionShape3D
@onready var dot: GPUParticles3D = $Dot
@onready var tail: GPUParticles3D = $Tail
@onready var smoke: GPUParticles3D = $Smoke
@onready var audio: AudioStreamPlayer3D = $Audio
@onready var die_timer: Timer = $DieTimer
@onready var area_timer: Timer = $AreaTimer


func _ready() -> void:
	time = 0.0
	die_timer.wait_time = died_time
	die_timer.start()

	add_tween()
	instantiate_meshs_and_waves()

	dot.emitting = true
	smoke.emitting = true
	smoke.lifetime = died_time

	dot.process_material.initial_velocity_min = particle_speed
	dot.process_material.initial_velocity_max = particle_speed * 1.5
	dot.scale = radius * Vector3.ONE
	collision.get_shape().radius = radius

	entered_body.clear()

	#audio.pitch_scale = 6 / died_time
	#audio.playing = true


func _physics_process(_delta: float) -> void:
	var time_left_percent = time / died_time
	if time_left_percent >= disappear_time:
		var t = (time_left_percent - disappear_time) / (1 - disappear_time)
		for mesh: MeshInstance3D in explod_meshs:
			var material: Material = mesh.mesh.surface_get_material(0)
			material.set_shader_parameter("transparency", clamp(1-t, 0, 1))
		for wave: Node3D in waves:
			wave.transparency = t
		tail.transparency = t

	var RcV3 = radius * time * Vector3.ONE
	calculate_scales(RcV3)

	#area.scale = red.scale
	#if audio.playing == false:
		#queue_free()
	#print("time: ", time)


func add_tween() -> void:
	#var tween_time = 0
	var tween:Tween = get_tree().create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "time", 0.5, died_time * 0.2)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "time", 1.0, died_time * 0.8)


func explode(in_damage: float=3, in_radius: float=2.5, in_force: float=2) -> void:
	self.damage = in_damage
	self.radius = in_radius
	self.force = in_force


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body not in entered_body:
		if body.has_method("be_hit"): # 击中敌人
			var attack = HL.Attack.new()
			attack.damage = damage
			attack.knockback_force = force
			attack.position = global_position
			attack.radius = self.radius
			attack.source = self
			body.be_hit(attack)
		if body is RigidBody3D:
			var dir: Vector3 = global_position.direction_to(body.global_position)
			var explode_force: Vector3 = dir * force * global_position.distance_to(body.global_position) / self.radius
			if body.mass:
				#prints("yesss", force)
				explode_force = clamp(explode_force.length(), 0.0, Global.explod_max_speed * body.mass) * dir
				#prints("   ", force, Global.explod_max_speed * body.mass)
			body.apply_impulse(explode_force)
		entered_body.append(body)


func _on_die_timer_timeout() -> void:
	for mesh in explod_meshs:
		mesh.mesh.surface_get_material(0).set_shader_parameter("transparency", 1)
		mesh.queue_free()
	for wave in waves:
		wave.queue_free()
	queue_free()


func _on_area_timer_timeout() -> void:
	area.monitoring = false


func calculate_scales(RcV3) -> void:
	smoke.draw_pass_1.size = Vector2(RcV3.x, RcV3.z)
	for i in range(explod_meshs.size()):
		explod_meshs[i].scale = RcV3 * (1 - float(i) / 4)
	for i in range(waves.size()):
		waves[i].scale = RcV3 * 2


func instantiate_meshs_and_waves() -> void:
	# SpecialEffectsAndSoundEffects
	#var effects = get_node("/root/Effects")

	var white1 = EXPLODE_WHITE.instantiate()
	add_child(white1)
	var impact_wave1 = IMPACT_WAVE.instantiate()
	add_child(impact_wave1)

	explod_meshs.clear()
	waves.clear()
	explod_meshs.append(white1)
	waves.append(impact_wave1)

	if damage < white_explode_limit:
		explod_type = Explod_Type.WHITE # 1白 1波

		dot.lifetime = 0.3 # 其他3s
		tail.lifetime = 0.3
	elif damage < orange_explode_limit:
		explod_type = Explod_Type.ORANGE # 1橘 1白 1波

		var orange1 = EXPLODE_ORANGE.instantiate()
		add_child(orange1)

		explod_meshs.append(orange1)
	elif damage < red_explode_limit:
		explod_type = Explod_Type.RED # 1红 1白 3波

		var red1 = EXPLODE_RED.instantiate()
		add_child(red1)
		var impact_wave2 = IMPACT_WAVE.instantiate()
		add_child(impact_wave2)
		var impact_wave3 = IMPACT_WAVE.instantiate()
		add_child(impact_wave3)

		explod_meshs.append(red1)
		waves.append(impact_wave2)
		waves.append(impact_wave3)
		impact_wave2.rotation.x = PI / 2
		impact_wave3.rotation.z = PI / 2
	else:
		explod_type = Explod_Type.NUKE # 1红 1橘 2白 3波

		var white2 = EXPLODE_WHITE.instantiate()
		add_child(white2)
		var orange1 = EXPLODE_ORANGE.instantiate()
		add_child(orange1)
		var red1 = EXPLODE_RED.instantiate()
		add_child(red1)
		var impact_wave2 = IMPACT_WAVE.instantiate()
		add_child(impact_wave2)
		var impact_wave3 = IMPACT_WAVE.instantiate()
		add_child(impact_wave3)

		explod_meshs.append(red1)
		explod_meshs.append(white2)
		explod_meshs.append(orange1)
		waves.append(impact_wave2)
		waves.append(impact_wave3)
		impact_wave2.rotation.x = PI / 2
		impact_wave3.rotation.z = PI / 2

	#print("explod_type: ", explod_type)

	#for mesh in explod_meshs:
		#mesh.global_position = global_position
	#for wave in waves:
		#wave.global_position = global_position
