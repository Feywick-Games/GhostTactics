class_name SpecialState
extends TurnState

var _target_tile: Vector2i

func _init(target_tile: Vector2i) -> void:
	_target_tile = target_tile

func exit() -> void:
	super.exit()
	_character.special.cool_down_status = 0
