class_name Enemy
extends Character

const DISTANCE_PRIORITY: float = .5

@export_category("AI Prioritization")
@export_range(0,1)
var damage_priority_min: float = 0.5
@export_range(0,1)
var damage_priority_max: float = 1
@export_range(0,1)
var knock_out_priority_min: float = 0.5
@export_range(0,1)
var knock_out_priority_max: float = 1
@export_range(0,1)
var safety_priority_min: float = 0.5
@export_range(0,1)
var safety_priority_max: float = 1
@export_range(0,1)
var special_priority_min: float = 0.5
@export_range(0,1)
var special_priority_max: float = 1
@export_range(0,1)
var custom_priority_min: float = 0
@export_range(0,1)
var custom_priority_max: float = 1


var damage_priority: float
var knock_out_priority: float
var safety_priority: float
var special_priority: float
var custom_priority: float


func _ready() -> void:
	super._ready()
	# initalize AI prioritzation
	damage_priority = damage_priority_min
	knock_out_priority = knock_out_priority_min
	safety_priority = safety_priority_min
	special_priority = special_priority_min
	custom_priority = custom_priority_min


func take_damage(skill: Skill, direction: Vector2, hit_chance: float, hit_signal: Signal, multiplier: float = 1) -> void:
	if GameState.battle_timer.value < GameState.battle_timer.max_value * .25:
		multiplier *= 2
	elif GameState.battle_timer.value > GameState.battle_timer.max_value * .75:
		multiplier *= .5
	super.take_damage(skill, direction, hit_chance, hit_signal, multiplier)
