@tool
extends ColorRect

@export var update: bool = false :
	set(v):
		force_update()

@export var up_color: Color = Color.GRAY
@export var below_color: Color = Color.WHITE

@export_range(2, 100) var mark_count: int = 5
@export_range(0, 20) var mark_subdivide_count: int = 3

@export_range(0, 10, 0.01) var mark_up_width: float = 2 ## px
@export_range(0, 10, 0.01) var mark_below_width: float = 1 ## px

@export_group("margin")
@export var margin_left: float = 5 ## px
@export var margin_right: float = 5 ## px

@export_range(0, 0.5) var up_margin_top: float = 0 ## %
@export_range(0, 0.5) var up_margin_bottom: float = 0 ## %
@export_range(0, 0.5) var below_margin_top: float = 0.5 ## %
@export_range(0, 0.5) var below_margin_bottom: float = 0 ## %

@export var offset: Vector2 = Vector2.ZERO ## %

@onready var shader_material: ShaderMaterial = self.material


#func _ready() -> void:
	#if not Engine.is_editor_hint():
		#add_child(GetReady.new(func(): return self.draw, force_update))


#func _process(delta: float) -> void:
	#if Engine.is_editor_hint():
		#force_update()
	#if self.visible:
		#force_update()


func _physics_process(delta: float) -> void:
	#force_update()
	if Engine.is_editor_hint():
		force_update()
	if self.visible:
		force_update()


func force_update() -> void:
	# 设置颜色
	shader_material.set_shader_parameter("up_color", up_color)
	shader_material.set_shader_parameter("below_color", below_color)
	# 设置数量
	var _self_size_x: float = max(self.size.x, 1.0)
	shader_material.set_shader_parameter("up_count", mark_count)
	shader_material.set_shader_parameter("below_count", mark_count + (mark_count - 1) * mark_subdivide_count)
	shader_material.set_shader_parameter("up_width", mark_up_width / _self_size_x)
	shader_material.set_shader_parameter("below_width", mark_below_width / _self_size_x)

	var _offset: Vector2 = offset # / self.size.max(Vector2.ONE)

	# 主左右边距 px
	var _up_margin_left: float = margin_left / _self_size_x
	var _up_margin_right: float = margin_right / _self_size_x
	shader_material.set_shader_parameter("up_margin_left", _up_margin_left + _offset.x)
	shader_material.set_shader_parameter("up_margin_right", _up_margin_right - _offset.x)

	# 下层左右边距 自动
	var lr_offset: float = (mark_up_width - mark_below_width) * 0.5 / _self_size_x
	shader_material.set_shader_parameter("below_margin_left", lr_offset + _up_margin_left + _offset.x)
	shader_material.set_shader_parameter("below_margin_right", lr_offset + _up_margin_right - _offset.x)

	# 上下边距 %
	shader_material.set_shader_parameter("up_margin_top", up_margin_top + _offset.y)
	shader_material.set_shader_parameter("up_margin_bottom", up_margin_bottom - _offset.y)
	shader_material.set_shader_parameter("below_margin_top", below_margin_top + _offset.y)
	shader_material.set_shader_parameter("below_margin_bottom", below_margin_bottom - _offset.y)
