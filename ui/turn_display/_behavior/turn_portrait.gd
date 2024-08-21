class_name TurnPortrait
extends Control

@onready
var _small_portrait: Sprite2D = $SmallPortrait
@onready
var _full_portrait: Sprite2D = $FullPortrait
@onready
var _animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	reset_portrait()


func display_full_portrait() -> void:
	_small_portrait.hide()
	_full_portrait.show()
	
	custom_minimum_size = Vector2(64,64)
	
	if "turn_start" in _animation_player.get_animation_list():
		_animation_player.play("turn_start")


func reset_portrait() -> void:
	_small_portrait.show()
	_full_portrait.hide()
	custom_minimum_size = Vector2(20,20)


func set_portrait_name(portrait_name: String) -> void:
	$FullPortrait/Label.text = portrait_name
