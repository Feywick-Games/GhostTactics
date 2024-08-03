class_name CharacterCombatIdleState
extends State

var _character: Character


func enter() -> void:
	_character = state_machine.state_owner as Character
	EventBus.turn_started.connect(_on_turn_started)


func _on_turn_started(unit: Character) -> void:
	if unit == _character:
		if unit is Ally:
			state_machine.change_state(AllyCombatTurnState.new())
