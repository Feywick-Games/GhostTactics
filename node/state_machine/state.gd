class_name State
extends RefCounted

var state_machine : StateMachine

func enter() -> void:
	pass


func exit() -> void:
	pass


func update(_delta : float) -> State:
	return null
	
	
func physics_update(_delta : float) -> State:
	return null


func unhandled_input(_event : InputEvent) -> State:
	return null


func input(_event : InputEvent) -> State:
	return null
