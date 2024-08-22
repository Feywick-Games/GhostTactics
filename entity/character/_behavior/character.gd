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
var basic_skill: Skill
@export
var special: Skill
@export
var reactions: Array[Skill]

@export_category("Unit Stats")
@export
var max_health: int = 20
@export
var _movement_range: int = 5
var _movement_modifier: int
var movement_range: int:
	get:
		return _movement_range + _movement_modifier

@export
var _evasion: int = 4
var _evasion_modifier: int
var evasion: int:
	get:
		return _evasion + _evasion_modifier
@export
var _accuracy: int = 4
var _accuracy_modifer: int
var accuracy: int:
	get:
		return _accuracy + _accuracy_modifer
		


var health: int
var facing: Vector2i
var ready_for_battle := false
var current_tile: Vector2i
var status: Array[StatusEffect]
var attack_state: Combat.AttackState
var improvised_weapon: ImprovisedWeapon

@onready
var sprite: Sprite2D = $CharacterSprite
@onready
var animator: DirectionalAnimator = $ActionAnimator
@onready
var skill_animator: DirectionalAnimator = $SkillAnimator

@onready
var health_bar: TextureProgressBar = $CharacterSprite/HealthBar
@onready
var hit_chance_label: Label = $CharacterSprite/HealthBar/HitChanceLabel
@onready
var damage_bar: TextureProgressBar = $CharacterSprite/HealthBar/DamageBar

func _ready() -> void:
	health_bar.hide()
	EventBus.display_requested.connect(_on_display_requested)
	var state_machine := StateMachine.new(self, init_state.new())
	add_child(state_machine)
	print(self.get_class())


func start_encounter() -> void:
	if special:
		special.cool_down_status = special.cool_down
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health_bar.max_value
	health_bar.step = float(health_bar.max_value) / HEALTH_BAR_PIXEL_WIDTH
	damage_bar.value = health
	damage_bar.max_value = max_health
	damage_bar.step = float(health_bar.max_value) / HEALTH_BAR_PIXEL_WIDTH


func end_encounter() -> void:
	pass


func notify_impact() -> void:
	target_hit.emit()


func _on_display_requested(show_display: bool) -> void:
	if show_display:
		health_bar.show()
	else:
		health_bar.hide()


func is_hit(hit_chance: float) -> bool:
	return (float(hit_chance) / float(evasion)) > randf()


func drop_weapon() -> void:
	attack_state = Combat.AttackState.BASIC
	improvised_weapon = null
	#TODO play drop animation on skill animator


func take_damage(skill: Skill, direction: Vector2, hit_chance: float, hit_signal: Signal, multiplier: float = 1) -> void:
	health_bar.show()
	await hit_signal
	var hit_connected: bool
	
	if is_equal_approx(direction.normalized().dot(Vector2(facing).normalized()), -1) and facing != Vector2i.ZERO:
		hit_connected = true
		multiplier += .5
	else:
		hit_connected = is_hit(hit_chance)
	

	if hit_connected:
		for effect: StatusEffect in skill.status_effects:
			effect.multiplier = multiplier
			status.append(effect)
			_process_status_effect(effect)
	
		if health <= 0:
			died.emit()
			queue_free()
		print("attack hit " + name)
	else:
		print("attack missed " + name)
	status = status

	health_bar.value = health
	damage_bar.value = health
	await get_tree().create_timer(2).timeout
	health_bar.hide()
	action_processed.emit()


func _process_status_effect(effect: StatusEffect) -> void:
	if effect.status == Combat.Status.HIT:
		health -= effect.value * effect.multiplier
	elif effect.status == Combat.Status.SLOWED:
		_movement_modifier += effect.value * effect.multiplier
	elif effect.status == Combat.Status.DAZED:
		_accuracy_modifer += effect.value * effect.multiplier


func start_turn() -> void:
	basic_skill.cool_down_status = min(basic_skill.cool_down_status + 1, basic_skill.cool_down)
	
	if special:
		special.cool_down_status = min(special.cool_down_status + 1, special.cool_down)

	health_bar.value = health
	health_bar.show()
	
	for effect: StatusEffect in status:
		effect.duration


func end_turn() -> void:
	GameState.current_level.update_unit_registry(current_tile, self)
	EventBus.turn_ended.emit.call_deferred()
	
	health_bar.hide()
	
	for effect: StatusEffect in status:
		effect.duration -= 1
	
	status = status.filter(func(x: StatusEffect): return x.duration > 0)
	
	for effect: StatusEffect in status:
		_process_status_effect(effect)
	
	EventBus.tiles_highlighted.emit([] as Array[Vector2i], [] as Array[StatusEffect], 0)


func process_action(tile: Vector2i, attack_range: RangeStruct, state: TurnState) -> State:
	var dir := Vector2(tile - current_tile).normalized()
	facing = Vector2i(dir)
	
	if is_animated:
		animator.play_directional("idle", dir)
	
	
	if tile in attack_range.range_tiles:
		var unit: Character = GameState.current_level.get_unit_from_tile(tile)
		if unit != self:
			facing = Vector2i(Vector2(tile - current_tile).normalized().round())
			EventBus.timer_stopped.emit()
			if attack_state == Combat.AttackState.BASIC:
				return basic_skill.state.new(basic_skill, tile)
			elif attack_state == Combat.AttackState.SPECIAL:
				return special.state.new(special, tile)
			elif attack_state == Combat.AttackState.IMPROV:
				return improvised_weapon.state.new(improvised_weapon, tile)
			elif attack_state == Combat.AttackState.IMPROV_THROW:
				return ImprovisedWeaponThrowState.new(improvised_weapon, tile)
	elif GameState.current_level.get_interactable(tile):
		improvised_weapon = GameState.current_level.take_interactable(tile)
		attack_state = Combat.AttackState.IMPROV
		state.interacted = true
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


func update_ranges(movement_range: RangeStruct, interactable_range: Array[Vector2i]) -> RangeStruct:
	# color tiles differently when attacks overlap with movement 
	var skill_range: RangeStruct
	var attack_atlas_coords: Vector2i
	var overlap_atlas_coords: Vector2i
	var is_ally: bool = self is Ally
	
	if attack_state == Combat.AttackState.BASIC:
		skill_range = GameState.current_level.request_range(current_tile, basic_skill.min_range, basic_skill.max_range, basic_skill.range_shape, is_ally, true, true)
		attack_atlas_coords = Global.RETICLE_ATTACK_ALTAS_COORDS
		overlap_atlas_coords = Global.RETICLE_SPECIAL_2_ATLAS_COORDS
	elif attack_state == Combat.AttackState.SPECIAL:
		skill_range = GameState.current_level.request_range(current_tile, special.min_range, special.max_range, special.range_shape, is_ally, true, true)
		attack_atlas_coords = Global.RETICLE_SPECIAL_1_ALTAS_COORDS
		overlap_atlas_coords = Global.RETICLE_CURE_1_ATLAS_COORDS
	elif attack_state == Combat.AttackState.IMPROV:
		skill_range = GameState.current_level.request_range(current_tile, improvised_weapon.min_range, improvised_weapon.max_range, improvised_weapon.range_shape, is_ally, true, true)
		attack_atlas_coords = Global.RETICLE_ATTACK_ALTAS_COORDS
		overlap_atlas_coords = Global.RETICLE_SPECIAL_2_ATLAS_COORDS
	elif attack_state == Combat.AttackState.IMPROV_THROW:
		skill_range = GameState.current_level.request_range(current_tile, improvised_weapon.min_throw_range, improvised_weapon.max_throw_range, Combat.RangeShape.DIAMOND, is_ally, true, true)
		attack_atlas_coords = Global.RETICLE_SPECIAL_1_ALTAS_COORDS
		overlap_atlas_coords = Global.RETICLE_CURE_1_ATLAS_COORDS
	
	var overlap_tiles: Array[Vector2i]
	var attack_only_tiles: Array[Vector2i]
	
	for tile in skill_range.range_tiles:
		if tile in movement_range.range_tiles:
			overlap_tiles.append(tile)
		else:
			attack_only_tiles.append(tile)
	
	GameState.current_level.reset_map()
	GameState.current_level.draw_range(movement_range.range_tiles, Global.RETICLE_MOVE_ALTAS_COORDS)
	GameState.current_level.draw_range(skill_range.blocked_tiles, Global.RETICLE_BLOCKED_ALTAS_COORDS)
	GameState.current_level.draw_range(movement_range.blocked_tiles, Global.RETICLE_BLOCKED_ALTAS_COORDS)
	GameState.current_level.draw_range(attack_only_tiles, attack_atlas_coords)
	GameState.current_level.draw_range(overlap_tiles, overlap_atlas_coords)
	GameState.current_level.draw_range(interactable_range, Global.RETICLE_INTERACTABLE_ATLAS_COORDS)
	GameState.current_level.map.set_cell(current_tile, 0, Global.RETICLE_MOVE_ALTAS_COORDS)
	GameState.current_level.select_tile(current_tile)
	
	return skill_range


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
			GameState.current_level.update_unit_registry(current_tile, self)
	return tile_path
