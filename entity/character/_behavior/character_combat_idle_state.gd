class_name CharacterCombatIdleState
extends State

var _character: Character
var _encounter_ended := false
var _turn_started := false

func enter() -> void:
	_character = state_machine.state_owner as Character
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.encounter_ended.connect(_on_encounter_ended)
	if _character.is_animated:
		_character.animator.play_directional("idle", Vector2.ZERO)


func _on_encounter_ended() -> void:
	_encounter_ended = true

func _on_turn_started(unit: Character) -> void:
	if unit == _character:
		_turn_started = true


func update(_delta: float) -> State:
	if _encounter_ended:
		_character.end_encounter()
		return _character.init_state.new()
	elif _turn_started:
		return _character.turn_state.new()
	return
