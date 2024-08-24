class_name EnemyTurnState
extends TurnState

const HIGHLIGHT_TIME: float = 2.5

var _enemy: Enemy
var _target: Character
var _full_attack_range := RangeStruct.new()
var _full_special_range := RangeStruct.new()
var _special_atlas_coords: Vector2i = Global.RETICLE_SPECIAL_1_ALTAS_COORDS
var _special_overlap_atlas_coords: Vector2i = Global.RETICLE_CURE_1_ATLAS_COORDS
var _is_acting := false
var _is_processing_custom := false
var _time_highlight: float = 0
var _has_highlighted := false


class TargetPriority:
	var target:  Character
	var knock_out_likelihood: float
	var basic_skill_likelihood: float
	var distance: float
	var special_likelihood: float
	var rating: float
	
	func  _init(target_to_calc: Character) -> void:
		target = target_to_calc
	
	

func enter() -> void:
	super.enter()
	_enemy = state_machine.state_owner as Enemy
	var units_on_field: Array[Node] = _enemy.get_tree().get_nodes_in_group("ally")
	units_on_field.shuffle()
	var target_list: Array[Ally]
	_start_tile = _enemy.current_tile
	_movement_range = GameState.current_level.request_range(_enemy.current_tile, 0,  _enemy.movement_range, Combat.RangeShape.DIAMOND, false)
	_interactable_range =  GameState.current_level.request_range(_enemy.current_tile, 0,  _enemy.movement_range + 1, Combat.RangeShape.DIAMOND, false).blocked_tiles
	_interactable_range = GameState.current_level.get_interactable_tiles(_interactable_range)
	for tile: Vector2i in _movement_range.range_tiles:
		var valid_tiles := GameState.current_level.request_range(tile, _enemy.basic_skill.min_range, _enemy.basic_skill.max_range, _enemy.basic_skill.range_shape, false, true, true)
		_full_attack_range.absorb(valid_tiles)
		
	if _enemy.special:
		for tile: Vector2i in _movement_range.range_tiles:
			var valid_tiles := GameState.current_level.request_range(tile, _enemy.special.min_range, _enemy.special.max_range, _enemy.special.range_shape, false, true, true)
			_full_special_range.absorb(valid_tiles)
			
	var all_allies: Array[Ally]
	for unit: Ally in units_on_field:
		if unit.current_tile in _full_attack_range.range_tiles:
			target_list.append(unit)
		elif unit.current_tile in _full_special_range.range_tiles:
			target_list.append(unit)
		all_allies.append(unit)
	

	_adjust_priority()
	
	var standard_priorities : Array[float] = [_enemy.special_priority, _enemy.knock_out_priority, _enemy.safety_priority, _enemy.damage_priority]
	var should_custom := true
	for priority: float in standard_priorities:
		if priority > _enemy.custom_priority:
			should_custom = false
			break
	
	if not should_custom:
		_target = _pick_target(target_list, all_allies)
		var target_tile = _pick_tile()
		_tile_path = GameState.current_level.get_id_path(_enemy.current_tile, target_tile)
	else:
		_is_processing_custom = true
		_take_custom_action()


func _adjust_priority() -> void:
	pass

func _calculate_custom_likelihood() -> float:
	return 0.0


func _take_custom_action() -> void:
	pass
	
	
	
func _process_custom_action() -> void:
	pass


func _pick_target(target_list: Array[Ally], all_allys: Array[Ally]) -> Ally:
	var current_target: Ally
	
	var target_priorities: Array[TargetPriority]
	if target_list.is_empty():
		for target in all_allys:
			var target_priority := TargetPriority.new(target)
			target_priority.distance = GameState.current_level.get_id_path(_enemy.current_tile, target.current_tile, false, false, false, true).size()
			target_priority.distance = 1 - (target_priority.distance/float(_enemy.movement_range))
			target_priority.distance *= Enemy.DISTANCE_PRIORITY
			var damage_likelihood =  float(_enemy.accuracy) / float(target.evasion)
			target_priority.knock_out_likelihood = 1 if target.health - _enemy.basic_skill.get_hit_damage() < 0 else 0
			target_priority.knock_out_likelihood *= damage_likelihood
			target_priorities.append(target_priority)
		_is_acting = false
	else:
		for target in target_list:
			var target_priority := TargetPriority.new(target)
			target_priority.distance = GameState.current_level.get_id_path(_enemy.current_tile, target.current_tile, false, false, false, true).size() - 1
			target_priority.distance = 1 - (target_priority.distance/float(_enemy.movement_range))
			var damage_likelihood =  float(_enemy.accuracy) / float(target.evasion)
			target_priority.knock_out_likelihood = 1 if target.health - _enemy.basic_skill.get_hit_damage() < 0 else 0
			target_priority.knock_out_likelihood *= damage_likelihood
			if target.current_tile in _full_attack_range.range_tiles: 
				var basic_skill_state: SkillState = (_character.basic_skill.state.new(_character.basic_skill, target.current_tile) as SkillState)
				target_priority.basic_skill_likelihood = basic_skill_state.calc_skill_likelihood(_full_attack_range)
			if _enemy.special and target.current_tile in _full_special_range.range_tiles:
				var special_skill_state: SkillState = (_character.special.state.new(_character.special, target.current_tile) as SkillState)
				target_priority.special_likelihood = special_skill_state.calc_skill_likelihood(_full_special_range)
				target_priority.special_likelihood *=damage_likelihood
			target_priorities.append(target_priority)
		_is_acting = true
	
	for target_priority: TargetPriority in target_priorities:
		target_priority.rating += target_priority.distance
		target_priority.rating += target_priority.knock_out_likelihood * _enemy.knock_out_priority
		target_priority.rating += target_priority.special_likelihood * _enemy.special_priority
		target_priority.rating += target_priority.basic_skill_likelihood * _enemy.basic_skill_priority
	
	var max_rating: float = -INF
	for target_priority: TargetPriority in target_priorities:
		if target_priority.rating > max_rating:
			max_rating = target_priority.rating
			current_target = target_priority.target
			target_priority = target_priority
			_enemy.attack_state = Combat.AttackState.BASIC if target_priority.basic_skill_likelihood > target_priority.special_likelihood or target_priority.special_likelihood == 0 else Combat.AttackState.SPECIAL
	
	return current_target


func _pick_tile() -> Vector2i:
	var desired_skill = _enemy.basic_skill if _enemy.attack_state == Combat.AttackState.BASIC else _enemy.special
	var skill_state: SkillState = (desired_skill.state.new(desired_skill, _target.current_tile) as SkillState)
	_attack_range = GameState.current_level.request_range(_enemy.current_tile, desired_skill.min_range, desired_skill.max_range, desired_skill.range_shape, false, true, true)
	var ideal_distance: int = desired_skill.max_range
	var desired_tile: Vector2i = _start_tile
	var desired_distance: int 
	var start_distance: int = GameState.current_level.get_id_path(_start_tile, _target.current_tile, false, true, true).size() - 1
	desired_distance = abs(start_distance - ideal_distance)
	if not _is_acting:
		for tile in _movement_range.range_tiles:
			var dist: int = GameState.current_level.get_id_path(tile, _target.current_tile, false, true, true).size() - 1
			if abs(dist - ideal_distance) < desired_distance:
				desired_distance = abs(dist - ideal_distance)
				desired_tile = tile
	else:
		var desired_skill_likelihood: float = 0
		for tile in _movement_range.range_tiles:
			var dist: int = GameState.current_level.get_id_path(tile, _target.current_tile, false, true, true).size() - 1
			var target_range: RangeStruct = GameState.current_level.request_range(tile, desired_skill.min_range, desired_skill.max_range, desired_skill.range_shape, false, true, true)
			var range_struct := RangeStruct.new()
			range_struct.range_tiles.append(tile)
			var likelihood: float = skill_state.calc_skill_likelihood(range_struct)
			if abs(dist - ideal_distance)  < desired_distance and _target.current_tile in target_range.range_tiles:
				desired_tile = tile
				desired_skill_likelihood = likelihood

	return desired_tile


func update(delta: float) -> State:
	if not _is_processing_custom:
		var current_tile := _enemy.current_tile
		
		_time_since_move += delta
		if _time_since_move > Character.TIME_PER_MOVE:
			_time_since_move = 0
			_tile_path =  _enemy.process_movement(delta, _tile_path)
		
		
		if current_tile != _enemy.current_tile:
			_attack_range = _enemy.update_ranges(_movement_range,  _interactable_range)
		if not _exiting and _tile_path.is_empty() and _is_acting:
			if _time_highlight >= HIGHLIGHT_TIME:
				return _enemy.process_action(_target.current_tile, _attack_range, self)
			else:
				if not _has_highlighted:
					_movement_range = RangeStruct.new()
					_has_highlighted = true
					_highlight_targets(_target.current_tile, true)
				_time_highlight += delta
		elif _exiting or (_tile_path.is_empty() and not _is_acting):
			_enemy.end_turn()
			return CharacterCombatIdleState.new()
	else:
		_process_custom_action()
	
	return
