class_name AllyCombatBeginState
extends State

var _target_position: Vector2
var _ally: Ally

func enter() -> void:
	_ally = state_machine.state_owner as Ally
	
	_target_position = GameState.current_level.tile_to_world(
		GameState.current_level.get_nearest_available_tile(_ally.global_position)
	)


func update(_delta: float) -> void:
	if _ally.global_position != _target_position:
		_ally.position += (_target_position - _ally.global_position).normalized() * Global.PLAYER_SPEED
	else:
		return AllyCombatIdleState.new()
	
	return
