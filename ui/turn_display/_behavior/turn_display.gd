class_name TurnDisplay
extends BoxContainer

var _units: Array[Character]
var _current_unit_idx: int = -1
var _current_unit: Character:
	get:
		return _units[_current_unit_idx]
var _turn_portraits: Array[TurnPortrait]
var _battle_started := false
var _turn_pending := false

func _ready() -> void:
	EventBus.turn_ended.connect(_start_turn)
	EventBus.encounter_started.connect(_on_encounter_started)
	hide()


func _on_encounter_ended() -> void:
	hide()
	_battle_started = false
	for child in get_children():
		queue_free()
	_units.clear()
	_turn_pending = false
	EventBus.encounter_ended.emit()


func _start_turn() -> void:
	var enemies_remaining := false
	var allies_remaining := false
	for unit in _units:
		if unit is Enemy:
			enemies_remaining = true
			break
	
	for unit in _units:
		if unit is Ally:
			allies_remaining = true
			break
	
	if not enemies_remaining:
		_on_encounter_ended()
		return
	elif not allies_remaining:
		get_tree().reload_current_scene()
	
	
	_turn_portraits[_current_unit_idx].reset_portrait()
	move_child(_turn_portraits[_current_unit_idx], -1)
	if _current_unit_idx < len(_units) - 1:
		_current_unit_idx += 1
	else:
		_current_unit_idx = 0
	var turn_portait := _turn_portraits[_current_unit_idx]
	turn_portait.display_full_portrait()
	EventBus.cam_follow_requested.emit(_current_unit)
	_turn_pending = true


func _process(delta: float) -> void:
	if visible:
		if not _battle_started and not _units.is_empty() and GameState.current_level.grid_complete:
			var units_waiting := false
			for unit in _units:
				if not unit.ready_for_battle:
					units_waiting = true
					break
			if not units_waiting:
				_battle_started = true
				
			if _battle_started:
				_start_turn()
	if _turn_pending:
		if get_viewport().get_camera_2d().in_position:
			_turn_pending = false
			EventBus.turn_started.emit(_current_unit)


func _on_encounter_started(group: String) -> void:
	_turn_pending = false
	if not visible:
		show()
	
	_current_unit_idx = -1
	
	var combatants: Array = get_tree().get_nodes_in_group("ally")
	combatants.append_array(
		get_tree().get_nodes_in_group(group)
	)
	
	for unit: Character in combatants:
		_units.append(unit)
		unit.died.connect(_on_unit_died.bind(unit))
		var turn_portrait: TurnPortrait = unit.turn_portrait_scene.instantiate()
		_turn_portraits.append(turn_portrait)
		add_child(turn_portrait)
		

func _on_unit_died(unit: Character) -> void:
	if not _units.is_empty():
		var idx: int = _units.find(unit)
		_units.remove_at(idx)
		var child = _turn_portraits[idx]
		_turn_portraits.remove_at(idx)
		child.queue_free()
