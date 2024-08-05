class_name EnemyCombatTurnState
extends State

var _enemy: Enemy

func enter() -> void:
	_enemy = state_machine.state_owner as Enemy
	
	
func update(_delta: float) -> State:
	
	GameState.current_level.reset_map()
	EventBus.turn_ended.emit()
	return CharacterCombatIdleState.new()
