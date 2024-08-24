class_name RangeStruct
extends RefCounted

var range_tiles: Array[Vector2i]
var blocked_tiles: Array[Vector2i]

func absorb(o_struct: RangeStruct) -> void:
	for valid: Vector2i in o_struct.range_tiles:
		if valid not in range_tiles:
			range_tiles.append(valid)
	for invalid: Vector2i in o_struct.blocked_tiles:
		if invalid not in blocked_tiles:
			blocked_tiles.append(invalid)
			
