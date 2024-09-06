class_name BasicSkillState
extends SkillState

var _direction: Vector2

func enter() -> void:
	super.enter()
	#TODO make directional animations
	_direction = VectorF.snap_direction(_target_tile - _character.current_tile)
	if _character.is_animated:
		_character.animator.play_directional(_skill.character_animation, _direction)
	
	if not _skill.skill_animation.is_empty():
		_character.skill_animator.play_directional(_skill.skill_animation, _direction)
	_hit_targets(_skill.aoe, _skill.range_type)


func _hit_targets(aoe: Array[Vector2i], range_type: Combat.RangeType) -> void:
	_action_to_process = 0
	for tile_offset in aoe:
		var tile: Vector2i
		var offset_rotated: = Vector2i(Vector2(tile_offset).rotated(_direction.angle()))
		if range_type == Combat.RangeType.MELEE:
			tile = _character.current_tile + Vector2i(_direction) + offset_rotated
		else:
			tile = _target_tile + offset_rotated
		var unit: Character = GameState.current_level.grid.get_unit_from_tile(tile)
		if unit:
			unit.action_processed.connect(end_turn)
			_action_to_process += 1
			unit.take_damage(_skill, _direction, _character.accuracy, _character.target_hit)
	if not _skill.is_animated:
		_character.notify_impact()
