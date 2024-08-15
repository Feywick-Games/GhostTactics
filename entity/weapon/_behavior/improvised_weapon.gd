class_name ImprovisedWeapon
extends Skill

const IMPROV_STICKER: Texture2D= preload("res://ui/sticker/_sprite/sticker_improv_weapon.png")
const IMPROV_THROW_STICKER: Texture2D = preload("res://ui/sticker/_sprite/sticker_improv_throw.png")

@export
var durability: int = 1
@export
var movement_penalty: int
@export
var max_throw_range: int = 4
@export
var throw_aoe: Array[Vector2i] = [Vector2i.ZERO]

var min_throw_range: int = 1
var throw_skill: Skill

func _init() -> void:
	if sticker == Skill.DEFAULT_STICKER:
		sticker = IMPROV_STICKER

func is_broken() -> bool:
	return durability <= 0
