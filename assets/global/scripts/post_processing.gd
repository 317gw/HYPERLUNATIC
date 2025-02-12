extends Node3D


@onready var water_ripple_overlay: TextureRect = $WaterRippleOverlay
@onready var radial_blur: ColorRect = $RadialBlur


func _ready() -> void:
	for child: Control in get_children():
		child.visible = false
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
