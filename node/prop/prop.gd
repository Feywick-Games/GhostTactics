class_name Prop
extends StaticBody2D

@export
var collision_rects: Array[Rect2i]

func _ready() -> void:
	add_to_group("prop")
