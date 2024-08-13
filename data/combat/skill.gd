class_name Skill
extends Resource

const default_sticker: Texture2D= preload("res://ui/sticker/_sprite/sticker_basic_attack.png")

@export
var name: String
@export
var sticker: Texture2D = default_sticker
@export
var character_animation: String
@export
var skill_animation: String
@export
var max_range: int = 1
@export
var min_range: int
@export
var state: GDScript
@export
var cool_down: int = 3
@export
var status_effects: Array[StatusEffect]
var cool_down_status: int = 3


func is_ready() -> bool:
	return cool_down_status == cool_down
