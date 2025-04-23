extends CanvasLayer


@onready var water_ripple_overlay: TextureRect = $WaterRippleOverlay
@onready var radial_blur: ColorRect = $RadialBlur
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	for child in get_children():
		#child.visible = false
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mesh_instance_3d.queue_free()
