class_name StateMachine
extends Node

@export var initial_state: State
@export var print_transition: bool = false

var last_state: State
var current_state: State # 当前状态
var states: Dictionary = {}
var is_first_tick: bool = false


func _ready() -> void:
	await owner.ready
	for child in get_children():
		if child is State:
			child.state_machine = self
			child.Transitioned.connect(on_child_transition)
			states[child.name.to_lower()] = child
	if initial_state:
		initial_state.Enter()
		current_state = initial_state


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.Handle_Input(event)


func _process(delta: float) -> void:
	if current_state:
		current_state.Update(delta)
	is_first_tick = false


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.Physics_Update(delta)
	is_first_tick = false


func on_child_transition(state: State, new_state_name: String):
	if state != current_state:
		return

	var new_state:State = states.get(new_state_name.to_lower())
	if !new_state:
		return

	if current_state:
		current_state.Exit()
		if print_transition:
			print("out: %s\n" %current_state)

	new_state.Enter()
	if print_transition:
		print("in: %s" %new_state)
	last_state = state
	current_state = new_state

	is_first_tick = true
