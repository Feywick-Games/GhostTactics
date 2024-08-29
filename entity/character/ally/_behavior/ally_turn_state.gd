class_name AllyTurnState
extends TurnState

var _ally: Ally
var _mouse_node: Node2D
var force_redraw := false

func enter() -> void:
	super.enter()
	_ally = state_machine.state_owner as Ally
	_ally.global_position = GameState.current_level.tile_to_world(_ally.current_tile).round()
	_start_tile = _ally.current_tile
	_movement_range = GameState.current_level.grid.request_range(_ally.current_tile, 0, _ally.movement_range, Combat.RangeShape.DIAMOND)
	_starting_movement_range = _movement_range
	_interactable_range = GameState.current_level.grid.request_range(_ally.current_tile, 0, _ally.movement_range + 1, Combat.RangeShape.DIAMOND).blocked_tiles
	_interactable_range = GameState.current_level.get_interactable_tiles(_interactable_range)
	_ally.attack_state = Combat.AttackState.BASIC if not _ally.improvised_weapon else Combat.AttackState.IMPROV
	_movement_astar = _ally.create_range_astar(_movement_range, _ally.movement_range)
	_attack_range = _ally.update_ranges(_movement_range,  _interactable_range)
	EventBus.timed_out.connect(_on_timed_out)
	_mouse_node = Node2D.new()
	_mouse_node.global_position = _ally.global_position
	GameState.current_level.add_child(_mouse_node)


func _on_timed_out() -> void:
	_exiting = true


func update(delta: float) -> State:
	if Input.is_action_just_pressed("free_camera"):
		EventBus.cam_follow_requested.emit(_mouse_node)
		EventBus.display_requested.emit(true)
	elif Input.is_action_just_released("free_camera"):
		EventBus.cam_follow_requested.emit(_ally)
		EventBus.display_requested.emit(false)
	
	if not Input.is_action_pressed("free_camera"):
		
		var _current_state: State = super.update(delta)
		if _current_state:
			return _current_state
		
		var hover_tile: Vector2i = GameState.current_level.world_to_tile(_ally.get_global_mouse_position())
		if Input.is_action_pressed("move") and not acted:
			if hover_tile in _movement_range.range_tiles:
				_tile_path = _movement_astar.get_id_path(_ally.current_tile, hover_tile)
		elif acted and _highlighted_tile != hover_tile and \
		(hover_tile in _attack_range.range_tiles or hover_tile in _interactable_range):
			_highlight_targets(_highlighted_tile, false)
			_highlight_targets(hover_tile)
			_highlighted_tile = hover_tile
		
		if Input.is_action_just_pressed("guard"):
				_ally.get_viewport().set_input_as_handled()
				_ally.facing = Vector2i.ZERO
				#TODO add exit animation where they align themselves on the tile 
				_ally.global_position = GameState.current_level.tile_to_world(_ally.current_tile)
				_ally.end_turn()
				_current_state = CharacterCombatIdleState.new()
		elif Input.is_action_just_pressed("cancel"):
			if acted and not interacted:
				acted = false
				EventBus.tiles_highlighted.emit(
					[] as Array[Vector2i], [] as Array[StatusEffect], 0, Vector2i.ZERO, true
				)
				_movement_range = _starting_movement_range
				force_redraw = true
		elif Input.is_action_just_pressed("special"):
			if _ally.special.is_ready() and _ally.attack_state == Combat.AttackState.BASIC:
				_ally.attack_state = Combat.AttackState.SPECIAL
			elif _ally.attack_state == Combat.AttackState.SPECIAL:
				_ally.attack_state = Combat.AttackState.BASIC
				force_redraw = true
			elif _ally.attack_state == Combat.AttackState.IMPROV:
				_ally.attack_state = Combat.AttackState.IMPROV_THROW
			elif _ally.attack_state == Combat.AttackState.IMPROV_THROW:
				_ally.attack_state = Combat.AttackState.IMPROV
				
				
			if acted:
				EventBus.tiles_highlighted.emit(
					[] as Array[Vector2i], [] as Array[StatusEffect], 0, Vector2i.ZERO, true
				)
			force_redraw = true
		elif Input.is_action_just_pressed("act"):
			acted = true
			force_redraw = true
			_movement_range = RangeStruct.new()
		elif  Input.is_action_just_pressed("accept") and acted:
			_current_state = _ally.process_action(_highlighted_tile, _attack_range, self)
			if _current_state:
				force_redraw = true
			if interacted:
				_movement_range = RangeStruct.new()
				_interactable_range = GameState.grid.current_level.request_range(_ally.current_tile, 0, _ally.movement_range + 1, Combat.RangeShape.DIAMOND,).blocked_tiles
				_interactable_range = GameState.current_level.get_interactable_tiles(_interactable_range)
		

		return _current_state
	else:
		if Input.is_action_pressed("accept"):
			_mouse_node.global_position = _ally.get_global_mouse_position()
	return


func physics_update(delta: float) -> State:
	var current_tile: Vector2i = _ally.current_tile
	super.physics_update(delta)
	if current_tile != _ally.current_tile or force_redraw:
		force_redraw = false
		_attack_range = _ally.update_ranges(_movement_range,  _interactable_range)
		if interacted:
			_highlight_targets(_highlighted_tile)
	return
