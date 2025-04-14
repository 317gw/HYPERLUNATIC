extends Control

@export var ray_length: float = 50.0

var mouse_position: Vector2
var look_at_target: Vector3
var is_mouse_wheel_pressed: bool = false
var viewport_size: Vector2

@onready var player_fp_ui: CanvasLayer = $".."
@onready var h_box_container: HBoxContainer = $ColorRect/HBoxContainer
@onready var menu_button: MenuButton = $ColorRect/HBoxContainer/MenuButton
@onready var ray_cast_3d: RayCast3D = $RayCast3D

@onready var infor_color_rect: ColorRect = $InforColorRect
@onready var infor_label: Label = $InforColorRect/InforLabel

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	self.visible = false
	ray_cast_3d.target_position.z = -ray_length


func _physics_process(delta: float) -> void:
	if not self.visible:
		return

	# 处理鼠标传送逻辑
	if is_mouse_wheel_pressed:
		viewport_size = get_viewport().size
		var mouse_pos = get_viewport().get_mouse_position()
		var new_mouse_pos = mouse_pos

		# 检查是否超出边界并传送
		if mouse_pos.x <= 0:
			new_mouse_pos.x = viewport_size.x - 2
		elif mouse_pos.x >= viewport_size.x - 1:
			new_mouse_pos.x = 2

		if mouse_pos.y <= 0:
			new_mouse_pos.y = viewport_size.y - 2
		elif mouse_pos.y >= viewport_size.y - 1:
			new_mouse_pos.y = 2

		if new_mouse_pos != mouse_pos:
			get_viewport().warp_mouse(new_mouse_pos)

	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE or (is_mouse_wheel_pressed and Input.get_mouse_mode() == Input.MOUSE_MODE_CONFINED):
		var camera:= get_viewport().get_camera_3d()
		var pos: Vector3 = camera.project_position(mouse_position, 2.0)

		# 疯狂的蛇
		ray_cast_3d.look_at_from_position(camera.global_position, pos)
		ray_cast_3d.force_raycast_update()
		var collider = ray_cast_3d.get_collider()
		look_at_target = ray_cast_3d.get_collision_point() if collider else camera.project_position(mouse_position, ray_length)
		mesh_instance_3d.global_position = ray_cast_3d.get_collision_point() if collider else pos

		# 标签
		infor_label.text = "+++"
		if collider is RigidBody3D or collider is CharacterBody3D:
			infor_label.text = collider.name + "\n" + str(collider.global_position)

		infor_label.size = infor_label.get_minimum_size()
		infor_color_rect.size = infor_label.size
		infor_color_rect.position = mouse_position
		infor_color_rect.position.y -= infor_label.size.y


func _input(event: InputEvent) -> void:
	# 起洞！
	if event.is_action_pressed("tool_ui"):
		self.visible = !self.visible
		var debug_menu_control = Global.debug_menu.debug_menu_control
		if self.visible:
			self.mouse_filter = Control.MOUSE_FILTER_STOP
			var sizey: float = h_box_container.size.y
			debug_menu_control.size.y -= sizey
			debug_menu_control.position.y = sizey
		else:
			self.mouse_filter = Control.MOUSE_FILTER_IGNORE
			debug_menu_control.size.y = get_window().size.y
			debug_menu_control.position.y = 0
		Global.set_mouse_mode()

	# 鼠标中键控制
	if self.visible:
		if event.is_action_pressed("mouse_wheel_pressed"):
			is_mouse_wheel_pressed = true
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED
		elif event.is_action_released("mouse_wheel_pressed"):
			is_mouse_wheel_pressed = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# 摇到耗子pos
	if event is InputEventMouse:
		var mouse_motion: InputEventMouse = event
		mouse_position = mouse_motion.global_position
