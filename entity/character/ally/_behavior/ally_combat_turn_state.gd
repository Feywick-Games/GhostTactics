class_name AllyCombatTurnState
extends State

const SNAP_DISTANCE: int = 2
const TIME_PER_MOVE: float = .025

var _ally: Ally
var _movement_range: Array[Vector2i]
var _attack_range: Array[Vector2i]
var _tile_path: Array[Vector2i]
var _time_since_move: float = 0
var _astar: AStarGrid2D

func enter() -> void:
	_ally = state_machine.state_owner as Ally
	
	_movement_range = GameState.current_level.request_range(_ally.current_tile, _ally.movement_range)
	
	for tile: Vector2i in _movement_range:
		if not tile + Vector2i.RIGHT in _movement_range or not tile + Vector2i.LEFT in _movement_range or\
		not tile + Vector2i.UP in _movement_range or not tile + Vector2i.DOWN in _movement_range:
			var valid_range : Array[Vector2i] = GameState.current_level.request_range(
				tile, _ally.attack_range, true
			)
			for attack_tile in valid_range:
				if not attack_tile in _attack_range and not attack_tile in _movement_range:
					_attack_range.append(attack_tile)
	
	_create_movement_astar()
	
	GameState.current_level.draw_range(_attack_range, Global.RETICLE_ATTACK_ALTAS_COORDS)
	GameState.current_level.draw_range(_movement_range, Global.RETICLE_MOVE_ALTAS_COORDS)


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
			if not Vector2i(x,y) in _movement_range:
				_astar.set_point_solid(Vector2i(x,y))


func update(delta: float) -> State:
	if Input.is_action_just_pressed("move"):
		var pos := _ally.to_global(_ally.get_local_mouse_position())
		var tile := GameState.current_level.world_to_tile(pos)
		if tile in _movement_range:
			_tile_path = _astar.get_id_path(_ally.current_tile, tile)
			_tile_path.pop_front()
			
	_ally.velocity = Vector2.ZERO
	if not _tile_path.is_empty():
		_time_since_move += delta
		if _time_since_move >= TIME_PER_MOVE:
			_time_since_move = 0
			var path_position :=  GameState.current_level.tile_to_world(_tile_path[0])
			if path_position.distance_to(_ally.global_position) > SNAP_DISTANCE:
				var dir: Vector2 = (path_position - _ally.global_position).normalized()
				_ally.global_position += dir * Global.PLAYER_SPEED * 4.0 * delta
				_ally.global_position = _ally.global_position.snapped(Vector2(2,1))
			if not path_position.distance_to(_ally.global_position) > SNAP_DISTANCE:
				_ally.global_position = path_position.round()
				_ally.current_tile = _tile_path.pop_front()
	return
