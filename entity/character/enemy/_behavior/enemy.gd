class_name Enemy
extends Character

@export_category("AI Prioritization")
@export_range(0,1)
var damage_priortization: float
@export_range(0,1)
var kill_prioritization: float
@export_range(0,1)
var custom_priorization: float


func take_damage(damage: int, direction: Vector2, hit_chance: int, hit_signal: Signal, inflicted_status: Combat.Status) -> void:
	if GameState.battle_timer.value < GameState.battle_timer.max_value * .25:
		damage *= 2
	elif GameState.battle_timer.value > GameState.battle_timer.max_value * .75:
		damage *= .5
	super.take_damage(damage, direction, hit_chance, hit_signal, inflicted_status)
