class_name AllyCombatIdleState
extends State

var _ally: Ally


func enter() -> void:
	_ally = state_machine.state_owner as Ally
