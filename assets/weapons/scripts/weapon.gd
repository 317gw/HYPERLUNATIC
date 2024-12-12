#class_name Weapon
extends Node3D

signal Transitioned

var weapon_manager: HL.Controller.WeaponManager = null
var PLAYER: HL.Controller.Player
var self_position_origin: Vector3 = Vector3.ZERO


func _ready() -> void: # 节点准备好时执行
	await owner.ready
	PLAYER = owner
	Ready()


func Ready() -> void:
	pass


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
