class_name ReactionState
extends State

var _character: Character
var _reaction: Skill
var _target: Character
var _next_state: ReactionState
var _exiting := false


func _init(reaction: Skill, next_state: ReactionState, character: Character, target: Character) -> void:
	_reaction = reaction
	_next_state = next_state
	_character = character
	_target = target


func update(_delta: float) -> State:
	if not is_instance_valid(_target):
		return CharacterCombatIdleState.new()
	
	if _exiting:
		if _next_state:
			return _next_state
		else:
			return CharacterCombatIdleState.new()
	return


func can_use() -> bool:
	return false
