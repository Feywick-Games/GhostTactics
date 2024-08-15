class_name Skill
extends Resource

const DEFAULT_STICKER: Texture2D= preload("res://ui/sticker/_sprite/sticker_basic_attack.png")

@export
var name: String
@export
var sticker: Texture2D = DEFAULT_STICKER
@export
var character_animation: String
@export
var skill_animation: String
@export
var max_range: int = 1
@export
var min_range: int
@export
var range_shape: Combat.RangeShape = Combat.RangeShape.DIAMOND
@export
var state: GDScript
@export
var cool_down: int
@export
var status_effects: Array[StatusEffect]
@export
var aoe: Array[Vector2i] = [Vector2i.ZERO]
@export
var range_type: Combat.RangeType = Combat.RangeType.MELEE

var cool_down_status: int

func _init() -> void:
	resource_local_to_scene = true
	cool_down_status = cool_down


func is_ready() -> bool:
	return cool_down_status == cool_down
