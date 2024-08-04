class_name Character
extends CharacterBody2D

@export
var init_state: GDScript
@export
var turn_state: GDScript
@export
var special_state: GDScript
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
