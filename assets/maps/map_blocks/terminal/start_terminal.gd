extends Node3D

# id, OwningLevel, Start, check_points, Destination
#var route: Dictionary = {
	#"id": -1,
	#"OwningLevel": null,
	#"Start": self,
	#"check_points": [],
	#"Destination": null,
#}

signal teleport_enable
signal change_name

var route: HL.Route
var _start_on_out: bool = false

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
	_start_on_out = false


func _on_area_3d_body_exited(body: Node3D) -> void:
	if not route:
		prints("no route", global_position)
		return
	if body is HL.Player and not route.is_start and _start_on_out:
		route.start.emit()


func _on_button_out_pressed() -> void:
	_start_on_out = true


func _on_button_now_pressed() -> void:
	route.start.emit()


func _on_button_teleport_pressed() -> void:
	if route.pass_once and not route.is_start:
		Global.main_player.teleport(route.destination_terminal.marker_3d.global_position)
