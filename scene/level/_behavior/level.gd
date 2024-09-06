class_name Level
extends Node2D

const GRID_DRAW_TIME: float = 1

var map_complete: bool
var _encounter_started: bool
var _time_since_grid_tile: float = 0
var _current_cell_x: int = 0
var _time_per_grid_tile
var _reverse_build_grid := false

@onready
var _floor_layer: TileMapLayer = $Floor
@onready
var _prop_layer: TileMapLayer = $Props
@onready
var _improvised_weapon_layer: TileMapLayer = $ImprovisedWeapon

var grid: Grid

@onready
var combat_ui: CombatUI = $CombatUI
@onready
var map: TileMapLayer = $Map


func _ready() -> void:
	GameState.current_level = self
	EventBus.encounter_ended.connect(_on_encounter_ended)
	await get_tree().create_timer(2).timeout
	_on_encounter_started()
	EventBus.encounter_started.emit()


func _on_encounter_started() -> void:
	if not _encounter_started:
		map_complete = false
	_reverse_build_grid = false
	_populate_grid()
	_encounter_started = true
	_current_cell_x = grid.region.position.x
	_time_per_grid_tile =  GRID_DRAW_TIME/ grid.size.x
	map_complete = true


func _on_encounter_ended() -> void:
	_reverse_build_grid = true
	_current_cell_x = grid.region.end.x
	_encounter_started = false
	map_complete = false


func world_to_tile(world_position: Vector2) -> Vector2i:
	return map.local_to_map(map.to_local(world_position))


func tile_to_world(tile: Vector2i) -> Vector2:
	return map.to_global(map.map_to_local(tile))


func _process(delta: float) -> void:
	if (_encounter_started or _reverse_build_grid) and not map_complete:
		_time_since_grid_tile += delta
		
		if _time_since_grid_tile > _time_per_grid_tile:
			_time_since_grid_tile = 0
			if not _reverse_build_grid:
				for y in range(grid.region.position.y, grid.region.end.y):
					if not grid.is_point_solid(Vector2i(_current_cell_x,y)):
						if Vector2i(_current_cell_x,y) + Vector2i.UP in grid.cells:
							map.set_cell(Vector2i(_current_cell_x,y), 0, Vector2.RIGHT)
						else:
							map.set_cell(Vector2i(_current_cell_x,y), 0, Vector2i.ZERO)
				
				_current_cell_x +=  1
			
				if _current_cell_x == grid.region.end.x:
					map_complete = true
			else:
				for y in range(grid.region.position.y, grid.region.end.y):
					if Vector2i(_current_cell_x,y) in grid.cells:
						#if Vector2i(_current_cell_x,y) + Vector2i.UP in _grid_cells:
						map.set_cell(Vector2i(_current_cell_x,y))
				
				_current_cell_x -=  1
				
				if _current_cell_x == grid.region.position.x:
					_reverse_build_grid = false
					map_complete = true


func reset_map() -> void:
	for tile in grid.cells:
		map.set_cell(tile)

func draw_range(tiles: Array[Vector2i], atlas_coords: Vector2i) -> void:
	for tile in tiles:
		map.set_cell(tile, 0, atlas_coords)


func select_tile(tile: Vector2i, select := true) -> void:
	
	var atlas_coords: Vector2i = map.get_cell_atlas_coords(tile)
		
	if select:
		atlas_coords.x = 1
		map.set_cell(tile, 0, atlas_coords)
	else:
		atlas_coords.x = 0
		map.set_cell(tile, 0, atlas_coords)


func get_interactable_tiles(tiles: Array[Vector2i]) -> Array[Vector2i]:
	var interactable_tiles: Array[Vector2i]
	for tile in tiles:
		if _improvised_weapon_layer.get_cell_source_id(tile) != -1:
			interactable_tiles.append(tile)
	
	return interactable_tiles


func _populate_grid() -> void:
	grid = Grid.new(self)
	var o_rect: Rect2i = _floor_layer.get_used_rect()
	if grid.region.size.x + grid.region.size.y == 0:
		grid.update_region(o_rect)
	else:
		grid.update_region(grid.region.merge(o_rect))
	
	
	for y:int in range(o_rect.position.y, o_rect.end.y):
		for x:int in range(o_rect.position.x, o_rect.end.x):
			var tile := Vector2i(x,y)
			var source_id = _floor_layer.get_cell_source_id(tile)
			var prop_source_id = _prop_layer.get_cell_source_id(tile)
			var improv_weapon_source_id = _improvised_weapon_layer.get_cell_source_id(tile)
			if source_id == -1 or _floor_layer.get_cell_tile_data(tile).get_custom_data("border"):
				grid.lock_cell(tile)
			else:
				grid.add_cell(tile)
				if prop_source_id != -1 or improv_weapon_source_id != -1:
					var tile_data: TileData = _prop_layer.get_cell_tile_data(tile)
					if tile_data and tile_data.get_custom_data("impassable"):
						grid.lock_cell(tile)
					else:
						grid.add_prop(tile)
					

func get_interactable(tile: Vector2i) -> ImprovisedWeapon:
	var tile_data: TileData = _improvised_weapon_layer.get_cell_tile_data(tile)
	if tile_data:
		return tile_data.get_custom_data("improvised_weapon") as ImprovisedWeapon
	return


func take_interactable(tile: Vector2i) -> ImprovisedWeapon:
	var weapon: ImprovisedWeapon = get_interactable(tile)
	_improvised_weapon_layer.set_cell(tile, -1)
	grid.erase_prop(tile)
	return weapon


func get_subtile_position(world_position: Vector2) -> Vector2:
	var tile := world_to_tile(world_position)
	var tile_world_position := tile_to_world(tile)
	var offset: Vector2 = abs(tile_world_position - world_position) / Vector2(Global.TILE_SIZE)
	var out: Vector2
	out.x = fmod(offset.x, 1)
	out.y = fmod(offset.y, 1)
	return out
