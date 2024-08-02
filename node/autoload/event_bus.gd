extends Node

signal encounter_started(encounter_name: String)
signal room_transitioned(room: Room, loaded: bool)
signal cam_follow_requested(leader: Node2D)
