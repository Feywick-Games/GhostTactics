class_name Character
extends CharacterBody2D

@export
var init_state: GDScript

@onready
var sprite: Sprite2D = $CharacterSprite
@onready
var animator: DirectionalAnimator = $ActionAnimator


func _ready() -> void:
	var state_machine := StateMachine.new(self, init_state.new())
	add_child(state_machine)



func get_tile() -> Vector2i:
	return GameState.current_level.get_tile(global_position)
