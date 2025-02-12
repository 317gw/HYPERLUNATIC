extends TextureRect


@export var wrosp_in_value: float = 2.0
var wrosp_trg: float
var wrosp_ori: float
var wrosp_in: float

var player: HL.Player = null

@onready var camera_pos_shape_cast_3d: ShapeCast3D = $CameraPosShapeCast3D


func _ready() -> void:
	player = Global.main_player
	wrosp_ori = material.get_shader_parameter("value_all")
	wrosp_in = wrosp_ori * wrosp_in_value
	wrosp_trg = wrosp_in
	player.now_out_water.connect(_player_out_water)


func _physics_process(delta: float) -> void:
	if player.is_swimming():
		visible = should_draw_camera_underwater_effect()
		wrosp_trg = HL.exponential_decay(wrosp_trg, wrosp_ori, delta*1.5333)
		material.set_shader_parameter("value_all", wrosp_trg)


# 用一个区域跟踪当前摄像机，以便我们检查它是否在水中
func should_draw_camera_underwater_effect() -> bool:
	var camera := get_viewport().get_camera_3d() if get_viewport() else null
	if not camera:
		return false
	camera_pos_shape_cast_3d.global_position = camera.global_position
	camera_pos_shape_cast_3d.force_update_transform()
	camera_pos_shape_cast_3d.force_shapecast_update()
	return camera_pos_shape_cast_3d.is_colliding()

#func _player_in_water() -> void:
	

func _player_out_water() -> void:
	visible = false
	wrosp_trg = wrosp_in
	material.set_shader_parameter("value_all", wrosp_ori)
