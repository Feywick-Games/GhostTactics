extends Node

signal encounter_started()
signal encounter_ended
signal room_transitioned(room: Room, loaded: bool)
signal cam_follow_requested(leader: Node2D)
signal build_battle_map(rooms: Array[Room])
signal tiles_highlighted(tiles: Array[Vector2i], status_effects: Array[StatusEffect], accuracy: int)
signal display_requested(show_display: bool)

signal turn_started(unit: Character)
signal turn_ended(unit_name: String)
signal reactions_requested(unit: Character, is_ally: bool)
signal timed_out
signal timer_stopped
