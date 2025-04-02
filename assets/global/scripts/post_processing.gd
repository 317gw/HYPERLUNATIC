extends CanvasLayer


@onready var water_ripple_overlay: TextureRect = $WaterRippleOverlay
@onready var radial_blur: ColorRect = $RadialBlur


func _ready() -> void:
	for child in get_children():
		#child.visible = false
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
