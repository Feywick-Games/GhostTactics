class_name AllyTurnState
extends TurnState

var _ally: Ally

func enter() -> void:
	super.enter()
	_ally = state_machine.state_owner as Ally
	_ally.global_position = GameState.current_level.tile_to_world(_ally.current_tile).round()
	_start_tile = _ally.current_tile
	_movement_range = GameState.current_level.request_range(_ally.current_tile, 0, _ally.movement_range, true, [_start_tile])
	_ally.attack_state = Combat.AttackState.BASIC
	_astar = _ally.create_range_astar(_movement_range, _ally.movement_range)
	_attack_range = GameState.current_level.request_range(_ally.current_tile, _ally.basic_skill.min_range, _ally.basic_skill.max_range, true, [_start_tile], true, true)
	_ally.draw_ranges(_attack_range, _movement_range, Global.RETICLE_ATTACK_ALTAS_COORDS, Global.RETICLE_SPECIAL_2_ATLAS_COORDS)
	EventBus.timed_out.connect(_on_timed_out)


func _on_timed_out() -> void:
	_exiting = true


func update(delta: float) -> State:
	var current_tile: Vector2i = _ally.current_tile
	var force_redraw := false
	
	var parent_state: State = super.update(delta)
	if parent_state:
		return parent_state
	
	if Input.is_action_just_pressed("move"):
		var pos := _ally.get_global_mouse_position()
		var tile := GameState.current_level.world_to_tile(pos)
		if tile in _movement_range.range_tiles:
			_tile_path = _astar.get_id_path(_ally.current_tile, tile)
	elif Input.is_action_just_pressed("guard"):
			_ally.get_viewport().set_input_as_handled()
			_ally.facing = Vector2i.ZERO
			#TODO add exit animation where they align themselves on the tile 
			_ally.global_position = GameState.current_level.tile_to_world(_ally.current_tile)
			_ally.end_turn()
			return CharacterCombatIdleState.new()
	elif Input.is_action_just_pressed("cancel"):
		if not _ally.attack_state == Combat.AttackState.BASIC:
			_ally.attack_state = Combat.AttackState.BASIC
			force_redraw = true
	elif Input.is_action_just_pressed("special") and _ally.special.is_ready():
		if not _ally.attack_state == Combat.AttackState.SPECIAL:
			_ally.attack_state = Combat.AttackState.SPECIAL
			force_redraw = true
	elif Input.is_action_just_pressed("interact"):
		pass

	
	_time_since_move += delta
	if _time_since_move > Character.TIME_PER_MOVE:
		_time_since_move = 0
		_tile_path =  _ally.process_movement(delta, _tile_path)
	
	if current_tile != _ally.current_tile or force_redraw:
		if _ally.attack_state == Combat.AttackState.BASIC:
			_attack_range = GameState.current_level.request_range(_ally.current_tile, _ally.basic_skill.min_range, _ally.basic_skill.max_range, true, [_start_tile], true, true)
			_ally.draw_ranges(_attack_range, _movement_range, Global.RETICLE_ATTACK_ALTAS_COORDS, Global.RETICLE_SPECIAL_2_ATLAS_COORDS)
		elif _ally.attack_state == Combat.AttackState.SPECIAL:
			_attack_range = GameState.current_level.request_range(_ally.current_tile, _ally.special.min_range, _ally.special.max_range, true, [_start_tile], true, true)
			_ally.draw_ranges(_attack_range, _movement_range, Global.RETICLE_SPECIAL_1_ALTAS_COORDS, Global.RETICLE_CURE_1_ATLAS_COORDS)
	
	if Input.is_action_just_pressed("accept"):
		var pos := _ally.get_global_mouse_position()
		var tile: Vector2i = GameState.current_level.world_to_tile(pos)
		return _ally.process_action(tile, _attack_range, self)
		
	return
