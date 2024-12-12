extends Node3D

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
	if initial_weapon:
		initial_weapon.Enter()
		current_weapon = initial_weapon


func _unhandled_input(event: InputEvent) -> void:
	if current_weapon:
		current_weapon.Handle_Input(event)


func _process(delta: float) -> void:
	if current_weapon:
		current_weapon.Update(delta)
	is_first_tick = false


func _physics_process(delta: float) -> void:
	if current_weapon:
		current_weapon.Physics_Update(delta)
	is_first_tick = false


func on_child_transition(weapon: HL.Weapon, new_weapon_name: String):
	if weapon != current_weapon:
		return

	var new_weapon: HL.Weapon = player_weapons.get(new_weapon_name.to_lower())
	if !new_weapon:
		return

	if current_weapon:
		current_weapon.Exit()
		if print_transition:
			print("out: %s\n" %current_weapon)

	new_weapon.Enter()
	if print_transition:
		print("in: %s" %new_weapon)
	last_weapon = weapon
	current_weapon = new_weapon
	_current = current_weapon.name

	is_first_tick = true


func _on_main_action() -> void: # Usually left-click trigger
	if current_weapon:
		current_weapon.Main_Action()


func _on_sub_action() -> void: # Usually left-click trigger
	if current_weapon:
		current_weapon.Sub_Action()
