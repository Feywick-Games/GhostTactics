class_name EnemyTurnState
extends TurnState

var _enemy: Enemy
var _target: Character
var _full_attack_range: Array[Vector2i]
var _special_atlas_coords: Vector2i = Global.RETICLE_SPECIAL_1_ALTAS_COORDS
var _special_overlap_atlas_coords: Vector2i = Global.RETICLE_CURE_1_ATLAS_COORDS
var _is_acting := false

func enter() -> void:
	super.enter()
	_enemy = state_machine.state_owner as Enemy
	var units_on_field: Array[Node] = _enemy.get_tree().get_nodes_in_group("ally")
	units_on_field.shuffle()
	var target_list: Array[Ally]
	_start_tile = _enemy.current_tile
	_movement_range = GameState.current_level.request_range(_enemy.current_tile, 0,  _enemy.movement_range, false, [_start_tile])
	_attack_range = GameState.current_level.request_range(_enemy.current_tile, _enemy.minimum_attack_range, _enemy.attack_range, false, [_start_tile], true, true)
	
	for tile: Vector2i in _movement_range.range_tiles:
		var valid_tiles := GameState.current_level.request_range(tile, _enemy.minimum_attack_range, _enemy.attack_range, false, [_start_tile], true, true)
		for valid: Vector2i in valid_tiles.range_tiles:
			if valid not in _full_attack_range:
				_full_attack_range.append(valid)
	var all_allies: Array[Ally]
	
	for unit: Ally in units_on_field:
		if unit.current_tile in _full_attack_range:
			target_list.append(unit)
		all_allies.append(unit)
	
	_target = pick_target(target_list, all_allies)
	var target_tile = pick_tile()
	_tile_path = GameState.current_level.get_id_path(_enemy.current_tile, target_tile)



func pick_target(target_list: Array[Ally], all_allys: Array[Ally]) -> Ally:
	var current_target: Ally
	
	if target_list.is_empty():
		var min_distance: float = INF
		for target in all_allys:
			var dist: int = GameState.current_level.get_id_path(target.current_tile, _enemy.current_tile, false, true, true).size()
			if dist < min_distance:
				current_target = target
				min_distance = dist
		_is_acting = false
	else:
		var min_health: float = INF
		for target in target_list:
			if target.health < min_health:
				current_target = target
				min_health  = target.health
		_is_acting = true
	return current_target


func pick_tile() -> Vector2i:
	var ideal_distance: int = _enemy.attack_range
	var desired_tile: Vector2i = _start_tile
	var desired_distance: int 
	var start_distance: int = GameState.current_level.get_id_path(_start_tile, _target.current_tile, false, true, true, true).size() - 1
	desired_distance = abs(start_distance - ideal_distance)
	for tile in _movement_range.range_tiles:
		var dist: int = GameState.current_level.get_id_path(tile, _target.current_tile, false, true, true, true).size()
		# deduct 1 for start tile
		dist -= 1
		if abs(dist - ideal_distance) <= desired_distance:
			desired_distance = abs(dist - ideal_distance)
			desired_tile = tile
	
	return desired_tile


func update(delta: float) -> State:
	var current_tile := _enemy.current_tile
	
	_time_since_move += delta
	if _time_since_move > Character.TIME_PER_MOVE:
		_time_since_move = 0
		_tile_path =  _enemy.process_movement(delta, _tile_path)
	
	
	if current_tile != _enemy.current_tile:
		if _enemy.attack_state == Character.AttackState.BASIC:
			_attack_range = GameState.current_level.request_range(_enemy.current_tile, _enemy.minimum_attack_range, _enemy.attack_range, false, [_start_tile], true, true)
			_enemy.draw_ranges(_attack_range, _movement_range, Global.RETICLE_ATTACK_ALTAS_COORDS, Global.RETICLE_SPECIAL_2_ATLAS_COORDS)
		elif _enemy.attack_state == Character.AttackState.SPECIAL:
			_attack_range = GameState.current_level.request_range(_enemy.current_tile, _enemy.special.min_range, _enemy.special.range, false, [_start_tile], true, true)
			_enemy.draw_ranges(_attack_range, _movement_range, _special_atlas_coords, _special_overlap_atlas_coords)
	
	if not _exiting and _tile_path.is_empty() and _is_acting:
		if _enemy.attack_state == Character.AttackState.BASIC:
			_enemy.process_action(_target.current_tile, _attack_range, self)
	elif _exiting or (_tile_path.is_empty() and not _is_acting):
		_enemy.end_turn()
		return CharacterCombatIdleState.new()
	
	return
