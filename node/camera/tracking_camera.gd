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

func _ready() -> void:
	EventBus.cam_follow_requested.connect(_on_cam_follow_requested)
	get_tree().root.get_viewport().size_changed.connect(_set_window_scale)
	window_scale = DisplayServer.screen_get_size()

func _set_window_scale() -> void:
	window_scale = DisplayServer.window_get_size() / Global.GAME_SIZE


func _process(delta: float) -> void:
	if leader.global_position.distance_to(global_position) > 40:
		global_position =  global_position.lerp(leader.global_position, lerp_speed * .5 * delta)
		var subpixel_position = global_position -  global_position.snapped(Vector2(2,1))
		global_position = global_position.round()
	#RenderingServer.global_shader_parameter_set("cam_offset", subpixel_position)
	
	#if global_position.x + 320 > GameState.level_size.x:
		#global_position.x = GameState.level_size.x - 320
	#elif global_position.x < 320:
		#global_position.x = 320
#
	#
	#if global_position.y + 180 > GameState.level_size.y:
		#global_position.y = GameState.level_size.y - 180
	#elif global_position.y < 180:
		#global_position.y = 180


func _on_cam_follow_requested(node: Node2D) -> void:
	leader = node
