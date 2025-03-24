@tool
extends LinePath3D


func _ready() -> void:
	if not is_connected("curve_changed",Callable(self,"_rd")):
		connect("curve_changed",Callable(self,"_rd"))

	if not Engine.is_editor_hint():
		add_child(GetReady.new(func(): return Global.sky_limit, _set_curve))


func _set_curve() -> void:
	curve.clear_points()
	curve.add_point(Vector3.ZERO)
	curve.add_point(Global.sky_limit.plane.project(self.global_position)-self.global_position)
