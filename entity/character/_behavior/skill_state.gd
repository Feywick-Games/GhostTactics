class_name SkillState
extends State

var _character: Character
var _target_tile: Vector2i
var _skill: Skill
var _unit_targets: Array[Character]
var _action_to_process: int = 1
var _exiting := false
var _desired_target_count: int

func _init(skill: Skill, target_tile: Vector2i) -> void:
	_target_tile = target_tile
	_skill = skill
	_desired_target_count = round(_skill.aoe.size() * .75)

func enter() -> void:
	_character = state_machine.state_owner as Character


func update(_delta: float) -> State:
	if _exiting:
		_character.end_turn()
		return CharacterCombatIdleState.new()
	return


func end_turn() -> void:
	_action_to_process -=1
	if _action_to_process == 0:
		_exiting = true
	

func exit() -> void:
	super.exit()
	_skill.cool_down_status = 0


func calc_skill_likelihood(attack_range: RangeStruct, strike_tile : Vector2i) -> float:
	for tile in attack_range.range_tiles:
		var target_count: int = 0
		var has_unit := false
		var direction := VectorF.snap_direction(Vector2(tile - strike_tile))
		var last_target_tile: Vector2i = Vector2i.UP
		for target_tile in _skill.aoe:
			target_tile = Vector2i(Vector2(target_tile).rotated(direction.angle()))
			if target_tile == last_target_tile:
				printerr("counted tile twice")
			
			var unit: Character = GameState.current_level.get_unit_from_tile(tile + target_tile)
			if unit != self and (unit is Ally) != (_character is Ally):
				target_count +=1
				if tile + target_tile == _target_tile:
					has_unit = true
				if target_count >= _desired_target_count and has_unit:
					return 1
			last_target_tile = target_tile
	return 0
