class_name TrackingCamera
extends Camera2D


@export
var leader : Node2D
@export_range(0,5)
var lerp_speed: float = 5
@export
var max_speed: float = .5
@onready
var window_scale : Vector2
var _in_encounter := false
var in_position := false

func _ready() -> void:
	EventBus.cam_follow_requested.connect(_on_cam_follow_requested)
	get_tree().root.get_viewport().size_changed.connect(_set_window_scale)
	window_scale = DisplayServer.screen_get_size()
	EventBus.encounter_started.connect(_on_encounter_started)


func _on_encounter_started(_group: String) -> void:
	_in_encounter = true


func _set_window_scale() -> void:
	window_scale = DisplayServer.window_get_size() / Global.GAME_SIZE


func _process(delta: float) -> void:
	if _in_encounter:
		if leader.global_position.distance_to(global_position) > 40:
			global_position =  global_position.lerp(leader.global_position, lerp_speed * .5 * delta)
			var subpixel_position = global_position -  global_position.snapped(Vector2(2,1))
			global_position = global_position.round()
			in_position = false
		else:
			in_position = true
	else:
		if leader.global_position.distance_to(global_position) > 20:
			global_position =  global_position.lerp(leader.global_position, lerp_speed * delta)
			var subpixel_position = global_position -  global_position.snapped(Vector2(2,1))
			global_position = global_position.round()

func _on_cam_follow_requested(node: Node2D) -> void:
	leader = node
