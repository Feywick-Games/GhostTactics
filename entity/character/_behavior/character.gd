class_name Character
extends CharacterBody2D

signal died

@export
var is_animated := false
@export
var init_state: GDScript
@export
var turn_state: GDScript
@export
var special: Special
@export
var turn_portrait_scene: PackedScene

@export
var health: int = 10
@export
var movement_range: int = 5
@export
var attack_range: int = 1
@export
var attack_damage: int = 2

var facing: Vector2i
var ready_for_battle := false
var current_tile: Vector2i

@onready
var sprite: Sprite2D = $CharacterSprite
@onready
var animator: DirectionalAnimator = $ActionAnimator


func _ready() -> void:
	var state_machine := StateMachine.new(self, init_state.new())
	add_child(state_machine)



func get_tile() -> Vector2i:
	return GameState.current_level.get_tile(global_position)


func take_damage(damage: int, direction: Vector2) -> void:
	var damage_multiplier: int = 1
	if facing != Vector2i.ZERO:
		if is_equal_approx(direction.normalized().dot(Vector2(facing).normalized()), -1):
			damage_multiplier += 2
	
	if GameState.battle_timer.value < GameState.battle_timer.max_value * .25:
		damage_multiplier += 2
	elif GameState.battle_timer.value > GameState.battle_timer.max_value * .75:
		damage_multiplier += -.5
	
	damage *= damage_multiplier
	
	health -= damage
	if health <= 0:
		died.emit()
		queue_free()


func end_turn() -> void:
	GameState.current_level.update_unit_registry(current_tile, self)
	EventBus.turn_ended.emit()
	
	
