class_name EncounterArea
extends Area2D

@export
var group: String
@export
var rooms: Array[Room]

func _ready() -> void:
	body_entered.connect(_on_area_entered)
	set_collision_mask_value(Global.PhysicsLayers.ENVIRONMENT, false)
	set_collision_mask_value(Global.PhysicsLayers.ALLY, true)
	
	
func _on_area_entered(body: Node2D) -> void:
	EventBus.encounter_started.emit(group)
	EventBus.build_battle_map.emit(rooms)
	queue_free()
