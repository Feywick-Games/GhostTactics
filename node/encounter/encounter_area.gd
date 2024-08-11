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
	EventBus.build_battle_map.emit(rooms)
	EventBus.encounter_started.emit()
	queue_free()
