class_name ImprovisedWeaponThrowState
extends ImprovisedWeaponState

func enter() -> void:
	_character = state_machine.state_owner as Character
	_direction = VectorF.snap_direction(_target_tile - _character.current_tile)
	if _character.is_animated:
		_character.animator.play_directional("idle", _direction)
	
	var unit: Character = GameState.current_level.get_unit_from_tile(_target_tile)
	if not unit is Ally:
		_hit_targets(_improvised_weapon.throw_aoe, Combat.RangeType.RANGED)
	else:
		pass


func exit() -> void:
	super.exit()
	_character.drop_weapon()
