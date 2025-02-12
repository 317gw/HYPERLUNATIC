#class_name Weapon
extends Node3D

signal Transitioned

var id: String # 1_要你命三千
var weapon_manager: HL.WeaponManager = null
var self_position_origin: Vector3 = Vector3.ZERO
var ready_to_action: bool = false
var special_visible_mode: bool = false

var PLAYER: HL.Player
var CAMERA: HL.Camera



func on_weapon_manager_ready() -> void:
	PLAYER = weapon_manager.PLAYER
	CAMERA = weapon_manager.CAMERA


func Enter() -> void:
	pass


func Exit() -> void:
	pass


func Update(_delta: float) -> void:
	pass


func Physics_Update(_delta: float) -> void:
	pass


func Handle_Input(_event: InputEvent) -> void:
	pass


func Main_Action() -> void: # Usually left-click trigger
	pass


func Sub_Action() -> void: # Usually left-click trigger
	pass


func Handle_Visible(_visible: bool) -> void:
	pass


func _switch_visible(_visible: bool) -> void:
	if special_visible_mode:
		Handle_Visible(_visible)
	else:
		visible = _visible
