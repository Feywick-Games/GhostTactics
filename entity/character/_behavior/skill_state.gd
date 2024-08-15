class_name SkillState
extends TurnState

var _target_tile: Vector2i
var _skill: Skill
var _unit_targets: Array[Character]

func _init(skill: Skill, target_tile: Vector2i) -> void:
	_target_tile = target_tile
	_skill = skill


func exit() -> void:
	super.exit()
	_skill.cool_down_status = 0
