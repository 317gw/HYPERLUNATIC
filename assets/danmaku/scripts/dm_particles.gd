#@tool
extends Node3D

const PARTICLE_SIZE = 2048

var _break_group_spawn: bool = false
var _break_count: int = 0
var _particle_position: PackedVector3Array
var _particle_color: PackedColorArray
var _particle_scale: PackedFloat32Array


@onready var break_gpu_particles_1: GPUParticles3D = $BreakGPUParticles1
@onready var break_gpu_particles_2: GPUParticles3D = $BreakGPUParticles2
@onready var break_gpu_particles_3: GPUParticles3D = $BreakGPUParticles3

#@onready var frameskiper: FrameSkiper = FrameSkiper.new(1)


func  _ready() -> void:
	_particle_position.clear()
	_particle_color.clear()
	_particle_scale.clear()
	_particle_position.resize(PARTICLE_SIZE)
	_particle_color.resize(PARTICLE_SIZE)
	_particle_scale.resize(PARTICLE_SIZE)
	break_gpu_particles_1.amount = PARTICLE_SIZE
	break_gpu_particles_2.amount = PARTICLE_SIZE
	break_gpu_particles_3.amount = PARTICLE_SIZE


func _physics_process(delta: float) -> void:
	#if frameskiper.skip_frame():
		#return

	if _break_group_spawn:
		#break_gpu_particles_1.amount = _break_count
		#break_gpu_particles_2.amount = _break_count
		#break_gpu_particles_3.amount = _break_count
		for i in _break_count:
			_emit_break_group(_particle_position[i], _particle_color[i], _particle_scale[i])

		_break_group_spawn = false
		_break_count = 0


func add_break_group(pos: Vector3, new_color: Color, new_scale: float) -> void:
	_break_group_spawn = true
	_particle_position.set(_break_count, pos)
	_particle_color.set(_break_count, new_color)
	_particle_scale.set(_break_count, new_scale)
	_break_count += 1


# r * 7.0
func _emit_break_group(pos: Vector3 = Vector3.ONE, new_color: Color = Color.WHITE, new_scale: float = 1.0) -> void:
	var trans:= Transform3D(Basis.IDENTITY, pos)
	var ppm1: ParticleProcessMaterial = break_gpu_particles_1.process_material
	var ppm2: ParticleProcessMaterial = break_gpu_particles_2.process_material
	var ppm3: ParticleProcessMaterial = break_gpu_particles_3.process_material
	ppm1.color = new_color
	ppm2.color = Color(new_color, 0.6)
	ppm3.color = Color(new_color, 0.2)
	_set_particle_scale(ppm1, new_scale)
	_set_particle_scale(ppm2, new_scale * 0.85)
	_set_particle_scale(ppm3, new_scale * 0.6)
	_emit_particle(break_gpu_particles_1, trans)
	_emit_particle(break_gpu_particles_2, trans)
	_emit_particle(break_gpu_particles_3, trans)


func _emit_particle(gpu_particles: GPUParticles3D, transform3d: Transform3D) -> void:
	gpu_particles.emit_particle(transform3d, Vector3.ZERO, Color.WHITE, Color.WHITE, GPUParticles3D.EmitFlags.EMIT_FLAG_POSITION)


func _set_particle_scale(ppm: ParticleProcessMaterial, new_scale: float) -> void:
	ppm.set_param_min(ParticleProcessMaterial.PARAM_SCALE, new_scale)
	ppm.set_param_max(ParticleProcessMaterial.PARAM_SCALE, new_scale)
