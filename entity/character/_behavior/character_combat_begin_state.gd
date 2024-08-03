class_name CharacterCombatBeginState
extends State

const SNAP_DISTANCE: float = 1

var _target_position: Vector2
var _character: Character

func enter() -> void:
	_character = state_machine.state_owner as Character
	_character.current_tile = GameState.current_level.get_nearest_available_tile(_character.global_position)
	_target_position = GameState.current_level.tile_to_world(_character.current_tile)


func update(_delta: float) -> State:
	if _character.global_position.distance_to(_target_position) > SNAP_DISTANCE:
		_character.global_position += (_target_position - _character.global_position).normalized() * 2.0
		_character.global_position = _character.global_position.round()
	else:
		_character.ready_for_battle = true
		_character.global_position = GameState.current_level.tile_to_world(_character.current_tile)
		return CharacterCombatIdleState.new()
	
	return
