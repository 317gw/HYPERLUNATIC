class_name WeaponStateMachine
extends Node3D

@export var PLAYER: HL.Player
@export var CAMERA: HL.Camera
@export var initial_weapon: HL.Weapon
@export var print_transition: bool = false

var last_weapon: HL.Weapon
var current_weapon: HL.Weapon
var _current: String

var player_weapons: Dictionary = {}
var is_first_tick: bool = false


func _ready() -> void:
	await owner.ready
	for child in get_children():
		if child is HL.Weapon:
			child.weapon_manager = self
			child.Transitioned.connect(on_child_transition)
			player_weapons[child.name.to_lower()] = child
			child._switch_visible(false) # 显示保险
			child.on_weapon_manager_ready()
	if initial_weapon:
		initial_weapon.Enter()
		current_weapon = initial_weapon
		initial_weapon._switch_visible(true)
		_current = initial_weapon.name


func _unhandled_input(event: InputEvent) -> void:
	if current_weapon:
		current_weapon.Handle_Input(event)

	# switch weaponsssssss
	if event.is_action_pressed("weapon_rifle"):
		on_child_transition(current_weapon, "Rifle")
	if event.is_action_pressed("weapon_holy_fisher"):
		on_child_transition(current_weapon, "HolyFisher")


func _process(delta: float) -> void:
	if current_weapon:
		current_weapon.Update(delta)
	is_first_tick = false


func _physics_process(delta: float) -> void:
	if current_weapon:
		current_weapon.Physics_Update(delta)
	is_first_tick = false


func on_child_transition(now_weapon: HL.Weapon, new_weapon_name: String):
	if now_weapon != current_weapon:
		return

	var new_weapon: HL.Weapon = player_weapons.get(new_weapon_name.to_lower())
	if !new_weapon:
		return

	if current_weapon:
		current_weapon.Exit()
		current_weapon.ready_to_action = false
		current_weapon._switch_visible(false)
		if print_transition:
			print("out: %s\n" %current_weapon)

	new_weapon.Enter()
	if print_transition:
		print("in: %s" %new_weapon)
	last_weapon = now_weapon

	# 换
	_current = new_weapon.name
	new_weapon.ready_to_action = true
	new_weapon._switch_visible(true)
	current_weapon = new_weapon
	is_first_tick = true


func _on_main_action() -> void: # Usually left-click trigger
	if current_weapon:
		current_weapon.Main_Action()


func _on_sub_action() -> void: # Usually left-click trigger
	if current_weapon:
		current_weapon.Sub_Action()
