class_name Room
extends Area2D

@export
var neighbors: Array[Room]
@export
var transparent_walls: Array[TileMapLayer]

func _ready() -> void:
	hide()
	set_collision_mask_value(Global.PhysicsLayers.ALLY, true)
	set_collision_mask_value(Global.PhysicsLayers.ENVIRONMENT, false)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var walls: Array[Node] = find_children("*", "Wall")
	
	for wall: Wall in walls:
		wall.room = self

# TODO
func _on_body_entered(body: Node2D) -> void:
	show()
	EventBus.room_transitioned.emit(self, true)


func _on_body_exited(body: Node2D) -> void:
	if not has_overlapping_bodies():
		hide()
		EventBus.room_transitioned.emit(self, false)
