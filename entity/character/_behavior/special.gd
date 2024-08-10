class_name Special
extends Resource

@export
var sticker: Texture2D
@export
var damage: int
@export
var range: int
@export
var min_range: int
@export
var state: GDScript
@export
var cool_down: int = 3
@export
var custom_values: Dictionary

var cool_down_status: int = 3


func is_ready() -> bool:
	return cool_down_status == cool_down
