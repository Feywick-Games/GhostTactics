class_name AllyRoamFollowState
extends AllyRoamState

var _current_direction: String

func enter() -> void:
	super.enter()
	_ally.nav_agent.velocity_computed.connect(_on_velocity_computed)
	
	
func update(delta: float) -> State:
	if _ally.follow_order == 0:
		return AllyRoamLeadState.new()
	
	if _ally.is_animated:
		var direction := _ally.animator.get_current_direction(_ally.velocity)
		if direction != _current_direction:
			_ally.animator.play_directional("idle", _ally.velocity.rotated(-PI/4.0), true)
	
	_ally.nav_agent.target_position = GameState.ally_order[_ally.follow_order - 1].global_position
	
	return super.update(delta)


func physics_update(_delta: float) -> State:	
	if _ally.nav_agent.is_navigation_finished():
		return
	
	var target_position := _ally.nav_agent.get_next_path_position()
	_ally.nav_agent.velocity = (target_position - _ally.global_position).normalized()
	_ally.nav_agent.velocity *= Global.PLAYER_SPEED

	return


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	_ally.velocity = safe_velocity
	_ally.move_and_slide()
	_ally.position = _ally.position.round()
