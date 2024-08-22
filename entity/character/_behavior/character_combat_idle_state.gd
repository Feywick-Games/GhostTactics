class_name CharacterCombatIdleState
extends State

var _character: Character
var _encounter_ended := false
var _turn_started := false

func enter() -> void:
	_character = state_machine.state_owner as Character
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.encounter_ended.connect(_on_encounter_ended)
	EventBus.tiles_highlighted.connect(_on_tiles_highlighted)
	if _character.is_animated:
		_character.animator.play_directional("combat_idle", Vector2.ZERO)


func _on_encounter_ended() -> void:
	_encounter_ended = true

func _on_turn_started(unit: Character) -> void:
	if unit == _character:
		_turn_started = true


func _on_tiles_highlighted(tiles: Array[Vector2i], status_effects: Array[StatusEffect], accuracy: int) -> void:
	if _character.current_tile in tiles:
		_character.health_bar.show()
		_character.hit_chance_label.show()
	elif _character.health_bar.visible:
		_character.health_bar.hide()
		_character.health_bar.value = _character.health
		_character.hit_chance_label.hide()
		return

	for effect: StatusEffect in status_effects:
		if effect.status == Combat.Status.HIT:
			_character.health_bar.value = _character.health - effect.value
	
	
	var hit_chance: int = int((float(accuracy) / float(_character.evasion)) * 100)
	_character.hit_chance_label.text = str(hit_chance) + "%" 
	
	var hit_chance_color: Color
	if hit_chance <= 50:
		hit_chance_color = Color.FIREBRICK
	elif hit_chance <= 75:
		hit_chance_color = Color.ORANGE_RED
	else:
		hit_chance_color = Color.WHITE
	
	_character.hit_chance_label.add_theme_color_override("font_color", hit_chance_color)


func update(_delta: float) -> State:
	if _encounter_ended:
		_character.end_encounter()
		return _character.init_state.new()
	elif _turn_started:
		return _character.turn_state.new()
	return


func exit() -> void:
	_character.health_bar.hide()
	_character.hit_chance_label.hide()
