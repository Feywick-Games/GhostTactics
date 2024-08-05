extends Node

var follow_layout: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT * 2, Vector2i.LEFT * 2]
var current_level: Level
var battle_timer: BattleTimer
var ally_order: Array[Ally]

func add_to_ally_order(ally: Character, index: int) -> void:
	if index > len(ally_order):
		ally_order.append(ally)
	else:
		ally_order.insert(index, ally)
