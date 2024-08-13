class_name BasicSkillState
extends SkillState

var _direction: Vector2

func enter() -> void:
	super.enter()
	#TODO make directional animations
	_direction = Vector2(_target_tile - _character.current_tile).normalized()
	if _character.is_animated:
		_character.animator.play_directional(_skill.character_animation, _direction)
	
	if not _skill.skill_animation.is_empty():
		_character.skill_animator.play_directional(_skill.skill_animation, _direction)
	
	var unit: Character = GameState.current_level.get_unit_from_tile(_target_tile)
	
	unit.action_processed.connect(end_turn)
	
	unit.take_damage(_skill, _character.facing, _character.accuracy, _character.target_hit)
	_character.notify_impact()
