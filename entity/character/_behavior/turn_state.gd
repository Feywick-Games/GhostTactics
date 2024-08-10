class_name TurnState
extends State

var _character: Character
var _movement_range: RangeStruct
var _attack_range: RangeStruct = RangeStruct.new()
var _tile_path: Array[Vector2i]
var _time_since_move: float = 0
var _astar: AStarGrid2D
var _start_tile: Vector2i
var _attack_state: Character.AttackState
var _exiting := false
var _encounter_ended := false


func enter() -> void:
	_character = state_machine.state_owner as Character
	_character.start_turn()
	EventBus.encounter_ended.connect(_on_encounter_ended)


func end_turn() -> void:
	_exiting = true
	
	
func exit() -> void:
	GameState.current_level.reset_map()
	
	
func _on_encounter_ended() -> void:
	_encounter_ended = true
