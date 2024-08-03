class_name Level
extends Node2D

const GRID_DRAW_TIME: float = 1

@export
var neighbors: Array[int]

var grid := AStarGrid2D.new()
var grid_complete: bool
var _active_floor_layers: Array[TileMapLayer]
var _encounter_started: bool
var _grid_cells: Array[Vector2i]
var _time_since_grid_tile: float = 0
var _current_cell_x: int = 0
var _time_per_grid_tile

@onready
var map: TileMapLayer = $Map


func _ready() -> void:
	grid.region = Rect2i()
	grid.cell_shape = AStarGrid2D.CELL_SHAPE_ISOMETRIC_DOWN
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grid.cell_size = Global.TILE_SIZE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	GameState.current_level = self
	EventBus.build_battle_map.connect(_on_encounter_started)


func world_to_tile(world_position: Vector2) -> Vector2i:
	return map.local_to_map(map.to_local(world_position))


func tile_to_world(tile: Vector2i) -> Vector2:
	return map.to_global(map.map_to_local(tile))
	
	
func get_nearest_available_tile(world_position: Vector2) -> Vector2i:
	var tile := world_to_tile(world_position)
	
	if not grid.is_point_solid(tile):
		return tile
	else:
		var alternates : Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		alternates.shuffle()
		for dir: Vector2i in alternates:
			if not grid.is_point_solid(tile + dir):
				return tile + dir
	printerr("no available tile found at ", world_position)
	return tile


func _on_encounter_started(rooms: Array[Room]) -> void:
	grid.clear()
	grid_complete = false
	for room in rooms:
		_populate_grid(room)
	
	_encounter_started = true
	_current_cell_x = grid.region.position.x
	_time_per_grid_tile =  GRID_DRAW_TIME/ grid.size.x


func _process(delta: float) -> void:
	
	if _encounter_started and not grid_complete:
		_time_since_grid_tile += delta
		
		if _time_since_grid_tile > _time_per_grid_tile:
			_time_since_grid_tile = 0
			for y in range(grid.region.position.y, grid.region.end.y):
				if not grid.is_point_solid(Vector2i(_current_cell_x,y)):
					if Vector2i(_current_cell_x,y) + Vector2i.UP in _grid_cells:
						map.set_cell(Vector2i(_current_cell_x,y), 0, Vector2.RIGHT)
					else:
						map.set_cell(Vector2i(_current_cell_x,y), 0, Vector2i.ZERO)
			_current_cell_x +=  1
			
		if _current_cell_x == grid.region.end.x:
				grid_complete = true


func reset_map() -> void:
	for tile in _grid_cells:
		if tile + Vector2i.UP in _grid_cells:
			map.set_cell(tile, 0, Vector2.ZERO)
		else:
			map.set_cell(tile, 0 , Vector2.RIGHT)


func request_range(unit_tile: Vector2i, distance: float, can_pass := false) -> Array[Vector2i]:
	var range_rect: Rect2i
	range_rect.position = unit_tile - Vector2i(distance, distance)
	range_rect.end = unit_tile + Vector2i(distance, distance)
	
	var out_range: Array[Vector2i]
	
	
	for y in range(range_rect.position.y, range_rect.end.y + 1):
		for x in range(range_rect.position.x, range_rect.end.x + 1):
			var tile = Vector2i(x,y)
			if grid.region.has_point(tile) and not grid.is_point_solid(tile):
				if grid.get_point_path(unit_tile, tile).size() <= distance + 1:
					out_range.append(tile)
	
	return out_range


func draw_range(tiles: Array[Vector2i], atlas_coords: Vector2i) -> void:
	for tile in tiles:
		map.set_cell(tile, 0, atlas_coords)



func select_tile(tile: Vector2i, deselect := false) -> void:
	
	var atlas_coords: Vector2i = map.get_cell_atlas_coords(tile)
	if not deselect:
		map.set_cell(tile, 0, tile + Vector2i.RIGHT)
	else:
		map.set_cell(tile, 0, tile - Vector2i.RIGHT)


func _populate_grid(room: Room) -> void:
	
	var floor_layer: TileMapLayer = room.find_child("Floor")
	var props: Array[Node] = get_tree().get_nodes_in_group("prop")
	var o_rect: Rect2i = floor_layer.get_used_rect()
	if not floor_layer in _active_floor_layers:
		_active_floor_layers.append(floor_layer)
		if grid.region.size.x + grid.region.size.y == 0:
			grid.region = o_rect
		else:
			grid.region = grid.region.merge(o_rect)
		grid.update()
		print(grid.region)
		for y:int in range(o_rect.position.y, o_rect.end.y):
			for x:int in range(o_rect.position.x, o_rect.end.x):
				var source_id = floor_layer.get_cell_source_id(Vector2i(x,y))
				if source_id == -1 or floor_layer.get_cell_tile_data(Vector2i(x,y)).get_custom_data("border"):
					grid.set_point_solid(Vector2i(x,y))
					_grid_cells.append(Vector2i(x,y))
		for prop: Prop in props:
			var prop_tile: Vector2i = floor_layer.local_to_map(floor_layer.to_local(prop.global_position))
			for rect: Rect2i in prop.collision_rects:
				for y in range(rect.position.y, rect.end.y):
					for x: int in range(rect.position.x, rect.end.x):
						var tile := Vector2i(x,y) + prop_tile
						grid.set_point_solid(tile)
		grid.update()
