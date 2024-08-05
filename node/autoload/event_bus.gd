extends Node

signal encounter_started(encounter_name: String)
signal encounter_ended
signal room_transitioned(room: Room, loaded: bool)
signal cam_follow_requested(leader: Node2D)
signal build_battle_map(rooms : Array[Room])

signal turn_started(unit: Character)
signal turn_ended(unit_name: String)
signal timed_out
signal timer_stopped
