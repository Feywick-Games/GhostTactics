extends Node

var follow_layout: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT * 2, Vector2i.LEFT * 2]
var current_level: Level
var battle_timer: BattleTimer
var ally_order: Array[Ally]

func add_to_ally_order(ally: Character, index: int) -> void:
	if not ally in ally_order:
		if index > len(ally_order):
			ally_order.append(ally)
		else:
			ally_order.insert(index, ally)
		ally.died.connect(_on_ally_died.bind(ally))


func _on_ally_died(ally: Ally) -> void:
	ally_order.erase(ally)
	
	for i in range(len(ally_order)):
		ally_order[i].follow_order = i
