class_name SpecialState
extends State

var _target_tile: Vector2i
var _character: Character

func _init(target_tile: Vector2i) -> void:
	_target_tile = target_tile
	
func enter() -> void:
	_character = state_machine.state_owner as Character
