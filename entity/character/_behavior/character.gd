class_name Character
extends CharacterBody2D

signal died
signal target_hit
signal action_processed

const SNAP_DISTANCE := 2.4
const TIME_PER_MOVE := .03
const HEALTH_BAR_PIXEL_WIDTH := 25

@export_category("Debug")
@export
var is_animated := false
@export_category("UI")
@export
var character_name: String
@export
var turn_portrait_scene: PackedScene

@export_category("Gameplay")
@export
var init_state: GDScript
@export
var turn_state: GDScript
@export
var special: Special
@export
var reactions: Array[Combat.Reaction]

@export_category("Unit Stats")
@export
var max_health: int = 10
@export
var movement_range: int = 5
@export
var attack_range: int = 1
@export
var minimum_attack_range: int = 0
@export
var attack_damage: int = 2
@export
var evasion: int = 4
@export
var accuracy: int = 4

var health: int
var facing: Vector2i
var ready_for_battle := false
var current_tile: Vector2i
var status: Combat.Status
var attack_state: Combat.AttackState

@onready
var sprite: Sprite2D = $CharacterSprite
@onready
var animator: DirectionalAnimator = $ActionAnimator

@onready
var _health_bar: TextureProgressBar = $CharacterSprite/HealthBar

func _ready() -> void:
	_health_bar.hide()
	
	var state_machine := StateMachine.new(self, init_state.new())
	add_child(state_machine)
	print(self.get_class())


func start_encounter() -> void:
	if special:
		special.cool_down_status = special.cool_down
	health = max_health
	_health_bar.show()
	_health_bar.max_value = max_health
	_health_bar.value = _health_bar.max_value
	_health_bar.step = float(_health_bar.max_value) / HEALTH_BAR_PIXEL_WIDTH


func end_encounter() -> void:
	_health_bar.hide()


func notify_impact() -> void:
	target_hit.emit()


func get_tile() -> Vector2i:
	return GameState.current_level.get_tile(global_position)


func is_hit(hit_chance: float) -> bool:
	return (float(hit_chance) / float(evasion)) > randf()


func take_damage(damage: int, direction: Vector2, hit_chance: int, hit_signal: Signal, inflicted_status: Combat.Status) -> void:
	await hit_signal
	var hit_connected: bool
	var damage_multiplier: float = 1
	
	if is_equal_approx(direction.normalized().dot(Vector2(facing).normalized()), -1) and facing != Vector2i.ZERO:
		hit_connected = true
		damage_multiplier += .5
	else:
		hit_connected = is_hit(hit_chance)
	
	
	if hit_connected:
		damage *= damage_multiplier
		health -= damage
		if health <= 0:
			died.emit()
			queue_free()
		print("attack hit " + name)
	else:
		print("attack missed " + name)
	status = status

	_health_bar.value = health
	action_processed.emit()


func start_turn() -> void:
	if special:
		special.cool_down_status = min(special.cool_down_status + 1, special.cool_down)
		
		if special.is_ready():
			# TODO notify ui
			pass


func end_turn() -> void:
	GameState.current_level.update_unit_registry(current_tile, self)
	EventBus.turn_ended.emit()
	

func process_action(tile: Vector2i, attack_range: RangeStruct, state: TurnState) -> State:
	var dir := Vector2(tile - current_tile).normalized()
	facing = Vector2i(dir)
	
	if is_animated:
		animator.play_directional("idle", dir)
	
	
	if tile in attack_range.range_tiles:
		var unit: Character = GameState.current_level.get_unit_from_tile(tile)
		if unit and unit != self:
			facing = Vector2i(Vector2(tile - current_tile).normalized().round())
			if attack_state == Combat.AttackState.BASIC:
				if name == "Izzy":
					animator.queue("idle_" + animator.get_current_direction(dir))
					animator.play("basic_attack_down")
				
				if not unit.action_processed.is_connected(state.end_turn):
					unit.action_processed.connect(state.end_turn)
				unit.take_damage(attack_damage, facing, accuracy, target_hit, Combat.Status.HIT)
				if name != "Izzy":
					notify_impact()
			else:
				EventBus.timer_stopped.emit()
				return special.state.new(unit.current_tile)
	return


func create_range_astar(range_struct: RangeStruct, manhattan_range: int) -> AStarGrid2D:
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(current_tile - Vector2i(manhattan_range, manhattan_range),  (Vector2i(manhattan_range, manhattan_range) * 2) + Vector2i.ONE)
	astar.cell_shape = AStarGrid2D.CELL_SHAPE_ISOMETRIC_DOWN
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.cell_size = Global.TILE_SIZE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	for y in range(astar.region.position.y, astar.region.end.y):
		for x in range(astar.region.position.x, astar.region.end.x):
			if not Vector2i(x,y) in range_struct.range_tiles:
				astar.set_point_solid(Vector2i(x,y))
	return astar


func draw_ranges(attack_range: RangeStruct, movement_range: RangeStruct, attack_atlas_coords: Vector2i, overlap_atlas_coords: Vector2i) -> void:
	# color tiles differently when attacks overlap with movement 
	var overlap_tiles: Array[Vector2i]
	var attack_only_tiles: Array[Vector2i]
	
	for tile in attack_range.range_tiles:
		if tile in movement_range.range_tiles:
			overlap_tiles.append(tile)
		else:
			attack_only_tiles.append(tile)
	
	GameState.current_level.reset_map()
	GameState.current_level.draw_range(movement_range.range_tiles, Global.RETICLE_MOVE_ALTAS_COORDS)
	GameState.current_level.draw_range(attack_range.blocked_tiles, Global.RETICLE_BLOCKED_ALTAS_COORDS)
	GameState.current_level.draw_range(movement_range.blocked_tiles, Global.RETICLE_BLOCKED_ALTAS_COORDS)
	GameState.current_level.draw_range(attack_only_tiles, attack_atlas_coords)
	GameState.current_level.draw_range(overlap_tiles, overlap_atlas_coords)
	GameState.current_level.map.set_cell(current_tile, 0, Global.RETICLE_MOVE_ALTAS_COORDS)
	GameState.current_level.select_tile(current_tile)


func process_movement(delta: float, tile_path: Array[Vector2i]) -> Array[Vector2i]:
	velocity = Vector2.ZERO
	if not tile_path.is_empty():
		var path_position :=  GameState.current_level.tile_to_world(tile_path[0])
		var map_position := GameState.current_level.tile_to_world(current_tile)
		if path_position.distance_to(global_position) > SNAP_DISTANCE:
			var dir: Vector2 = (path_position - global_position).normalized()
			global_position += dir * Global.PLAYER_SPEED * 4.0 * delta
			global_position = global_position.snapped(Vector2(2,1))
			if is_animated:
				var anim_dir := Vector2(tile_path[0] - current_tile).normalized()
				animator.play_directional("idle", anim_dir)
		if not path_position.distance_to(global_position) > SNAP_DISTANCE:
			if len(tile_path) == 1:
				global_position = path_position.round()
			tile_path.pop_front()
		if not tile_path.is_empty() and \
		path_position.distance_to(global_position) < map_position.distance_to(global_position):
			current_tile = tile_path[0]
				
	return tile_path
