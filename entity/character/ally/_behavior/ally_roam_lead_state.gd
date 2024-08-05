class_name AllyRoamLeadState
extends AllyRoamState

var _current_direction: String

func enter() -> void:
	super.enter()
	

func update(delta: float) -> State:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("move"):
		direction = _ally.get_local_mouse_position().normalized()
	
	if _ally.is_animated:
		var dir := _ally.animator.get_current_direction(_ally.velocity)
		if dir != _current_direction:
			_ally.animator.play_directional("idle", _ally.velocity.rotated(-PI/4.0), true)
	
	
	_ally.velocity = direction * Global.PLAYER_SPEED
	
	EventBus.cam_follow_requested.emit(_ally)
	
	return super.update(delta)
	
	
func physics_update(_delta: float) -> State:
	_ally.move_and_slide()
	_ally.position = _ally.position.round()
	return
