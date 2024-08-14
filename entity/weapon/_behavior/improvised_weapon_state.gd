class_name ImprovisedWeaponState
extends BasicSkillState

var _improvised_weapon: ImprovisedWeapon

func enter() -> void:
	super.enter()
	_improvised_weapon = _skill as ImprovisedWeapon


func exit() -> void:
	super.exit()
	_improvised_weapon.durability -= 1
	
	if _improvised_weapon.is_broken():
		_character.drop_weapon() 
