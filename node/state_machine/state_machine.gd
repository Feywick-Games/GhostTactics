class_name StateMachine
extends Node

var _current_state : State
var state_owner : Node

func _init(state_owner_ : Node, init_state : State) -> void:
	self.state_owner = state_owner_
	_current_state = init_state
	_current_state.state_machine = self
	_current_state.enter()


func _process(delta: float) -> void:
	var next_state := _current_state.update(delta)
	if next_state:
		change_state(next_state)


func _physics_process(delta: float) -> void:
	var next_state := _current_state.physics_update(delta)
	if next_state:
		change_state(next_state)


func _unhandled_input(event: InputEvent) -> void:
	var next_state := _current_state.unhandled_input(event)
	if next_state:
		change_state(next_state)


func _input(event: InputEvent) -> void:
	var next_state := _current_state.unhandled_input(event)
	if next_state:
		change_state(next_state)


func change_state(state : State) -> void:
	_current_state.exit()
	state.state_machine = self
	state.enter()
	_current_state = state


func get_owner_node(type : StringName, recursive := false) -> Node:
	if not state_owner.is_class(type):
		var candidates : Array[Node] = state_owner.find_children("*", type, recursive)
		if not candidates.is_empty():
			return candidates[0]
	else:
		return state_owner
	return null


func get_owner_nodes(type : StringName, recursive := false) -> Array[Node]:
	var out : Array[Node] = []
	if state_owner.get_class() == type:
		out.append(state_owner)
	var candidates : Array[Node] = state_owner.find_children("*", type, recursive)
	out.append_array(candidates)
	return out


func get_owner_node_by_unique_name(u_name : StringName):
	return state_owner.get_node("%" + u_name)
