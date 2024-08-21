class_name SkillState
extends State

var _character: Character
var _target_tile: Vector2i
var _skill: Skill
var _unit_targets: Array[Character]
var _action_to_process: int = 1
var _exiting := false

func _init(skill: Skill, target_tile: Vector2i) -> void:
	_target_tile = target_tile
	_skill = skill


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
