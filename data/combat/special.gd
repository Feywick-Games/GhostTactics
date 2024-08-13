class_name Special
extends Resource

@export
var name: String
@export
var sticker: Texture2D
@export
var range: int
@export
var min_range: int
@export
var state: GDScript
@export
var cool_down: int = 3
@export
var statuses: Array[Combat.Status]
@export
var status_values: Array[int]

var cool_down_status: int = 3


func is_ready() -> bool:
	return cool_down_status == cool_down
