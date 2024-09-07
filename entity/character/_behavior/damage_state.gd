class_name DamageState
extends CharacterCombatIdleState

var _skill: Skill
var _direction: Vector2
var _hit_chance: float
var _hit_signal: Signal
var _multiplier: float
var _request_reaction: bool
var _exiting := false
var _hit := false

func _init(skill: Skill, direction: Vector2, hit_chance: float, hit_signal: Signal, multiplier: float = 1, request_reaction:=true) -> void:
	_skill = skill
	_direction = direction
	_hit_chance = hit_chance
	_hit_signal = hit_signal
	_multiplier = multiplier
	_request_reaction = request_reaction
	_hit_signal.connect(_on_hit)


func enter() -> void:
	super.enter()
	_character.health_bar.show()
	_character.processing_action = true
	_character.reacting = false


func _on_hit() -> void:
	_hit = true


func _take_damage() -> void:
	var hit_connected: bool
	
	if _character is Enemy:
		if GameState.battle_timer.value < GameState.battle_timer.max_value * .25:
			_multiplier *= 2
		elif GameState.battle_timer.value > GameState.battle_timer.max_value * .75:
			_multiplier *= .5
	
	if is_equal_approx(_direction.normalized().dot(Vector2(_character.facing).normalized()), -1) and _character.facing != Vector2i.ZERO:
		hit_connected = true
		_multiplier += .5
	else:
		hit_connected = _character.is_hit(_hit_chance)
	

	if hit_connected:
		for effect: StatusEffect in _skill.status_effects:
			effect.multiplier = _multiplier
			_character.status.append(effect)
			_character.process_status_effect(effect)
			_character.status_label_manager.add_status_effect(effect)
	else:
		_character.status_label_manager.add_status_effect(null)
	
	_character.health_bar.value = _character.health
	_character.damage_bar.value = _character.health_bar.value
	_damage_taken = true
	
	_character.status_label_manager.display_statuses()
	await _character.status_label_manager.statuses_displayed
	
	_character.health_bar.hide()
	_character.processing_action = false
	if _character.health <= 0:
		_character.died.emit()
		_character.queue_free()
	elif _request_reaction:
		EventBus.reaction_requested.emit(_character)
	_exiting = true


func update(delta: float) -> State:
	var parent_state: State = super.update(delta)
	if parent_state:
		return parent_state
	
	if _hit and not _damage_taken:
		_take_damage()
		_hit = false
	if _exiting and not _character.reacting:
		return CharacterCombatIdleState.new()
	return super.update(delta)
