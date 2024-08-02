class_name AllyRoamLeadState
extends AllyRoamState

func update(delta: float) -> State:
	var direction := Vector2.ZERO

	if Input.is_action_pressed("move"):
		direction = _ally.get_local_mouse_position().normalized()

	_ally.velocity = direction * Global.PLAYER_SPEED
	
	return super.update(delta)
	
	
func physics_update(_delta: float) -> State:
	_ally.move_and_slide()
	_ally.position = _ally.position.round()
	return
