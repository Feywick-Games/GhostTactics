class_name MaskArea
extends Area2D

func _ready() -> void:
	set_collision_mask_value(Global.PhysicsLayers.ENVIRONMENT, false)
	set_collision_mask_value(Global.PhysicsLayers.ALLY, true)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	EventBus.room_transitioned.connect(_on_room_transitioned)

func _on_room_transitioned(room: Room, loaded: bool) -> void:
	if not room == self:
		if has_overlapping_bodies():
			_on_body_entered(null)


func _on_body_entered(_body: PhysicsBody2D) -> void:
	var children: Array[Node] = find_children("*", "Wall")
	
	var tween: Tween = get_tree().create_tween()
	
	for child: Wall in children:
		if child.sibling and child.sibling.room.visible:
			child.hide()
			tween.tween_property(child.sibling, "modulate", Color(1,1,1, child.sibling.wall_transaparency_value), child.sibling.modulate.a * .5)
		elif child.modulate.a > child.wall_transaparency_value:
			child.show()

			if child.sibling:
				child.modulate = child.sibling.modulate

			tween.tween_property(child, "modulate", Color(1,1,1,child.wall_transaparency_value), child.modulate.a * .5)
		else:
			child.show()
			tween.kill()


func _on_body_exited(_body: PhysicsBody2D) -> void:
	if not has_overlapping_bodies():
		var children: Array[Node] = find_children("*", "Wall")
		
		var tween: Tween = get_tree().create_tween()
		
		for child: Wall in children:
			if not child.sibling or not child.sibling.visible:
				if child is Wall:
					child.show()
					tween.tween_property(child, "modulate", Color.WHITE, child.modulate.a * .5)
					if child.sibling:
						child.sibling.modulate.a = 1
						child.sibling.show()
