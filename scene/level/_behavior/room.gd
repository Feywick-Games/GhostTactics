class_name Room
extends Area2D

@export
var neighbors: Array[Room]
@export
var transparent_walls: Array[TileMapLayer]

@onready
var floor_layer: TileMapLayer = $Floor
@onready
var prop_layer: TileMapLayer = $Props

func _ready() -> void:
	set_collision_mask_value(Global.PhysicsLayers.ALLY, true)
	set_collision_mask_value(Global.PhysicsLayers.ENVIRONMENT, false)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# TODO
func _on_body_entered(body: Node2D) -> void:
	EventBus.room_transitioned.emit(self, true)


func _on_body_exited(body: Node2D) -> void:
	if not has_overlapping_bodies():
		hide()
		EventBus.room_transitioned.emit(self, false)
