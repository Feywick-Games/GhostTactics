class_name AllyCombatTurnState
extends State

const SNAP_DISTANCE: int = 2.4
const TIME_PER_MOVE: float = .03

var _ally: Ally
var _movement_range: RangeStruct
var _attack_range: RangeStruct = RangeStruct.new()
var _tile_path: Array[Vector2i]
var _time_since_move: float = 0
var _astar: AStarGrid2D
var _selecting_facing := false
var _start_tile: Vector2i

func enter() -> void:
	_ally = state_machine.state_owner as Ally
	_ally.global_position = GameState.current_level.tile_to_world(_ally.current_tile).round()
	_start_tile = _ally.current_tile
	_movement_range = GameState.current_level.request_range(_ally.current_tile, _ally.movement_range, true, [_start_tile])
	
	_create_movement_astar()
	_draw_ranges()
	
	
func _draw_ranges() -> void:
	#GameState.current_level.draw_range(_attack_range.range_tiles, Global.BATTLE_MAP_ATLAS_COORDS)
	#GameState.current_level.draw_range(_attack_range.blocked_tiles, Global.BATTLE_MAP_ATLAS_COORDS)
	GameState.current_level.reset_map()
	_attack_range = GameState.current_level.request_range(_ally.current_tile, _ally.attack_range, true, [_start_tile], true, true)
	GameState.current_level.draw_range(_movement_range.range_tiles, Global.RETICLE_MOVE_ALTAS_COORDS)
	GameState.current_level.draw_range(_attack_range.blocked_tiles, Global.RETICLE_BLOCKED_ALTAS_COORDS)
	GameState.current_level.draw_range(_movement_range.blocked_tiles, Global.RETICLE_BLOCKED_ALTAS_COORDS)
	GameState.current_level.draw_range(_attack_range.range_tiles, Global.RETICLE_ATTACK_ALTAS_COORDS)
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


func update(delta: float) -> State:
	if Input.is_action_just_pressed("move"):
		var pos := _ally.to_global(_ally.get_local_mouse_position())
		var tile := GameState.current_level.world_to_tile(pos)
		if tile in _movement_range.range_tiles:
			_tile_path = _astar.get_id_path(_ally.current_tile, tile)
			#_tile_path.pop_front()
			
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
			if not path_position.distance_to(_ally.global_position) > SNAP_DISTANCE:
				if len(_tile_path) == 1:
					_ally.global_position = path_position.round()
				_tile_path.pop_front()
			if not _tile_path.is_empty() and \
			path_position.distance_to(_ally.global_position) < map_position.distance_to(_ally.global_position):
				_ally.current_tile = _tile_path[0]
				_draw_ranges()
				
				
	if Input.is_action_just_pressed("guard"):
		_ally.get_viewport().set_input_as_handled()
		_ally.facing = Vector2i.ZERO
		return CharacterCombatIdleState.new()
	return

func set_attack_range() -> void:
	pass



func exit() -> void:
	EventBus.turn_ended.emit()
	GameState.current_level.reset_map()
	GameState.current_level.update_unit_registry(_ally.current_tile, _ally)
