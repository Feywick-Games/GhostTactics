class_name AllyCombatBeginState
extends State

const SNAP_DISTANCE: float = .05

var _target_position: Vector2
var _ally: Ally

func enter() -> void:
	_ally = state_machine.state_owner as Ally
	
	_target_position = GameState.current_level.tile_to_world(
		GameState.current_level.get_nearest_available_tile(_ally.global_position)
	)


func update(_delta: float) -> State:
	if _ally.global_position.distance_to(_target_position) > SNAP_DISTANCE:
		_ally.global_position += (_target_position - _ally.global_position).normalized() * 2.0
		_ally.global_position = _ally.global_position.round()
	else:
		return AllyCombatIdleState.new()
	
	return
