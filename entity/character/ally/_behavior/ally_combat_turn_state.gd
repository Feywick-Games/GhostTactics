class_name AllyCombatTurnState
extends State

const SNAP_DISTANCE: int = 2.4
const TIME_PER_MOVE: float = .03

enum AttackState {
	BASIC,
	SPECIAL
}


var _ally: Ally
var _movement_range: RangeStruct
var _attack_range: RangeStruct = RangeStruct.new()
var _tile_path: Array[Vector2i]
var _time_since_move: float = 0
var _astar: AStarGrid2D
var _selecting_facing := false
var _start_tile: Vector2i
var _attack_state: AttackState
var _exiting := false

func enter() -> void:
	_ally = state_machine.state_owner as Ally
	_ally.global_position = GameState.current_level.tile_to_world(_ally.current_tile).round()
	_start_tile = _ally.current_tile
	_movement_range = GameState.current_level.request_range(_ally.current_tile, _ally.movement_range, true, [_start_tile])
	_attack_state = AttackState.BASIC
	_create_movement_astar()
	_draw_ranges()
	EventBus.timed_out.connect(_on_timed_out)


func _on_timed_out() -> void:
	_exiting = true


func _draw_ranges() -> void:
	var attack_altas_coords: Vector2i
	var overlap_atlas_coords: Vector2i
	if _attack_state == AttackState.BASIC:
		_attack_range = GameState.current_level.request_range(_ally.current_tile, _ally.attack_range, true, [_start_tile], true, true)
		attack_altas_coords = Global.RETICLE_ATTACK_ALTAS_COORDS
		overlap_atlas_coords = Global.RETICLE_SPECIAL_2_ATLAS_COORDS
	else:
		_attack_range =  GameState.current_level.request_range(_ally.current_tile, _ally.special.range, true, [_start_tile], true, true)
		attack_altas_coords = Global.RETICLE_SPECIAL_1_ALTAS_COORDS
		overlap_atlas_coords = Global.RETICLE_CURE_2_ATLAS_COORDS

	
	# color tiles differently when attacks overlap with movement 
	var overlap_tiles: Array[Vector2i]
	var attack_only_tiles: Array[Vector2i]
	
	for tile in _attack_range.range_tiles:
		if tile in _movement_range.range_tiles:
			overlap_tiles.append(tile)
		else:
			attack_only_tiles.append(tile)
	
	
	_attack_range.range_tiles.remove_at(_attack_range.range_tiles.find(_ally.current_tile))
	GameState.current_level.reset_map()
	GameState.current_level.draw_range(_movement_range.range_tiles, Global.RETICLE_MOVE_ALTAS_COORDS)
	GameState.current_level.draw_range(_attack_range.blocked_tiles, Global.RETICLE_BLOCKED_ALTAS_COORDS)
	GameState.current_level.draw_range(_movement_range.blocked_tiles, Global.RETICLE_BLOCKED_ALTAS_COORDS)
	GameState.current_level.draw_range(attack_only_tiles, attack_altas_coords)
	GameState.current_level.draw_range(overlap_tiles, overlap_atlas_coords)
	GameState.current_level.map.set_cell(_ally.current_tile, 0, Global.RETICLE_MOVE_ALTAS_COORDS)
	GameState.current_level.select_tile(_ally.current_tile)


func _create_movement_astar() -> void:
	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(_ally.current_tile - Vector2i(_ally.movement_range, _ally.movement_range),  (Vector2i(_ally.movement_range, _ally.movement_range) * 2) + Vector2i.ONE)
	_astar.cell_shape = AStarGrid2D.CELL_SHAPE_ISOMETRIC_DOWN
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.cell_size = Global.TILE_SIZE
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()
	
	for y in range(_astar.region.position.y, _astar.region.end.y):
		for x in range(_astar.region.position.x, _astar.region.end.x):
			if not Vector2i(x,y) in _movement_range.range_tiles:
				_astar.set_point_solid(Vector2i(x,y))

func _process_movement(delta: float) -> void:
	_ally.velocity = Vector2.ZERO
	if not _tile_path.is_empty():
		_time_since_move += delta
		if _time_since_move >= TIME_PER_MOVE:
			_time_since_move = 0
			var path_position :=  GameState.current_level.tile_to_world(_tile_path[0])
			var map_position := GameState.current_level.tile_to_world(_ally.current_tile)
			if path_position.distance_to(_ally.global_position) > SNAP_DISTANCE:
				var dir: Vector2 = (path_position - _ally.global_position).normalized()
				_ally.global_position += dir * Global.PLAYER_SPEED * 4.0 * delta
				_ally.global_position = _ally.global_position.snapped(Vector2(2,1))
				
				if _ally.is_animated:
					var anim_dir := Vector2(_tile_path[0] - _ally.current_tile).normalized()
					_ally.animator.play_directional("idle", anim_dir)
			if not path_position.distance_to(_ally.global_position) > SNAP_DISTANCE:
				if len(_tile_path) == 1:
					_ally.global_position = path_position.round()
				_tile_path.pop_front()
			if not _tile_path.is_empty() and \
			path_position.distance_to(_ally.global_position) < map_position.distance_to(_ally.global_position):
				_ally.current_tile = _tile_path[0]
				_draw_ranges()


func _process_action() -> State:
	if Input.is_action_just_pressed("accept"):
		var pos := _ally.get_global_mouse_position()
		var tile := GameState.current_level.world_to_tile(pos)
		
		if _ally.is_animated:
			var dir := Vector2(tile - _ally.current_tile).normalized()
			_ally.animator.play_directional("idle", dir)
		
		
		if tile in _attack_range.range_tiles:
			var unit: Character = GameState.current_level.get_unit_from_tile(tile)
			if unit and unit != _ally:
				_ally.facing = Vector2i(Vector2(tile - _ally.current_tile).normalized().round())
				if _attack_state == AttackState.BASIC:
					if _ally.name == "Izzy":
						_ally.animator.play("basic_attack_down")
						_ally.animator.queue("idle_" + _ally.animator.get_current_direction(dir))
					
					unit.take_damage(_ally.attack_damage, _ally.facing, _ally.target_hit)
					print("atacked ", _ally.facing)
					_ally.end_turn()
					return CharacterCombatIdleState.new()
				else:
					EventBus.timer_stopped.emit()
					return _ally.special.state.new(unit.current_tile)
				
	return


func update(delta: float) -> State:
	
	if _exiting:
		_ally.end_turn()
		return CharacterCombatIdleState.new()
	
	if Input.is_action_just_pressed("move") and not _selecting_facing:
		var pos := _ally.get_global_mouse_position()
		var tile := GameState.current_level.world_to_tile(pos)
		if tile in _movement_range.range_tiles:
			_tile_path = _astar.get_id_path(_ally.current_tile, tile)
	else:
		if Input.is_action_just_pressed("guard"):
			_ally.get_viewport().set_input_as_handled()
			_ally.facing = Vector2i.ZERO
			_ally.end_turn()
			return CharacterCombatIdleState.new()
		elif Input.is_action_just_pressed("cancel"):
			if not _attack_state == AttackState.BASIC:
				_attack_state = AttackState.BASIC
				_draw_ranges()
		if Input.is_action_just_pressed("special"):
			if not _attack_state == AttackState.SPECIAL:
				_attack_state = AttackState.SPECIAL
				_draw_ranges()
	
	_process_movement(delta)
	
	return _process_action()


func exit() -> void:
	GameState.current_level.reset_map()
