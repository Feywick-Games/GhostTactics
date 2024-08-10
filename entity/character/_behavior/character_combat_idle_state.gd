class_name CharacterCombatIdleState
extends State

var _character: Character
var _exiting := false

func enter() -> void:
	_character = state_machine.state_owner as Character
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.encounter_ended.connect(_on_encounter_ended)


func _on_encounter_ended() -> void:
	state_machine.change_state(_character.init_state.new())


func _on_turn_started(unit: Character) -> void:
	if unit == _character:
		state_machine.change_state(_character.turn_state.new())
