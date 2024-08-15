class_name TurnState
extends State

var interacted := false
var acted := false

var _character: Character
var _starting_movement_range: RangeStruct
var _movement_range: RangeStruct
var _attack_range: RangeStruct = RangeStruct.new()
var _interactable_range: Array[Vector2i]
var _tile_path: Array[Vector2i]
var _time_since_move: float = 0
var _astar: AStarGrid2D
var _start_tile: Vector2i
var _exiting := false
var _encounter_ended := false
var _action_to_process: int = 1
var _highlighted_tile: Vector2i

func enter() -> void:
	_character = state_machine.state_owner as Character
	_character.start_turn()
	EventBus.encounter_ended.connect(_on_encounter_ended)

func update(_delta: float) -> State:
	if _encounter_ended:
		return _character.init_state.new()
	elif _exiting:
		_character.end_turn()
		if not _encounter_ended:
			return CharacterCombatIdleState.new()
	return


func end_turn() -> void:
	_action_to_process -=1
	if _action_to_process == 0:
		_exiting = true
	
func exit() -> void:
	GameState.current_level.reset_map()
	
	
func _on_encounter_ended() -> void:
	_encounter_ended = true
	_character.end_encounter()
	
	
	
func _highlight_targets(target_tile: Vector2i, highlight := true) -> void:
	var direction: Vector2 = VectorF.snap_direction(target_tile - _character.current_tile)
	var aoe: Array[Vector2i]
	var range_type: Combat.RangeType
	
	var highlighted_tiles: Array[Vector2i]
	GameState.current_level.reset_map()
	var temp_range := _character.update_ranges(_movement_range, _interactable_range)
	var status_effects: Array[StatusEffect]
	
	if not GameState.current_level.get_interactable(target_tile):
		if _character.attack_state == Combat.AttackState.BASIC:
			aoe = _character.basic_skill.aoe
			range_type = _character.basic_skill.range_type
			status_effects = _character.basic_skill.status_effects
		elif _character.attack_state == Combat.AttackState.SPECIAL:
			aoe = _character.special.aoe
			range_type = _character.special.range_type
			status_effects = _character.special.status_effects
		elif _character.attack_state == Combat.AttackState.IMPROV:
			aoe = _character.improvised_weapon.aoe
			range_type = _character.improvised_weapon.range_type
			status_effects = _character.improvised_weapon.status_effects
		elif _character.attack_state == Combat.AttackState.IMPROV_THROW:
			aoe = _character.improvised_weapon.throw_aoe
			range_type = Combat.RangeType.RANGED
			status_effects = _character.improvised_weapon.status_effects

		
		for tile_offset in aoe:
			var tile: Vector2i
			var offset_rotated: = Vector2i(Vector2(tile_offset).rotated(direction.angle()))
			if range_type == Combat.RangeType.MELEE:
				tile = _character.current_tile + Vector2i(direction) + offset_rotated
			else:
				tile = target_tile + offset_rotated
			
			highlighted_tiles.append(tile)
			
			if tile in _attack_range.range_tiles:
				GameState.current_level.select_tile(tile, highlight)
			else:
				if highlight:
					var is_floor := GameState.current_level.map.get_cell_source_id(tile) != -1
					
					if not is_floor:
						continue
					
					var atlas_coords := GameState.current_level.map.get_cell_atlas_coords(target_tile)
					atlas_coords.x = 1
					GameState.current_level.map.set_cell(tile, 0, atlas_coords)
	else:
		GameState.current_level.select_tile(target_tile, highlight)

	if highlight:
		EventBus.tiles_highlighted.emit(highlighted_tiles, status_effects, _character.accuracy)
