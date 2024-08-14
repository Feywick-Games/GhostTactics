class_name AllyTurnState
extends TurnState

var _ally: Ally

func enter() -> void:
	super.enter()
	_ally = state_machine.state_owner as Ally
	_ally.global_position = GameState.current_level.tile_to_world(_ally.current_tile).round()
	_start_tile = _ally.current_tile
	_movement_range = GameState.current_level.request_range(_ally.current_tile, 0, _ally.movement_range, Combat.RangeShape.DIAMOND, true)
	_interactable_range = GameState.current_level.request_range(_ally.current_tile, 0, _ally.movement_range + 1, Combat.RangeShape.DIAMOND, true).blocked_tiles
	_interactable_range = GameState.current_level.get_interactable_tiles(_interactable_range)
	_ally.attack_state = Combat.AttackState.BASIC if not _ally.improvised_weapon else Combat.AttackState.IMPROV
	_astar = _ally.create_range_astar(_movement_range, _ally.movement_range)
	_attack_range = _ally.update_ranges(_movement_range,  _interactable_range)
	EventBus.timed_out.connect(_on_timed_out)


func _on_timed_out() -> void:
	_exiting = true


func update(delta: float) -> State:
	var current_tile: Vector2i = _ally.current_tile
	var force_redraw := false
	
	var _current_state: State = super.update(delta)
	if _current_state:
		return _current_state
	
	if Input.is_action_pressed("move") and not interacted:
		var pos := _ally.get_global_mouse_position()
		var tile := GameState.current_level.world_to_tile(pos)
		if tile in _movement_range.range_tiles:
			_tile_path = _astar.get_id_path(_ally.current_tile, tile)
	
	_time_since_move += delta
	if _time_since_move > Character.TIME_PER_MOVE:
		_time_since_move = 0
		_tile_path =  _ally.process_movement(delta, _tile_path)
	
	if Input.is_action_just_pressed("guard"):
			_ally.get_viewport().set_input_as_handled()
			_ally.facing = Vector2i.ZERO
			#TODO add exit animation where they align themselves on the tile 
			_ally.global_position = GameState.current_level.tile_to_world(_ally.current_tile)
			_ally.end_turn()
			_current_state = CharacterCombatIdleState.new()
	elif Input.is_action_just_pressed("cancel"):
		if not _ally.attack_state == Combat.AttackState.BASIC and not _ally.attack_state == Combat.AttackState.IMPROV:
			_ally.attack_state = Combat.AttackState.BASIC
			force_redraw = true
	elif Input.is_action_just_pressed("special"):
		if _ally.special.is_ready() and _ally.attack_state == Combat.AttackState.BASIC:
			_ally.attack_state = Combat.AttackState.SPECIAL
		elif _ally.attack_state == Combat.AttackState.IMPROV:
			_ally.attack_state = Combat.AttackState.IMPROV_THROW
		force_redraw = true
	elif  Input.is_action_just_pressed("accept"):
		var pos := _ally.get_global_mouse_position()
		var tile: Vector2i = GameState.current_level.world_to_tile(pos)
		force_redraw = true
		_current_state = _ally.process_action(tile, _attack_range, self)
		if interacted:
			_movement_range = RangeStruct.new()
			_interactable_range = GameState.current_level.request_range(_ally.current_tile, 0, _ally.movement_range + 1, Combat.RangeShape.DIAMOND, true).blocked_tiles
			_interactable_range = GameState.current_level.get_interactable_tiles(_interactable_range)
	
	if current_tile != _ally.current_tile or force_redraw:
		force_redraw = false
		_attack_range = _ally.update_ranges(_movement_range,  _interactable_range)


	return _current_state
