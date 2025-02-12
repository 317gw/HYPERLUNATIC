extends Node3D

signal start
signal destination

@export var id: int = -1
@export var route_name: String = ""
@export var owning_level: Node3D
@export var start_terminal: Node3D
@export var check_points: Array[Node3D] = []
@export var destination_terminal: Node3D
@export var switch_maps: Node3D

var pass_once: bool = false
var is_start: bool = false
var time_record: float = 0
var time_list: Array[float] = []


func _ready() -> void:
	if owning_level and route_name == "":
		var parts = owning_level.name.split("_")
		route_name = parts[2] if parts.size() >= 3 else ""
	
	if start_terminal:
		start_terminal.route = self
		start_terminal.change_name.emit(route_name)
	else:
		prints("no start_terminal", get_path())
		
	if check_points:
		for Point in check_points:
			Point.route = self

	if destination_terminal:
		destination_terminal.route = self
		destination_terminal.change_name.emit(route_name)
		destination_terminal.off_area_3d()
	else:
		prints("no destination_terminal", get_path())
	
	switch_maps.visible = false
	switch_maps.call_deferred("set_process_mode", Node.PROCESS_MODE_DISABLED)


func _process(delta: float) -> void:
	if is_start:
		time_record += delta


func get_time_record() -> String:
	return "%0.2f" % time_record


func _on_start() -> void:
	is_start = true
	time_record = 0
	start_terminal.off_area_3d()
	destination_terminal.on_area_3d()
	switch_maps.visible = true
	switch_maps.call_deferred("set_process_mode", Node.PROCESS_MODE_INHERIT)


func _on_destination() -> void:
	is_start = false
	time_list.append(time_record)
	pass_once = true
	start_terminal.content.button_teleport.disabled = false
	destination_terminal.content.button_teleport.disabled = false
	start_terminal.teleport_enable.emit()
	destination_terminal.teleport_enable.emit()
	start_terminal.on_area_3d()
	destination_terminal.off_area_3d()
	switch_maps.visible = false
	switch_maps.call_deferred("set_process_mode", Node.PROCESS_MODE_DISABLED)
