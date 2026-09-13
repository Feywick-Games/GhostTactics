class_name LevelCutsceneState
extends LevelState

var _finished := false
var _tracking_cam: TrackingCamera
var _camera_leader: Node2D

func enter() -> void:
	super.enter()
	_tracking_cam = _level.get_viewport().get_camera_2d()
	_camera_leader = Node2D.new()
	_level.add_child(_camera_leader)
	if _level.cutscene:
		var characters: Array[Character] = _level.get_unit_list(false)
		var extra_states: Array = [self]
		
		for character: Character in characters:
			var state := CharacterActorState.new()
			character.set_state(state)
			var state_name : String = character.name.remove_chars(" ")
			extra_states.append({state_name : state})
		
		DialogueManager.show_dialogue_balloon(_level.cutscene, "start", extra_states)
		
		DialogueManager.dialogue_ended.connect(_on_cutscene_completed)


func _on_cutscene_completed(_dialogue_resource: DialogueResource) -> void:
	_finished = true


func camera_follow(node_name: String) -> void:
	_tracking_cam.follow(_level.get_node(node_name))


func camera_center_on_group(node_names: Array[String]) -> void:
	var first_pos := true
	for node_name: String in node_names:
		var node := _level.get_node(node_name) as Node2D
		if first_pos:
			_camera_leader.global_position = node.global_position
		else:
			_camera_leader.global_position = _camera_leader.global_position.lerp(node.global_position, .5)
	_tracking_cam.follow(_camera_leader)


func update(_delta : float) -> State:
	if not _level.cutscene or _finished:
		return LevelSpawnState.new()
	return


func exit() -> void:
	_camera_leader.queue_free()
	var characters: Array[Character] = _level.get_unit_list(false)
	for character: Character in characters:
		character.set_state(CharacterCombatBeginState.new())
