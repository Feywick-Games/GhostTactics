class_name Level
extends Node2D


@export
var neighbors: Array[int]

var grid := AStarGrid2D.new()

@onready
var map: TileMap = $MapReference

func _ready() -> void:
	grid.region = Rect2i()
	grid.update()
	GameState.current_level = self
	EventBus.room_transitioned.connect(_populate_grid)


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


func _populate_grid(room: Room, loaded: bool) -> void:
	
	var floor_layer: TileMapLayer = room.find_child("Floor")
	var props: Array[Node] = get_tree().get_nodes_in_group("prop")
	var o_rect: Rect2i = floor_layer.get_used_rect()

	if loaded:
		grid.region = grid.region.merge(o_rect)
		grid.update()
		
		for y:int in range(o_rect.position.y, o_rect.end.y):
			for x:int in range(o_rect.position.x, o_rect.end.x):
				if floor_layer.get_cell_source_id(Vector2i(x,y)) == -1:
					grid.set_point_solid(Vector2i(x,y))
				else:
					if grid.is_point_solid(Vector2i(x,y)):
						grid.set_point_solid(Vector2i(x,y), false)
		
		for prop: Prop in props:
			var prop_tile: Vector2i = floor_layer.local_to_map(floor_layer.to_local(prop.global_position))
			for rect: Rect2i in prop.collision_rects:
				for y in range(rect.position.y, rect.end.y):
					for x: int in range(rect.position.x, rect.end.x):
						var tile := Vector2i(x,y) + prop_tile
						grid.set_point_solid(tile)
	else:
		for y:int in range(o_rect.position.y, o_rect.end.y):
			for x:int in range(o_rect.position.x, o_rect.end.x):
				grid.set_point_solid(Vector2i(x,y))
				
	grid.update()
