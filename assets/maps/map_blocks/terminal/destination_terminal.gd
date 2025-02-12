extends Node3D


signal teleport_enable
signal change_name

var route: HL.Route

@onready var terminal_interactive_screen: StaticBody3D = $TerminalInteractiveScreen
@onready var check_point: Area3D = $CheckPoint
@onready var content: ColorRect = $TerminalInteractiveScreen/SubViewport/Content
@onready var marker_3d: Marker3D = $Marker3D


func _ready() -> void:
	content.terminal = self


func on_area_3d() -> void:
	check_point.call_deferred("set_process_mode", Node.PROCESS_MODE_INHERIT)
	check_point.visible = true


func off_area_3d() -> void:
	check_point.call_deferred("set_process_mode", Node.PROCESS_MODE_DISABLED)
	check_point.visible = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not route:
		prints("no route", global_position)
		return
	if body is HL.Player and route.is_start:
		route.destination.emit()


func _on_button_teleport_pressed() -> void:
	if route.pass_once and not route.is_start:
		Global.main_player.teleport(route.start_terminal.marker_3d.global_position)
