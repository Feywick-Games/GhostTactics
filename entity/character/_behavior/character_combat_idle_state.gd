class_name CharacterCombatIdleState
extends State

var _character: Character
var _encounter_ended := false
var _turn_started := false
var _highlighted_tiles: Array[Vector2i]
var _highlighted_accuracy: int
var _highlighted_status_effects: Array[StatusEffect] 
var _highlighted_direction: Vector2i
var _highlighter_is_ally: bool
var _damage_taken := false

func enter() -> void:
	_character = state_machine.state_owner as Character
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.encounter_ended.connect(_on_encounter_ended)
	EventBus.tiles_highlighted.connect(_on_tiles_highlighted)
	_character.damage_taken.connect(_on_damage_taken)
	if _character.is_animated:
		_character.animator.play_directional("combat_idle", Vector2.ZERO)


func _on_encounter_ended() -> void:
	_encounter_ended = true

func _on_turn_started(unit: Character) -> void:
	if unit == _character:
		_turn_started = true
	_damage_taken = false
	if _character.health_bar.visible:
		_character.health_bar.hide()


func _on_damage_taken() -> void:
	_damage_taken = true


func _on_tiles_highlighted(tiles: Array[Vector2i], status_effects: Array[StatusEffect], 
accuracy: int, direction: Vector2i, is_ally: bool) -> void:
	_highlighted_tiles = tiles
	_highlighted_accuracy = accuracy
	_highlighted_status_effects = status_effects
	_highlighted_direction = direction
	_highlighter_is_ally = is_ally
	if not _character.current_tile in _highlighted_tiles and _character.health_bar.visible:
		_character.health_bar.hide()


func _display_health() -> void:
	if _character.current_tile in _highlighted_tiles:
		_character.health_bar.show()
		_character.hit_chance_label.show()
	if not _damage_taken:
		var multiplier: int = 1
		if _highlighter_is_ally:
			if GameState.battle_timer.value < GameState.battle_timer.max_value * .25:
				multiplier = 2.0
			elif GameState.battle_timer.value > GameState.battle_timer.max_value * .75:
				multiplier = .5
			
		if is_equal_approx(Vector2(_highlighted_direction).normalized().dot(Vector2(_character.facing).normalized()), -1) and _character.facing != Vector2i.ZERO:
			multiplier += .5
		for effect: StatusEffect in _highlighted_status_effects:
			if effect.status == Combat.Status.HIT:
				_character.health_bar.value = _character.health - (effect.value * multiplier)
		
		var hit_chance: int
		
		if Vector2(_character.facing).dot(Vector2(_highlighted_direction)) < 0.1:
			hit_chance = int((float(_highlighted_accuracy) / float(_character.evasion)) * 100)
		elif _character.facing != Vector2i.ZERO: 
			hit_chance = 100
		else:
			hit_chance = 0
		
		_character.hit_chance_label.text = str(hit_chance) + "%" 
		
		var hit_chance_color: Color
		if hit_chance <= 50:
			hit_chance_color = Color.FIREBRICK
		elif hit_chance <= 75:
			hit_chance_color = Color.ORANGE_RED
		else:
			hit_chance_color = Color.WHITE
		
		_character.hit_chance_label.add_theme_color_override("font_color", hit_chance_color)
	elif _character.hit_chance_label.visible or _character.damage_bar.value != _character.health_bar.value:
		_character.hit_chance_label.hide()
		_character.damage_bar.value = _character.health_bar.value

func update(_delta: float) -> State:
	if _encounter_ended:
		_character.end_encounter()
		return _character.init_state.new()
	elif _turn_started:
		return _character.turn_state.new()
	if not _highlighted_tiles.is_empty():
		_display_health()
		
	return


func exit() -> void:
	_character.health_bar.hide()
	_character.hit_chance_label.hide()
