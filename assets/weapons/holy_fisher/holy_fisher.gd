# HolyFisher
extends HL.Weapon

@export var long_length: float = 15 # m
@export var short_length: float = 1.2 # m
@export var hook_force: float = 30
@export var cast_force: float = 35

var animation_state_machine: AnimationNodeStateMachinePlayback
var is_cast_out: bool = false
var is_reel_in: bool = false
var is_hooked: bool = false
var hooked_obj: PhysicsBody3D = null

var middle_point: Vector3 = Vector3.ZERO
var current_hook_linear_damp: float = 0
var current_length: float = short_length


@onready var animation_tree: AnimationTree = $AnimationTree # 获取AnimationTree
@onready var fisher: Node3D = $圣水钓竿
@onready var head_marker: Marker3D = $圣水钓竿/骨架/Skeleton3D/杆子/HeadMarker
#@onready var water: Node3D = $圣水
@onready var hook: CharacterBody3D = $Hook
@onready var hook_area: Area3D = $Hook/Area3D

@onready var line: Path3D = $Line
@onready var line_draw: Control = $Line/LineDraw


func _ready() -> void:
	animation_state_machine = animation_tree["parameters/playback"]
	hook.process_mode = Node.PROCESS_MODE_DISABLED

	special_visible_mode = true
	line.visible = false
	line_draw.visible = false

	line.curve.clear_points()
	line.curve.add_point(head_marker.global_position)
	line.curve.add_point(hook.global_position)
	line_draw.draw.connect(control_draw)


func Enter() -> void:
	if is_hooked:
		return
	hook.process_mode = Node.PROCESS_MODE_INHERIT
	hook.global_position = head_marker.global_position
	hook.velocity = Vector3.ZERO
	is_cast_out = false
	is_hooked = false
	current_hook_linear_damp = 3
	current_length = 0


func Exit() -> void:
	if is_hooked:
		return
	line.visible = false
	line_draw.visible = false
	hook.process_mode = Node.PROCESS_MODE_DISABLED


func Physics_Update(_delta: float) -> void:
	line.visible = true
	line_draw.visible = true
	var dis: float = hook.global_position.distance_to(head_marker.global_position)
	var direc: Vector3 = hook.global_position.direction_to(head_marker.global_position)
	var force = smoothstep(current_length, current_length * 1.1, dis) * hook_force
	force += smoothstep(current_length * 1.1, current_length * 2, dis) * hook_force * 2
	hook.apply_central_force(force * direc)

	if is_reel_in:
		current_length = move_toward(current_length, 0, _delta * 10)
		if is_zero_approx(current_length):
			is_reel_in = false

	if not is_cast_out and not is_reel_in:
		current_length = move_toward(current_length, short_length, _delta * 2)

	if dis > current_length:
		hook.global_position = head_marker.global_position - direc * current_length

	_check_hook()
	if not is_hooked:
		hook.force_control_process(_delta)


func _physics_process(delta: float) -> void:
	_on_hooking(delta)
	_drawing_fishing_line(line)
	#DebugDraw.draw_line_canvas(line.curve.get_baked_points(), Color.LIGHT_SLATE_GRAY, 2)
	line_draw.queue_redraw()


func Sub_Action() -> void:
	animation_state_machine.start("挥杆", true)
	is_cast_out = !is_cast_out
	var apply_dir: Vector3

	if is_cast_out:
		hook.velocity = Vector3.ZERO
		hook.global_position = head_marker.global_position
		current_length = long_length

		is_reel_in = false
		apply_dir = head_marker.global_position.direction_to(PLAYER.look_at_target)
	else:
		is_reel_in = true
		apply_dir = hook.global_position.direction_to(head_marker.global_position)

	hook.apply_central_impulse(apply_dir * cast_force)

	# 收杆
	if is_hooked:
		if hooked_obj is CharacterBody3D:
			hooked_obj.velocity += apply_dir * cast_force
			hooked_obj.move_and_slide()
		else:
			hooked_obj.apply_central_impulse(apply_dir * hooked_obj.mass * 10)
		is_hooked = false
		hooked_obj = null


func Handle_Visible(_visible: bool) -> void:
	if is_hooked:
		fisher.visible = _visible
	else:
		visible = _visible


func _check_hook() -> void:
	if is_hooked:
		return

	if not is_cast_out:
		return

	if not hook_area.get_overlapping_bodies():
		return

	var colliding_bodies: Array[Node3D] = hook_area.get_overlapping_bodies()
	if colliding_bodies.is_empty():
		return

	for obj in colliding_bodies:
		if obj != hook and (obj is RigidBody3D or obj is CharacterBody3D or obj is PhysicalBone3D):
			is_hooked = true
			hooked_obj = obj
			prints("hooked!", hooked_obj)
			break


func _on_hooking(_delta: float) -> void:
	if not is_cast_out:
		return

	if not is_hooked:
		return

	hook.global_position = MathUtils.exponential_decay_vec3(hook.global_position, hooked_obj.global_position, _delta*46)


# 绘制鱼线
func _drawing_fishing_line(_line: Path3D) -> void:
	if not _line.visible:
		return

	middle_point = Global.gravity_vector * 0.3
	_line.curve.set_point_position(0, head_marker.global_position)
	_line.curve.set_point_position(1, hook.global_position)
	_line.curve.set_point_out(0, middle_point * 2)
	_line.curve.set_point_in(1, middle_point * 0.5)


func _draw(Lines):
	#pass
	DebugDraw.draw_line_canvas(Lines, Color.LIGHT_SLATE_GRAY, 2)
	for i in range(len(Lines) -1):
		if DebugDraw.is_line3d_behind_camera(Lines[i], Lines[i+1]):
			continue

		var ScreenPointStart = DebugDraw.camera.unproject_position(Lines[i])
		var ScreenPointEnd = DebugDraw.camera.unproject_position(Lines[i+1])

		line_draw.draw_line(ScreenPointStart, ScreenPointEnd, Color.LIGHT_SLATE_GRAY, 2)
		#DebugDraw.draw_line_canvas(Lines[i], Lines[i+1], Color.LIGHT_SLATE_GRAY, 2)



func control_draw():
	_draw(line.curve.get_baked_points())
