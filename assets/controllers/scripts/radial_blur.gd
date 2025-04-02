extends ColorRect


var radial_blur: ShaderMaterial

var player: HL.Player = null
var camera_3d: HL.Camera = null

var current_blur_center: Vector2 = Vector2.ZERO
var current_blur_power: float = 0.0
var current_lod: float = 0.0

@onready var texture_rect: TextureRect = $TextureRect



func _ready() -> void:
	#await Global.main_player_ready
	player = Global.main_player
	camera_3d = player.camera
	radial_blur = material


func _physics_process(_delta: float) -> void:
	if player.velocity.length() < player.speed_normal:
		visible = false
		return
	visible = true

	var camera_plane: Plane = Plane(camera_3d._face_dir)
	var v: Vector3 = player.velocity.normalized()
	var v2 = camera_plane.project(v) + camera_3d._face_dir

	var pos: Vector2 = camera_3d.unproject_position(v2 + camera_3d.global_position)
	pos /= Vector2(get_window().size)
	current_blur_center = current_blur_center.move_toward(pos, 0.1)
	texture_rect.position = current_blur_center * Vector2(get_window().size) - texture_rect.size * 0.5

	var speed_smoothstep = smoothstep(player.speed_normal, 20, player.velocity.length()) # player.air_speed_max
	var power = 0.014 * speed_smoothstep * camera_3d._face_dir.dot(v)
	current_blur_power = move_toward(current_blur_power, power, 0.001)
	current_lod = move_toward(current_lod, speed_smoothstep * 0.5, 0.05)

	radial_blur.set_shader_parameter("blur_center", current_blur_center)
	radial_blur.set_shader_parameter("blur_power", current_blur_power)
	radial_blur.set_shader_parameter("lod", current_lod)
