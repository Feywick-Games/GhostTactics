class_name Enemy
extends Character

@export_category("AI Prioritization")
@export_range(0,1)
var damage_priortization: float
@export_range(0,1)
var kill_prioritization: float
@export_range(0,1)
var custom_priorization: float


func take_damage(skill: Skill, direction: Vector2, hit_chance: float, hit_signal: Signal, multiplier: float = 1) -> void:
	if GameState.battle_timer.value < GameState.battle_timer.max_value * .25:
		multiplier *= 2
	elif GameState.battle_timer.value > GameState.battle_timer.max_value * .75:
		multiplier *= .5
	super.take_damage(skill, direction, hit_chance, hit_signal, multiplier)
