@tool
extends Node3D

@export var text: String
@export_range(1, 100, 1) var font_size: int = 30
@export_range(0.01, 2, 0.01) var text_mesh_high: float = 1.0

@onready var text_mesh: MeshInstance3D = $TextMesh

@onready var sub_viewport: SubViewport = $SubViewport
@onready var margin_container: MarginContainer = $SubViewport/MarginContainer
@onready var label: Label = $SubViewport/MarginContainer/Label

@onready var marker_3d: Marker3D = $Marker3D
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		set_text()


func set_text() -> void:
	_set_text()
	_update_effect()


func _set_text() -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.text = text
	label.size = label.get_minimum_size()
	sub_viewport.size = margin_container.size


func _update_effect() -> void:
	var mesh_size: Vector2 = Vector2(1.0, margin_container.size.y / margin_container.size.x)
	#var min_size: float = min(mesh_size.x, mesh_size.y)
	mesh_size = mesh_size / mesh_size.y * text_mesh_high
	text_mesh.mesh.size = mesh_size

	var up_off = text_mesh.mesh.size.y * 0.25
	text_mesh.position.y = marker_3d.position.y + up_off

	# 烟
	#gpu_particles_3d.position.y = lerpf(text_mesh.position.y, marker_3d.position.y, 0.1)
	var pm: ParticleProcessMaterial = gpu_particles_3d.process_material
	pm.emission_ring_radius = mesh_size.x * 0.5
	pm.emission_ring_height = mesh_size.y * 0.8
