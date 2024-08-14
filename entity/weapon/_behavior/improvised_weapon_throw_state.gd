class_name ImprovisedWeaponThrowState
extends ImprovisedWeaponState

func exit() -> void:
	super.exit()
	_character.drop_weapon()
