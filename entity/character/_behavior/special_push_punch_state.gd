class_name PushPunchSpecialState
extends SpecialState

const TIME_PER_INCREMENT: float = .3
const TIME_TO_EXIT: float = 1.0

var _push_range: Array[Vector2i]
var _time_since_increment: float = 0
var _direction: Vector2i
var increment: int = 0
var pushing := false
var _max_push_distance: int = 0
var _target_unit: Character
var _time_since_exiting: float = 0
var _max_is_collision := false
var _o_target: Character

func enter() -> void:
	super.enter()
	var _push_range = [_target_tile]
	_direction =  Vector2i(Vector2(_target_tile - _character.current_tile).normalized().round())
	
	for i in range(1, _character.special.custom_values["push_distance"] + 1):
		if not GameState.current_level.grid.is_point_solid(_target_tile + (_direction * i)) and \
		GameState.current_level.grid.region.has_point(_target_tile + (_direction * i)):
			_max_push_distance += 1
		else:
			break
	
	var collision_point := _target_tile + (_direction * (_max_push_distance + 1))
	if GameState.current_level.grid.is_point_solid(collision_point):
		_max_is_collision = true
		
		var unit := GameState.current_level.get_unit_from_tile(collision_point)
		
		if unit:
			_o_target = unit
		
	
	_tile_path = GameState.current_level.get_id_path(_target_tile, _target_tile + (_direction * _max_push_distance))
	
	_draw_range()


func _draw_range() -> void:
	GameState.current_level.draw_range(_push_range, Global.RETICLE_SPECIAL_1_ALTAS_COORDS)
	if (_direction * _max_push_distance) + _target_tile in _push_range:
		GameState.current_level.select_tile((_direction * _max_push_distance) + _target_tile)


func _push(delta: float) -> void:
	_target_unit.velocity = Vector2.ZERO
	if not _tile_path.is_empty():
		_time_since_move += delta
		if _time_since_move >= Character.TIME_PER_MOVE:
			_time_since_move = 0
			var path_position :=  GameState.current_level.tile_to_world(_tile_path[0])
			var map_position := GameState.current_level.tile_to_world(_character.current_tile)
			if path_position.distance_to(_target_unit.global_position) > Character.SNAP_DISTANCE:
				var dir: Vector2 = (path_position - _target_unit.global_position).normalized()
				_target_unit.global_position += dir * Global.PLAYER_SPEED * 4.0 * delta
				_target_unit.global_position = _target_unit.global_position.snapped(Vector2(2,1))
			if not path_position.distance_to(_target_unit.global_position) > Character.SNAP_DISTANCE:
				if len(_tile_path) == 1:
					_target_unit.global_position = path_position.round()
				_tile_path.pop_front()
			if not _tile_path.is_empty() and \
			path_position.distance_to(_target_unit.global_position) < map_position.distance_to(_target_unit.global_position):
				_target_unit.current_tile = _tile_path[0]
	else:
		_exiting = true
		GameState.current_level.update_unit_registry(_target_unit.current_tile, _target_unit)
		if increment ==  _max_push_distance and _max_is_collision:
			# guaranteed as impact was precalculated
			_target_unit.take_damage(_character.special.damage * 2.0, _character.facing, INF, _character.target_hit, Combat.Status.PUSHED)
			if _o_target:
				_o_target.take_damage(_character.special.damage, _character.facing, INF, _character.target_hit, Combat.Status.HIT)
		else:
			_target_unit.take_damage(_character.special.damage, _direction, INF, _character.target_hit, Combat.Status.PUSHED)
		_character.target_hit.emit()


func update(delta: float) -> State:
	if _encounter_ended:
		return _character.init_state.new()
	elif not pushing:
		if Input.is_action_pressed("accept"):
			_time_since_increment += delta
			
			if _time_since_increment > TIME_PER_INCREMENT:
				_time_since_increment = 0
				increment += 1
				if increment > _max_push_distance:
					var unit = GameState.current_level.get_unit_from_tile(_target_tile)
					unit.take_damage(_character.special.damage, _character.facing,  _character.accuracy, _character.target_hit, Combat.Status.HIT)
				else:
					_push_range.append(_target_tile + (_direction * increment))
					_draw_range()
			
		# TODO account for push animation
		elif Input.is_action_just_released("accept"):
			_target_unit = GameState.current_level.get_unit_from_tile(_target_tile)
			var is_hit = _target_unit.is_hit(_character.accuracy)
			if is_hit:
				EventBus.cam_follow_requested.emit(_target_unit)
				pushing = true
				_tile_path = _tile_path.slice(0, increment + 1)
			else:
				_character.end_turn()
				return CharacterCombatIdleState.new()
				
	elif not _exiting:
		_push(delta)
	elif _exiting:
		_time_since_exiting += delta
		if _time_since_exiting > TIME_TO_EXIT:
			_character.end_turn()
			return CharacterCombatIdleState.new()

	return


func exit() -> void:
	GameState.current_level.reset_map()
