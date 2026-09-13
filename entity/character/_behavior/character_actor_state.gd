class_name CharacterActorState
extends State

var _character: Character
var _tile_path: Array[Vector2i]
var _current_speed_modifier: float = 1 

signal moved

func enter() -> void:
	_character = state_machine.state_owner as Character
	_character.current_tile = GameState.current_level.grid.get_nearest_available_tile(_character.global_position)
	GameState.current_level.grid.update_unit_registry(_character.current_tile, _character)


func animate(anim: String, direction: Vector2i, wait := false) -> void:
	if not anim.begins_with("dialogue"):
		_character.animator.play_directional(anim, direction)
		_character.facing = direction
		if wait:
			await _character.animator.animation_finished


func emote(anim: String, wait := false) -> void:
	_character.play_dialogue(anim)
	if wait:
		await _character.spoke


func move(direction: Vector2i, speed_modifier: float = 1, wait := false) -> void:
	var to_tile : Vector2i = _character.current_tile + direction
	_current_speed_modifier = speed_modifier
	_tile_path = GameState.current_level.grid.get_character_path(_character.current_tile, to_tile)
	if wait:
		await moved


func wait_for_movement() -> void:
	if not _tile_path.is_empty():
		await moved


func physics_update(delta : float) -> State:
	if not _tile_path.is_empty():
		_tile_path = _character.process_movement(delta, _tile_path, "move", false, _current_speed_modifier)
		if _tile_path.is_empty():
			moved.emit()
			_character.animator.play_directional("move_idle", _character.facing)
	return
